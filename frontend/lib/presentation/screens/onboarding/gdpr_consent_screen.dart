import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../info/info_screen.dart';

/// Pantalla de consentimiento GDPR — solo se muestra al nuevo usuario que
/// se registra via Google. Sin aceptacion el usuario es deslogueado.
class GdprConsentScreen extends ConsumerWidget {
  const GdprConsentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
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
                  Center(
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: successColor.withValues(alpha: 0.12),
                      child: Icon(Icons.shield_outlined, size: 36, color: successColor),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Titulo
                  Text(
                    'onboarding.gdpr_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'onboarding.gdpr_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
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
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      children: [
                        TextSpan(text: 'onboarding.gdpr_terms_prefix'.tr()),
                        TextSpan(
                          text: 'onboarding.gdpr_terms_link'.tr(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: colorScheme.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.push(InfoScreen.routeFor(InfoPageType.terms)),
                        ),
                        const TextSpan(text: ' y la '),
                        TextSpan(
                          text: 'onboarding.gdpr_privacy_link'.tr(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: colorScheme.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.push(InfoScreen.routeFor(InfoPageType.privacy)),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Boton aceptar
                  ElevatedButton(
                    onPressed: () async {
                      // Re-confirm auth state from storage in case it was
                      // reset by a GoRouter rebuild or Flutter Web page reload.
                      await ref.read(authProvider.notifier).ensureAuthenticated();
                      if (!context.mounted) return;
                      context.go('/');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
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
                      // Hard-delete the account so next Google sign-in
                      // triggers the consent screen again (is_new_user = true).
                      await ref.read(authProvider.notifier).deleteAccount();
                      if (context.mounted) context.go('/login');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      side: BorderSide(color: colorScheme.outlineVariant),
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
  const _GdprItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline, size: 20, color: successColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.4)),
        ),
      ],
    );
  }
}
