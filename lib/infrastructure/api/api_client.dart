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
  })  : _dio = dio ??
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
          final token = _accessToken?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final req = error.requestOptions;
          final already = req.extra['retried'] == true;
          if (status != 401 ||
              already ||
              _isAuthPath(req.path) ||
              _refreshToken?.call() == null) {
            handler.next(error);
            return;
          }
          try {
            final refreshed = await _onRefresh?.call();
            if (refreshed == null) {
              _onSessionLost?.call();
              handler.next(error);
              return;
            }
            req.extra['retried'] = true;
            req.headers['Authorization'] = 'Bearer ${refreshed.accessToken}';
            final clone = await _dio.fetch(req);
            handler.resolve(clone);
          } catch (_) {
            _onSessionLost?.call();
            handler.next(error);
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
        path.contains('/auth/reset-password');
  }

  Future<bool> ready() async {
    try {
      final res = await _dio.getUri(Uri.parse('${config.root}/health/ready'));
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

  Future<List<dynamic>> getList(String path) async {
    try {
      final res = await _dio.get<dynamic>(path);
      final data = res.data;
      if (data is List) return data;
      return const [];
    } on DioException catch (e) {
      throw _toApi(e);
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.post<dynamic>(path, data: body);
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
    return const {};
  }

  ApiException _toApi(DioException e) {
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
