import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:checkme/domain/apperr/api_exception.dart';
import 'package:checkme/domain/agenda/models.dart';
import 'package:checkme/application/agenda/agenda_controller.dart';
import 'package:checkme/application/identity/auth_controller.dart';
import 'package:checkme/infrastructure/storage/session_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checkme/infrastructure/api/api_client.dart';
import 'package:checkme/infrastructure/api/api_config.dart';
import 'package:checkme/infrastructure/api/checkme_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Respond = FutureOr<ResponseBody> Function(RequestOptions options);

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);
  final Respond respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return await respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object? body, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ApiClient clientFor(Respond respond) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'));
  dio.httpClientAdapter = FakeAdapter(respond);
  return ApiClient(
    config: const ApiConfig(root: 'https://api.test'),
    dio: dio,
  );
}

final invalidResponse = isA<ApiException>().having(
  (e) => e.code,
  'code',
  'client.invalid_response',
);

void main() {
  test('concurrent and delayed 401s share one token rotation', () async {
    var access = 'old';
    var refresh = 'refresh-old';
    var rotations = 0;
    var lost = 0;
    final refreshing = Completer<void>();
    final releaseRefresh = Completer<void>();
    final releaseLate = Completer<void>();
    final oldRequests = <String>[];
    final allOldSent = Completer<void>();
    final client = clientFor((req) async {
      if (req.headers['Authorization'] == 'Bearer old') {
        oldRequests.add(req.path);
        if (oldRequests.length == 3) allOldSent.complete();
        await allOldSent.future;
        if (req.path == '/late') await releaseLate.future;
        return jsonBody({
          'error': {'code': 'http.unauthorized'},
        }, 401);
      }
      expect(req.headers['Authorization'], 'Bearer new');
      return jsonBody({'ok': true});
    });
    client.bindAuth(
      accessToken: () => access,
      refreshToken: () => refresh,
      onRefresh: () async {
        rotations++;
        refreshing.complete();
        await releaseRefresh.future;
        access = 'new';
        refresh = 'refresh-new';
        return AuthRefresh(accessToken: access, refreshToken: refresh);
      },
      onSessionLost: () => lost++,
    );
    final first = client.getJson('/first');
    final second = client.getJson('/second');
    final late = client.getJson('/late');
    await refreshing.future;
    releaseRefresh.complete();
    await Future.wait([first, second]);
    releaseLate.complete();
    await late;
    expect(rotations, 1);
    expect(lost, 0);
  });

  test(
    'temporary refresh errors preserve the session and reach caller',
    () async {
      var lost = 0;
      final client = clientFor((req) => jsonBody({}, 401));
      client.bindAuth(
        accessToken: () => 'old',
        refreshToken: () => 'refresh',
        onRefresh: () async => throw const ApiException(
          code: 'postgres.unavailable',
          message: 'Temporário',
          status: 503,
        ),
        onSessionLost: () => lost++,
      );
      await expectLater(
        client.getJson('/me'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)),
      );
      expect(lost, 0);
    },
  );

  test(
    'invalid refresh clears the session once for concurrent requests',
    () async {
      var lost = 0;
      var sent = 0;
      final bothSent = Completer<void>();
      final client = clientFor((req) async {
        if (++sent == 2) bothSent.complete();
        await bothSent.future;
        return jsonBody({}, 401);
      });
      client.bindAuth(
        accessToken: () => 'old',
        refreshToken: () => 'refresh',
        onRefresh: () async {
          await Future<void>.delayed(Duration.zero);
          throw const ApiException(
            code: 'identity.invalid_refresh',
            message: 'Expirada',
            status: 401,
          );
        },
        onSessionLost: () => lost++,
      );
      await Future.wait([
        expectLater(client.getJson('/me'), throwsA(isA<ApiException>())),
        expectLater(
          client.getJson('/appointments'),
          throwsA(isA<ApiException>()),
        ),
      ]);
      expect(lost, 1);
    },
  );

  test('retry server failure does not log out the user', () async {
    var access = 'old';
    var lost = 0;
    final client = clientFor(
      (req) => jsonBody({}, req.extra['retried'] == true ? 503 : 401),
    );
    client.bindAuth(
      accessToken: () => access,
      refreshToken: () => 'refresh',
      onRefresh: () async {
        access = 'new';
        return const AuthRefresh(accessToken: 'new', refreshToken: 'next');
      },
      onSessionLost: () => lost++,
    );
    await expectLater(client.getJson('/me'), throwsA(isA<ApiException>()));
    expect(lost, 0);
  });

  test(
    'public and login requests never attach credentials or refresh',
    () async {
      var rotations = 0;
      final client = clientFor((req) {
        expect(req.headers.containsKey('Authorization'), isFalse);
        return jsonBody({}, 401);
      });
      client.bindAuth(
        accessToken: () => 'secret',
        refreshToken: () => 'refresh',
        onRefresh: () async {
          rotations++;
          return null;
        },
      );
      await expectLater(
        client.getJson('/contato', auth: false),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        client.getList('/planos', auth: false),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        client.postJson('/auth/login', {}),
        throwsA(isA<ApiException>()),
      );
      expect(rotations, 0);
    },
  );

  test(
    'wrong collection shape fails rather than displaying an empty list',
    () async {
      final api = CheckmeApi(clientFor((req) => jsonBody({'items': []})));
      await expectLater(api.consultas(), throwsA(invalidResponse));
    },
  );

  test(
    'invalid appointment dates and absent login tokens are rejected',
    () async {
      final api = CheckmeApi(
        clientFor(
          (req) => jsonBody(
            req.path == '/appointments'
                ? [
                    {
                      'id': 'a',
                      'professionalId': 'p',
                      'startsAt': 'bad',
                      'status': 'reservada',
                    },
                  ]
                : {
                    'user': {'id': 'u', 'email': 'u@test.com'},
                  },
          ),
        ),
      );
      await expectLater(api.consultas(), throwsA(invalidResponse));
      await expectLater(
        api.login(email: 'u@test.com', password: 'password'),
        throwsA(invalidResponse),
      );
    },
  );

  test(
    'professionals fetch availability concurrently and preserve ordering',
    () async {
      var active = 0;
      var peak = 0;
      final api = CheckmeApi(
        clientFor((req) async {
          if (req.path == '/professionals') {
            return jsonBody(
              List.generate(
                9,
                (i) => {
                  'id': '$i',
                  'nome': 'Pro $i',
                  'specialties': '["Clínica","Pediatria"]',
                },
              ),
            );
          }
          active++;
          if (active > peak) peak = active;
          await Future<void>.delayed(Duration.zero);
          active--;
          return jsonBody([]);
        }),
      );
      final pros = await api.profissionais();
      expect(pros.map((p) => p.id), List.generate(9, (i) => '$i'));
      expect(pros.first.especialidade, 'Clínica, Pediatria');
      expect(peak, 4);
    },
  );

  test(
    'availability errors are reported rather than interpreted as no slots',
    () async {
      final api = CheckmeApi(
        clientFor(
          (req) => req.path == '/professionals'
              ? jsonBody([
                  {'id': 'p', 'nome': 'Pro'},
                ])
              : jsonBody({}, 503),
        ),
      );
      await expectLater(api.profissionais(), throwsA(isA<ApiException>()));
    },
  );

  test('booking preserves the idempotency key through token refresh', () async {
    var access = 'old';
    final keys = <String>[];
    final client = clientFor((req) {
      keys.add(req.headers['X-Idempotency-Key'] as String);
      if (req.extra['retried'] != true) return jsonBody({}, 401);
      return jsonBody({
        'id': 'a',
        'professionalId': 'p',
        'startsAt': '2026-10-15T12:00:00Z',
        'status': 'reservada',
      });
    });
    client.bindAuth(
      accessToken: () => access,
      refreshToken: () => 'refresh',
      onRefresh: () async {
        access = 'new';
        return const AuthRefresh(accessToken: 'new', refreshToken: 'next');
      },
    );
    await CheckmeApi(client).reservar(
      profissionalId: 'p',
      startsAt: DateTime.utc(2026, 10, 15, 12),
      endsAt: DateTime.utc(2026, 10, 15, 13),
      idempotencyKey: 'operation-1',
    );
    expect(keys, ['operation-1', 'operation-1']);
  });
  test('Go null collections are accepted as empty availability', () async {
    final api = CheckmeApi(clientFor((req) => jsonBody(null)));
    expect(await api.horarios('p'), isEmpty);
  });

  test(
    'manual booking retries reuse their key and changed slots get a new key',
    () async {
      final keys = <String>[];
      final client = clientFor((req) {
        keys.add(req.headers['X-Idempotency-Key'] as String);
        return jsonBody({}, 503);
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        ],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);
      final controller = container.read(agendaControllerProvider.notifier);
      final slot = Horario(
        id: 's',
        startsAt: DateTime.utc(2026, 10, 15, 12),
        endsAt: DateTime.utc(2026, 10, 15, 13),
      );
      expect(
        await controller.reservar(profissionalId: 'p', horario: slot),
        isFalse,
      );
      expect(
        await controller.reservar(profissionalId: 'p', horario: slot),
        isFalse,
      );
      expect(
        await controller.reservar(profissionalId: 'other', horario: slot),
        isFalse,
      );
      expect(keys[0], isNotEmpty);
      expect(keys[1], keys[0]);
      expect(keys[2], isNot(keys[0]));
    },
  );

  test(
    'logout while refresh is running never restores the old session',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      final store = MemorySessionStore({
        'checkme.access': 'old',
        'checkme.refresh': 'refresh',
        'checkme.user': jsonEncode({
          'id': 'u',
          'email': 'u@test.com',
          'nome': 'U',
        }),
      });
      final client = clientFor((req) async {
        if (req.path == '/auth/refresh') {
          started.complete();
          await release.future;
          return jsonBody({'accessToken': 'new', 'refreshToken': 'next'});
        }
        return jsonBody({}, 401);
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          sessionStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      final auth = container.read(authControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final request = expectLater(
        client.getJson('/me'),
        throwsA(isA<ApiException>()),
      );
      await started.future;
      await auth.clearLocal();
      release.complete();
      await request;
      expect(auth.accessToken, isNull);
      expect(container.read(authControllerProvider).user, isNull);
      expect(await store.read('checkme.access'), isNull);
      expect(await store.read('checkme.refresh'), isNull);
    },
  );
  test(
    'a late unauthorized request cannot be replayed under another login',
    () async {
      var access = 'first-user';
      var calls = 0;
      final sent = Completer<void>();
      final release = Completer<void>();
      final client = clientFor((req) async {
        calls++;
        sent.complete();
        await release.future;
        return jsonBody({}, 401);
      });
      client.bindAuth(accessToken: () => access, refreshToken: () => 'refresh');
      final request = expectLater(
        client.getJson('/me'),
        throwsA(isA<ApiException>()),
      );
      await sent.future;
      access = 'second-user';
      release.complete();
      await request;
      expect(calls, 1);
    },
  );
}
