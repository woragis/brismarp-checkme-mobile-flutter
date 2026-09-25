import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/apperr/api_exception.dart';
import '../../domain/identity/user.dart';
import '../../infrastructure/api/api_client.dart';
import '../../infrastructure/api/checkme_api.dart';
import '../../infrastructure/storage/session_store.dart';

const _kAccess = 'checkme.access';
const _kRefresh = 'checkme.refresh';
const _kUser = 'checkme.user';

class AuthSnapshot {
  const AuthSnapshot({
    this.user,
    this.hydrating = true,
    this.errorMessage,
    this.errorCode,
  });

  final User? user;
  final bool hydrating;
  final String? errorMessage;
  final String? errorCode;

  bool get autenticado => user != null;

  AuthSnapshot copyWith({
    User? user,
    bool clearUser = false,
    bool? hydrating,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
  }) {
    return AuthSnapshot(
      user: clearUser ? null : (user ?? this.user),
      hydrating: hydrating ?? this.hydrating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }
}

class AuthController extends Notifier<AuthSnapshot> {
  late final CheckmeApi _api;
  late final SessionStore _store;
  late final ApiClient _client;
  String? _access;
  String? _refresh;

  String? get accessToken => _access;
  String? get refreshToken => _refresh;

  @override
  AuthSnapshot build() {
    _api = ref.read(checkmeApiProvider);
    _store = ref.read(sessionStoreProvider);
    _client = ref.read(apiClientProvider);
    _client.bindAuth(
      accessToken: () => _access,
      refreshToken: () => _refresh,
      onRefresh: _refreshSession,
      onSessionLost: () {
        Future.microtask(clearLocal);
      },
    );
    Future.microtask(hydrate);
    return const AuthSnapshot();
  }

  Future<void> hydrate() async {
    try {
      _access = await _store.read(_kAccess);
      _refresh = await _store.read(_kRefresh);
      final raw = await _store.read(_kUser);
      User? user;
      if (raw != null && raw.isNotEmpty) {
        user = User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
      if (_access == null || user == null) {
        state = const AuthSnapshot(hydrating: false);
        return;
      }
      state = AuthSnapshot(user: user, hydrating: false);
    } catch (_) {
      state = const AuthSnapshot(hydrating: false);
    }
  }

  Future<void> entrar({required String email, required String password}) async {
    state = state.copyWith(clearError: true);
    final tokens = await _api.login(email: email, password: password);
    await _persist(tokens);
  }

  Future<void> criar({
    required String nome,
    required String email,
    required String password,
    required bool lgpdConsent,
    String? affiliateCode,
  }) async {
    state = state.copyWith(clearError: true);
    final tokens = await _api.register(
      nome: nome,
      email: email,
      password: password,
      lgpdConsent: lgpdConsent,
      affiliateCode: affiliateCode,
    );
    await _persist(tokens);
  }

  Future<void> atualizarNome(String nome) async {
    final user = state.user;
    if (user == null || nome.trim().isEmpty) return;
    final next = User(
      id: user.id,
      email: user.email,
      nome: nome.trim(),
      role: user.role,
      emailVerified: user.emailVerified,
    );
    await _store.write(_kUser, jsonEncode(next.toJson()));
    state = state.copyWith(user: next);
  }

  Future<void> marcarEmailVerificado() async {
    final user = state.user;
    if (user == null) return;
    final next = User(
      id: user.id,
      email: user.email,
      nome: user.nome,
      role: user.role,
      emailVerified: true,
    );
    await _store.write(_kUser, jsonEncode(next.toJson()));
    state = state.copyWith(user: next, clearError: true);
  }

  Future<void> esqueciSenha(String email) => _api.esqueciSenha(email);

  Future<void> redefinirSenha({
    required String email,
    required String code,
    required String password,
  }) {
    return _api.redefinirSenha(email: email, code: code, password: password);
  }

  Future<void> sair() async {
    final refresh = _refresh;
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _api.logout(refresh);
      }
    } on ApiException {
      /* still clear local */
    }
    await clearLocal();
  }

  Future<void> clearLocal() async {
    _access = null;
    _refresh = null;
    await _store.delete(_kAccess);
    await _store.delete(_kRefresh);
    await _store.delete(_kUser);
    state = const AuthSnapshot(hydrating: false);
  }

  Future<void> _persist(AuthTokens tokens) async {
    _access = tokens.accessToken;
    _refresh = tokens.refreshToken;
    await _store.write(_kAccess, tokens.accessToken);
    await _store.write(_kRefresh, tokens.refreshToken);
    await _store.write(_kUser, jsonEncode(tokens.user.toJson()));
    state = AuthSnapshot(user: tokens.user, hydrating: false);
  }

  Future<AuthRefresh?> _refreshSession() async {
    final token = _refresh;
    if (token == null || token.isEmpty) return null;
    final next = await _api.refresh(token);
    _access = next.accessToken;
    _refresh = next.refreshToken;
    await _store.write(_kAccess, next.accessToken);
    await _store.write(_kRefresh, next.refreshToken);
    return next;
  }
}

final sessionStoreProvider = Provider<SessionStore>((ref) {
  throw UnimplementedError('sessionStoreProvider override required');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('apiClientProvider override required');
});

final checkmeApiProvider = Provider<CheckmeApi>((ref) {
  return CheckmeApi(ref.watch(apiClientProvider));
});

final authControllerProvider = NotifierProvider<AuthController, AuthSnapshot>(
  AuthController.new,
);
