import 'package:dio/dio.dart';

import '../config/env_config.dart';
import 'auth_interceptor.dart';

/// Creates a [Dio] instance pre-configured with:
///   - [EnvConfig.apiBaseUrl] as baseUrl
///   - Connection and receive timeouts from [EnvConfig.apiTimeout]
///   - JSON Content-Type / Accept headers
///   - [AuthInterceptor] for JWT injection and 401 session-expiry handling
///
/// Use this everywhere instead of raw `Dio()` or
/// `Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl))`.
Dio buildAuthDio() {
  final dio = Dio(
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
  dio.interceptors.add(AuthInterceptor());
  return dio;
}
