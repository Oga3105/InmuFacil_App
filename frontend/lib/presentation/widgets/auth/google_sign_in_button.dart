import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

/// Boton de inicio de sesion con Google segun Google Brand Guidelines.
/// Soporta light/dark mode: fondo oscuro (#131314) en dark, blanco en light.
/// El logo Google siempre se renderiza sobre un fondo blanco propio.
class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authProvider).isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Google Brand Guidelines: dark variant usa #131314 con borde sutil
    final bgColor = isDark ? const Color(0xFF131314) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final borderColor = isDark ? const Color(0xFF8E918F) : const Color(0xFFDADCE0);

    return OutlinedButton(
      onPressed: isLoading ? null : () => _handleGoogleSignIn(context, ref),
      style: OutlinedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        side: BorderSide(color: borderColor, width: 1),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _GoogleLogo(size: 22),
                const SizedBox(width: 12),
                Text(
                  'auth.google_sign_in_button'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    letterSpacing: 0.25,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    final isNewUser = await ref.read(authProvider.notifier).signInWithGoogle();

    if (!context.mounted) return;

    final error = ref.read(authProvider).errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red[700]),
      );
      return;
    }

    if (isNewUser) {
      context.go('/onboarding/consent');
    } else {
      context.go('/');
    }
  }
}

/// Logo "G" de Google usando el asset oficial sobre fondo circular blanco.
class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(4), // Margen interno para que la G respire
      child: Image.asset(
        'assets/images/google_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
