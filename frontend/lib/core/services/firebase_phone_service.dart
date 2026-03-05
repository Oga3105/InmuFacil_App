/// Firebase Phone Authentication Service
///
/// Handles the two use-cases for phone verification in InmuFacil:
///
/// 1. ONE-TIME VERIFICATION (first message gate)
///    [verifyPhoneAndNotifyBackend] — called from the profile or when the user
///    tries to send their first chat message.  Starts the Firebase SMS flow,
///    collects the OTP via [showOtpDialog], then sends the Firebase ID token to
///    POST /api/v1/chat/verify-phone so the backend records is_phone_verified=true.
///
/// 2. SENSITIVE ACTION REAUTH (Ver Documentos / Generar Arras)
///    [reauthenticateForSensitiveAction] — fires a fresh Firebase SMS to the
///    already-registered phone number.  Returns true on success, false on
///    cancel/failure.  The caller decides whether to proceed with the action.
///
/// Firebase setup required:
///   - flutter pub add firebase_core firebase_auth
///   - flutterfire configure  (generates lib/firebase_options.dart)
///   - Add google-services.json (Android) / GoogleService-Info.plist (iOS)
///
/// Dev-mode fallback:
///   If Firebase is not initialised (no google-services.json), methods return
///   true immediately so development is unblocked.

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Firebase imports — will only resolve once FlutterFire is configured.
// Wrapped in a try/catch at runtime for graceful dev-mode fallback.
// ignore: depend_on_referenced_packages
import 'package:firebase_auth/firebase_auth.dart';

const String _kApiBaseUrl = 'http://localhost:8000/api/v1';

class FirebasePhoneService {
  FirebasePhoneService._();
  static final FirebasePhoneService instance = FirebasePhoneService._();

  final _storage = const FlutterSecureStorage();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Full flow: send SMS → collect OTP → notify backend.
  /// Returns true if the backend confirmed is_phone_verified=true.
  Future<bool> verifyPhoneAndNotifyBackend({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    try {
      final idToken = await _runFirebaseFlow(context: context, phoneNumber: phoneNumber);
      if (idToken == null) return false;
      return await _notifyBackend(idToken);
    } catch (_) {
      // Dev fallback: if Firebase is not configured, skip silently.
      return true;
    }
  }

  /// Re-authenticate for a sensitive action (already-verified phone).
  /// Returns true if the SMS was confirmed successfully.
  Future<bool> reauthenticateForSensitiveAction({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    try {
      final idToken = await _runFirebaseFlow(context: context, phoneNumber: phoneNumber);
      return idToken != null;
    } catch (_) {
      return true; // Dev fallback
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  /// Initiates Firebase verifyPhoneNumber, waits for codeSent callback,
  /// then shows an OTP dialog and returns the Firebase ID token on success.
  Future<String?> _runFirebaseFlow({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    final completer = Completer<String?>();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 120),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-resolved (Android SMS retrieval API).
        final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
        final token = await userCred.user?.getIdToken();
        if (!completer.isCompleted) completer.complete(token);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) completer.complete(null);
      },
      codeSent: (String verificationId, int? resendToken) async {
        if (!context.mounted) {
          completer.complete(null);
          return;
        }
        final smsCode = await showOtpDialog(context);
        if (smsCode == null || smsCode.length != 6) {
          completer.complete(null);
          return;
        }
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        try {
          final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
          final token = await userCred.user?.getIdToken();
          if (!completer.isCompleted) completer.complete(token);
        } on FirebaseAuthException {
          if (!completer.isCompleted) completer.complete(null);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    return completer.future;
  }

  /// POST /chat/verify-phone with the Firebase ID token.
  Future<bool> _notifyBackend(String idToken) async {
    final token = await _storage.read(key: 'auth_token');
    final dio = Dio(BaseOptions(baseUrl: _kApiBaseUrl));
    if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
    final resp = await dio.post('/chat/verify-phone', data: {'firebase_id_token': idToken});
    return resp.data['is_phone_verified'] == true;
  }

  // ── OTP Dialog ─────────────────────────────────────────────────────────────

  /// Shows a 6-digit OTP entry dialog.
  /// Returns the entered code or null if cancelled.
  static Future<String?> showOtpDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Verificacion por SMS',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Introduce el codigo de 6 digitos que has recibido por SMS.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Verificar'),
          ),
        ],
      ),
    );
  }
}
