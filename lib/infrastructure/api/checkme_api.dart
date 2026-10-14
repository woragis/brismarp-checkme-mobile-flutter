import 'dart:convert';

import '../../domain/agenda/models.dart';
import '../../domain/agenda/quando.dart';
import '../../domain/care/models.dart';
import '../../domain/care/visible_text.dart';
import '../../domain/identity/user.dart';
import 'api_client.dart';

class CheckmeApi {
  CheckmeApi(this._client);

  final ApiClient _client;

  Future<bool> ready() => _client.ready();

  Future<AuthTokens> register({
    required String nome,
    required String email,
    required String password,
    required bool lgpdConsent,
    String? affiliateCode,
    String? phone,
  }) async {
    final data = await _client.postJson('/auth/register', {
      'nome': nome,
      'email': email,
      'password': password,
      'lgpdConsent': lgpdConsent,
      if (affiliateCode != null && affiliateCode.isNotEmpty)
        'affiliateCode': affiliateCode,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return _tokens(data);
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.postJson('/auth/login', {
      'email': email,
      'password': password,
    });
    return _tokens(data);
  }

  Future<AuthRefresh> refresh(String refreshToken) async {
    final data = await _client.postJson('/auth/refresh', {
      'refreshToken': refreshToken,
    });
    return AuthRefresh(
      accessToken: _requiredString(data, 'accessToken'),
      refreshToken: _requiredString(data, 'refreshToken'),
    );
  }

  Future<void> logout(String refreshToken) async {
    await _client.postJson('/auth/logout', {'refreshToken': refreshToken});
  }

  Future<ChatReply> chat({required String mensagem, String? sessaoId}) async {
    final data = await _client.postJson('/chat', {
      'mensagem': mensagem,
      if (sessaoId != null && sessaoId.isNotEmpty) 'sessaoId': sessaoId,
    });
    return ChatReply(
      status: _triageStatus(data),
      mensagem: visibleOrientationText(_requiredString(data, 'mensagem')),
      sessaoId: _requiredString(data, 'sessaoId'),
      soap: data['soap']?.toString(),
    );
  }

  Future<List<SessionView>> listTriagens() async {
    final raw = await _client.getList('/me/triagens');
    return raw.map((m) => _session(_map(m), withHistory: false)).toList();
  }

  Future<SessionView> triagem(String id) async {
    final data = await _client.getJson('/me/triagens/$id');
    return _session(data, withHistory: true);
  }

  Future<void> verifyEmail(String code) async {
    await _client.postJson('/auth/verify-email', {'code': code});
  }

  Future<void> resendVerification() async {
    await _client.postJson('/auth/resend-verification', {});
  }

  Future<List<Profissional>> profissionais() async {
    final raw = await _client.getList('/professionals');
    final agora = DateTime.now();
    final lista = <Profissional>[];
    // Limit concurrent requests so a large network does not flood the API.
    final maps = raw.map(_map).toList();
    for (var offset = 0; offset < maps.length; offset += 4) {
      final batch = maps.skip(offset).take(4);
      lista.addAll(
        await Future.wait(
          batch.map((map) async {
            final id = _requiredString(map, 'id');
            final slots = await horarios(id);
            return Profissional(
              id: id,
              nome: _requiredString(map, 'nome'),
              especialidade: _specialties(map['specialties']),
              proximo: proximoFuturo(slots.map((s) => s.startsAt), agora),
            );
          }),
        ),
      );
    }
    return lista;
  }

  Future<List<Horario>> horarios(String profissionalId) async {
    final raw = await _client.getList('/professionals/$profissionalId/slots');
    return raw.map((item) {
      final map = _map(item);
      return Horario(
        id: _requiredString(map, 'id'),
        startsAt: _date(map, 'startsAt'),
        endsAt: _date(map, 'endsAt'),
      );
    }).toList();
  }

  Future<Consulta> reservar({
    required String profissionalId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? sessaoId,
    required String idempotencyKey,
  }) async {
    final data = await _client.postJson('/appointments', {
      'professionalId': profissionalId,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
      if (sessaoId != null && sessaoId.isNotEmpty) 'sessaoId': sessaoId,
    }, idempotencyKey: idempotencyKey);
    return _consulta(data);
  }

  Future<List<Consulta>> consultas() async {
    final raw = await _client.getList('/appointments');
    return raw.map((item) => _consulta(_map(item))).toList();
  }

  Consulta _consulta(Map<String, dynamic> data) {
    return Consulta(
      id: _requiredString(data, 'id'),
      profissionalId: _requiredString(data, 'professionalId'),
      startsAt: _date(data, 'startsAt'),
      status: _requiredString(data, 'status'),
      videoStatus: data['videoStatus']?.toString() ?? '',
    );
  }

  Future<void> reagendarConsulta(
    String id, {
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    await _client.postJson('/appointments/$id/reschedule', {
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
    });
  }

  Future<void> cancelarConsulta(String id) async {
    await _client.postJson('/appointments/$id/cancel', {});
  }

  Future<String> entrarVideo(String id) async {
    final data = await _client.postJson('/appointments/$id/video/join', {});
    final url = _requiredString(data, 'url');
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw ApiClient.invalidResponse();
    }
    return url;
  }

  Future<void> encerrarVideo(String id) async {
    await _client.postJson('/appointments/$id/video/end', {});
  }

  Future<Map<String, dynamic>> eu() => _client.getJson('/me');

  Future<Map<String, dynamic>> atualizarEu({
    required String nome,
    required String cpf,
    required String phone,
  }) {
    return _client.patchJson('/me', {'nome': nome, 'cpf': cpf, 'phone': phone});
  }

  Future<Map<String, dynamic>> exportarEu() => _client.getJson('/me/export');

  Future<void> apagarEu() async {
    await _client.postJson('/me/erase', {});
  }

  Future<Map<String, dynamic>> adicionarDependente({
    required String nome,
    required String kinship,
  }) {
    return _client.postJson('/me/dependents', {
      'nome': nome,
      'kinship': kinship,
    });
  }

  Future<void> removerDependente(String id) async {
    await _client.delete('/me/dependents/$id');
  }

  Future<List<Map<String, dynamic>>> planos() async {
    final raw = await _client.getList('/planos', auth: false);
    return raw.map(_map).toList();
  }

  Future<Map<String, dynamic>> validarCupom(String code) {
    return _client.postJson('/coupons/validate', {'code': code});
  }

  Future<Map<String, dynamic>> contratarPlano({
    required String planId,
    String couponCode = '',
  }) {
    return _client.postJson('/subscriptions', {
      'planId': planId,
      if (couponCode.isNotEmpty) 'couponCode': couponCode,
    });
  }

  Future<void> esqueciSenha(String email) async {
    await _client.postJson('/auth/forgot-password', {'email': email});
  }

  Future<void> redefinirSenha({
    required String email,
    required String code,
    required String password,
  }) async {
    await _client.postJson('/auth/reset-password', {
      'email': email,
      'code': code,
      'password': password,
    });
  }

  Future<List<String>> especialidades() async {
    final raw = await _client.getList('/especialidades', auth: false);
    return raw
        .map((item) {
          if (item is! String) throw ApiClient.invalidResponse();
          return item;
        })
        .where((n) => n.isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> rede() async {
    final raw = await _client.getList(
      '/rede-credenciada/descontos',
      auth: false,
    );
    return raw.map(_map).toList();
  }

  Future<List<Map<String, dynamic>>> faq() async {
    final raw = await _client.getList('/faq', auth: false);
    return raw.map(_map).toList();
  }

  Future<ContactInfo> contato() async {
    final data = await _client.getJson('/contato', auth: false);
    return ContactInfo(whatsapp: data['whatsapp']?.toString());
  }

  AuthTokens _tokens(Map<String, dynamic> data) {
    final userMap = _map(data['user']);
    _requiredString(userMap, 'id');
    _requiredString(userMap, 'email');
    return AuthTokens(
      accessToken: _requiredString(data, 'accessToken'),
      refreshToken: _requiredString(data, 'refreshToken'),
      user: User.fromJson(userMap),
    );
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is! Map<String, dynamic>) throw ApiClient.invalidResponse();
    return value;
  }

  String _requiredString(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is! String || value.trim().isEmpty) {
      throw ApiClient.invalidResponse();
    }
    return value;
  }

  DateTime _date(Map<String, dynamic> data, String field) {
    final value = DateTime.tryParse(_requiredString(data, field));
    if (value == null) throw ApiClient.invalidResponse();
    return value;
  }

  TriageStatus _triageStatus(Map<String, dynamic> data) {
    final value = _requiredString(data, 'status');
    if (![
      'ALERTA_GRAVE',
      'LEVE',
      'MODERADO',
      'CONTINUAR_TRIAGEM',
    ].contains(value)) {
      throw ApiClient.invalidResponse();
    }
    return TriageStatus.parse(value);
  }

  String _specialties(dynamic value) {
    if (value == null) return '';
    if (value is! String) throw ApiClient.invalidResponse();
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded.join(', ');
    } on FormatException {
      // The API also accepts plain specialty names.
    }
    return value;
  }

  SessionView _session(Map<String, dynamic> data, {required bool withHistory}) {
    final history = <CareMessage>[];
    if (withHistory) {
      final raw = data['history'];
      if (raw is List) {
        var i = 0;
        for (final item in raw) {
          if (item is! Map) continue;
          final role = item['role']?.toString() ?? '';
          final content = item['content']?.toString() ?? '';
          final text = visibleOrientationText(content);
          if (text.isEmpty && looksLikeSoapJson(content)) continue;
          if (text.isEmpty) continue;
          history.add(
            CareMessage(
              id: 'h-$i',
              text: text,
              fromUser: role == 'user',
              at: DateTime.now(),
            ),
          );
          i += 1;
        }
      }
    }
    return SessionView(
      id: _requiredString(data, 'id'),
      status: _triageStatus(data),
      history: history,
      soap: data['soap']?.toString(),
      updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? ''),
    );
  }
}
