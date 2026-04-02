import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/env_config.dart';
import '../../../core/network/auth_interceptor.dart';

/// Dio HTTP client with JWT authentication interceptor.
/// Managed by @Shield for security compliance.
///
/// On 401 responses the [AuthInterceptor] deletes the stored token and fires
/// [sessionExpiredStream] — the app-level listener in [InmuFacilApp] handles
/// the redirect to /login and shows a snackbar.
class ApiClient {

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: EnvConfig.apiTimeout),
        receiveTimeout: Duration(milliseconds: EnvConfig.apiTimeout),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(AuthInterceptor());

    if (EnvConfig.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          requestHeader: true,
          responseHeader: false,
        ),
      );
    }
  }

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() async => _storage.read(key: _tokenKey);

  Future<void> deleteToken() async => _storage.delete(key: _tokenKey);

  Dio get client => _dio;
}
