import 'package:dio/dio.dart';

import '../../domain/apperr/api_exception.dart';
import 'api_config.dart';

typedef TokenReader = String? Function();
typedef RefreshFn = Future<AuthRefresh?> Function();
typedef SessionLost = void Function();

class AuthRefresh {
  const AuthRefresh({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

class ApiClient {
  ApiClient({
    required this.config,
    Dio? dio,
    this._accessToken,
    this._refreshToken,
    this._onRefresh,
    this._onSessionLost,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.v1,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 30),
               headers: {'Content-Type': 'application/json'},
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final skipAuth =
              options.extra['skipAuth'] == true || _isAuthPath(options.path);
          final token = skipAuth ? null : _accessToken?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (token == null || token.isEmpty) {
            options.headers.remove('Authorization');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final req = error.requestOptions;
          if (status != 401 ||
              req.extra['skipAuth'] == true ||
              _isAuthPath(req.path)) {
            handler.next(error);
            return;
          }
          final sent = req.headers['Authorization'];
          final current = _accessToken?.call();
          if (req.extra['retried'] == true) {
            if (sent == 'Bearer $current') _onSessionLost?.call();
            handler.next(error);
            return;
          }
          if (current != null &&
              current.isNotEmpty &&
              sent != 'Bearer $current' &&
              (sent != 'Bearer $_lastExpiredAccess' ||
                  current != _lastRefreshedAccess)) {
            // Never replay an old request under an unrelated login.
            handler.next(error);
            return;
          }
          try {
            // A delayed 401 may belong to the token already replaced by another request.
            if (current == null ||
                current.isEmpty ||
                sent == 'Bearer $current') {
              if (_refreshToken?.call() == null || _onRefresh == null) {
                if (current != null) _onSessionLost?.call();
                handler.next(error);
                return;
              }
              final refreshed = await _refreshOnce();
              if (refreshed == null) {
                handler.next(error);
                return;
              }
            }
          } on ApiException catch (e) {
            handler.reject(DioException(requestOptions: req, error: e));
            return;
          } catch (e) {
            handler.reject(DioException(requestOptions: req, error: e));
            return;
          }
          if (_accessToken?.call() == null) {
            handler.next(error);
            return;
          }
          req.extra['retried'] = true;
          try {
            handler.resolve(await _dio.fetch(req));
          } on DioException catch (e) {
            handler.next(e);
          }
        },
      ),
    );
  }

  final ApiConfig config;
  final Dio _dio;
  TokenReader? _accessToken;
  TokenReader? _refreshToken;
  RefreshFn? _onRefresh;
  SessionLost? _onSessionLost;
  Future<AuthRefresh?>? _refreshing;
  String? _lastExpiredAccess;
  String? _lastRefreshedAccess;

  Future<AuthRefresh?> _refreshOnce() {
    return _refreshing ??= _runRefresh();
  }

  Future<AuthRefresh?> _runRefresh() async {
    final token = _refreshToken?.call();
    final expiredAccess = _accessToken?.call();
    try {
      final result = await Future<AuthRefresh?>.sync(_onRefresh!);
      if (result == null && token == _refreshToken?.call()) {
        _onSessionLost?.call();
      }
      if (result != null && _accessToken?.call() == result.accessToken) {
        _lastExpiredAccess = expiredAccess;
        _lastRefreshedAccess = result.accessToken;
      }
      return result;
    } on ApiException catch (e) {
      // Connectivity and server errors do not invalidate a valid local session.
      if (e.unauthorized && token == _refreshToken?.call()) {
        _onSessionLost?.call();
      }
      rethrow;
    } finally {
      _refreshing = null;
    }
  }

  void bindAuth({
    TokenReader? accessToken,
    TokenReader? refreshToken,
    RefreshFn? onRefresh,
    SessionLost? onSessionLost,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _onRefresh = onRefresh;
    _onSessionLost = onSessionLost;
  }

  bool _isAuthPath(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/reset-password') ||
        path.contains('/auth/logout');
  }

  Future<bool> ready() async {
    try {
      final res = await _dio.getUri(
        Uri.parse('${config.root}/health/ready'),
        options: Options(extra: {'skipAuth': true}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getJson(String path, {bool auth = true}) async {
    try {
      final res = await _dio.get<dynamic>(
        path,
        options: Options(extra: {'skipAuth': !auth}),
      );
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _toApi(e);
    }
  }

  Future<List<dynamic>> getList(String path, {bool auth = true}) async {
    try {
      final res = await _dio.get<dynamic>(
        path,
        options: Options(extra: {'skipAuth': !auth}),
      );
      final data = res.data;
      if (data is List) return data;
      // Go encodes nil collection slices as JSON null.
      if (data == null) return const [];
      throw invalidResponse();
    } on DioException catch (e) {
      throw _toApi(e);
    }
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.patch<dynamic>(path, data: body);
      if (res.statusCode == 204 || res.data == null || res.data == '') {
        return const {};
      }
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _toApi(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete<dynamic>(path);
    } on DioException catch (e) {
      throw _toApi(e);
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(headers: {'X-Idempotency-Key': ?idempotencyKey}),
      );
      if (res.statusCode == 204 || res.data == null || res.data == '') {
        return const {};
      }
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _toApi(e);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw invalidResponse();
  }

  static ApiException invalidResponse() => const ApiException(
    code: 'client.invalid_response',
    message: 'Recebemos uma resposta inesperada. Tente novamente.',
  );

  ApiException _toApi(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        final fieldsRaw = err['fields'];
        final fields = <FieldError>[];
        if (fieldsRaw is List) {
          for (final f in fieldsRaw) {
            if (f is Map) {
              fields.add(
                FieldError(
                  field: f['field']?.toString() ?? '',
                  code: f['code']?.toString() ?? '',
                ),
              );
            }
          }
        }
        return ApiException(
          code: err['code']?.toString() ?? 'internal',
          message: err['message']?.toString() ?? 'Não foi possível continuar.',
          status: status,
          fields: fields,
        );
      }
    }
    if (status == 401) {
      return ApiException(
        code: 'http.unauthorized',
        message: 'Entre para continuar.',
        status: status,
      );
    }
    return ApiException(
      code: 'internal',
      message: 'Não foi possível falar com o CheckMe agora.',
      status: status,
    );
  }
}
