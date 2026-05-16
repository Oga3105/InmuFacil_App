import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/env_config.dart';
import '../events/session_events.dart';

/// Dio interceptor that:
///   1. Injects the stored JWT Bearer token on every outgoing request.
///   2. Proactively renews the token when less than [_renewThresholdSeconds]
///      remain before expiry (silent renewal via POST /auth/renew).
///      Concurrent requests share a single renewal call via a Completer.
///   3. On 401 from our own API: deletes the stored token and fires
///      [notifySessionExpired] so the app reacts globally (logout + redirect).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'auth_token';

  // Renew when less than 60 minutes remain (token lifetime is 8 h).
  static const _renewThresholdSeconds = 3600;

  // Guards against parallel renewal calls: all concurrent requests wait on
  // this completer instead of each firing their own /auth/renew request.
  static Completer<String?>? _renewCompleter;

  // ── JWT helpers ────────────────────────────────────────────────────────────

  /// Decodes the `exp` claim from a JWT without verifying the signature.
  static int? _extractExp(String token) {
    try {
      final segments = token.split('.');
      if (segments.length != 3) return null;
      // JWT uses base64url encoding without padding.
      final payload = base64Url.normalize(segments[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = json.decode(decoded) as Map<String, dynamic>;
      return (map['exp'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  static bool _needsRenewal(String token) {
    final exp = _extractExp(token);
    if (exp == null) return false;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return exp - nowSeconds < _renewThresholdSeconds;
  }

  // ── Silent renewal ─────────────────────────────────────────────────────────

  /// Calls POST /auth/renew with the current (still-valid) token.
  /// Returns the new token on success, null on failure.
  /// Concurrent callers share a single HTTP request via [_renewCompleter].
  Future<String?> _renewToken(String currentToken) async {
    // If a renewal is already in flight, wait for its result.
    if (_renewCompleter != null) return _renewCompleter!.future;

    _renewCompleter = Completer<String?>();
    try {
      // Use a bare Dio instance so this request does NOT go through
      // AuthInterceptor again (avoids infinite loop).
      final renewDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final resp = await renewDio.post(
        '${EnvConfig.apiBaseUrl}/auth/renew',
        options: Options(
          headers: {'Authorization': 'Bearer $currentToken'},
        ),
      );
      final newToken = resp.data['access_token'] as String?;
      _renewCompleter!.complete(newToken);
      return newToken;
    } catch (_) {
      // Renewal failed — the original token is still valid for up to 1 h,
      // so continue with the current token rather than forcing a logout.
      _renewCompleter!.complete(null);
      return null;
    } finally {
      _renewCompleter = null;
    }
  }

  // ── Interceptor overrides ──────────────────────────────────────────────────

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var token = await _storage.read(key: _tokenKey);
    if (token == null) {
      handler.next(options);
      return;
    }

    // Skip renewal for the renew endpoint itself.
    final isRenewCall =
        options.uri.toString().contains('/auth/renew');

    if (!isRenewCall && _needsRenewal(token)) {
      final newToken = await _renewToken(token);
      if (newToken != null) {
        await _storage.write(key: _tokenKey, value: newToken);
        token = newToken;
      }
      // If renewal fails, proceed with the still-valid original token.
    }

    options.headers['Authorization'] = 'Bearer $token';
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
        // Guard: only treat as session-expired when the request was actually
        // sent WITH an Authorization header.
        //
        // The previous implementation re-read the token from storage at the
        // time the 401 arrived, which caused a race condition on new Google
        // sign-in: a request sent without a token (unauthenticated) could
        // receive its 401 response *after* signInWithGoogle() had already
        // written the new token to storage — the interceptor would then find
        // the fresh token, delete it, and fire a spurious session-expiry
        // that immediately logged the user out.
        final sentWithToken =
            err.requestOptions.headers['Authorization'] != null;
        if (sentWithToken) {
          await _storage.delete(key: _tokenKey);
          notifySessionExpired();
        }
      }
    }
    handler.next(err);
  }
}
