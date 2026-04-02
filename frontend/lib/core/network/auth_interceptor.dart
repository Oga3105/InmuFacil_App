import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/env_config.dart';
import '../events/session_events.dart';

/// Dio interceptor that:
///   1. Injects the stored JWT Bearer token on every outgoing request.
///   2. On 401 responses from our own API: deletes the stored token and fires
///      [notifySessionExpired] so the app can react globally (logout + redirect).
///
/// The session-expired event is only fired when:
///   a) The 401 comes from a URL that belongs to [EnvConfig.apiBaseUrl].
///   b) A token actually exists in storage (i.e., the user was logged in).
///      A 401 on the login endpoint itself does not trigger a forced logout.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'auth_token';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final url = err.requestOptions.uri.toString();
      final isOwnApi = url.startsWith(EnvConfig.apiBaseUrl);

      if (isOwnApi) {
        // Guard: only treat as session-expired if the user was authenticated.
        // A 401 on /auth/token (wrong password) has no stored token yet.
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          await _storage.delete(key: _tokenKey);
          notifySessionExpired();
        }
      }
    }
    handler.next(err);
  }
}
