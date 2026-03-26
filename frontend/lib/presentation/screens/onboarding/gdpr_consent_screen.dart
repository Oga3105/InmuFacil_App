import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de consentimiento GDPR — solo se muestra al nuevo usuario que
/// se registra via Google. Sin aceptacion el usuario es deslogueado.
class GdprConsentScreen extends ConsumerWidget {
  const GdprConsentScreen({super.key});

  static const Color _teal = Color(0xFF2D5C5A);
  static const Color _blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icono shield
                  const Center(
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Color(0xFFDCFCE7),
                      child: Icon(Icons.shield_outlined, size: 36, color: Color(0xFF16A34A)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Titulo
                  Text(
                    'onboarding.gdpr_title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'onboarding.gdpr_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  // Items GDPR
                  _GdprItem(text: 'onboarding.gdpr_item_1'.tr()),
                  const SizedBox(height: 12),
                  _GdprItem(text: 'onboarding.gdpr_item_2'.tr()),
                  const SizedBox(height: 12),
                  _GdprItem(text: 'onboarding.gdpr_item_3'.tr()),
                  const SizedBox(height: 32),

                  // Nota legal
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      children: [
                        TextSpan(text: 'onboarding.gdpr_terms_prefix'.tr()),
                        TextSpan(
                          text: 'onboarding.gdpr_terms_link'.tr(),
                          style: const TextStyle(
                            color: _blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: ' y la '),
                        TextSpan(
                          text: 'onboarding.gdpr_privacy_link'.tr(),
                          style: const TextStyle(
                            color: _blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Boton aceptar
                  ElevatedButton(
                    onPressed: () => context.go('/onboarding/user-type'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'onboarding.gdpr_accept_button'.tr(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Boton rechazar
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'onboarding.gdpr_decline_button'.tr(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GdprItem extends StatelessWidget {
  final String text;
  const _GdprItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, size: 20, color: Color(0xFF16A34A)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4)),
        ),
      ],
    );
  }
}
