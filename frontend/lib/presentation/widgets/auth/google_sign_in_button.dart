import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

/// Boton de inicio de sesion con Google segun Google Brand Guidelines.
/// Maneja el flujo completo: sign-in -> onboarding (si nuevo) -> home.
class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authProvider).isLoading;

    return OutlinedButton(
      onPressed: isLoading ? null : () => _handleGoogleSignIn(context, ref),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F1F1F),
        side: const BorderSide(color: Color(0xFFDADCE0), width: 1),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GoogleLogo(size: 20),
          const SizedBox(width: 12),
          Text(
            'auth.google_sign_in_button'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F1F1F),
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

/// Logo de Google pintado con Canvas (sin dependencia de assets).
class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Background circle blanco
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = Colors.white,
    );

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Cuadrantes de color del logo Google
    final sweepPaint = Paint()..style = PaintingStyle.fill;

    // Rojo (top-right)
    sweepPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -1.5708, 1.5708, true, sweepPaint);

    // Amarillo (bottom-right)
    sweepPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 0, 1.5708, true, sweepPaint);

    // Verde (bottom-left)
    sweepPaint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.5708, 1.5708, true, sweepPaint);

    // Azul (top-left)
    sweepPaint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, 3.14159, 1.5708, true, sweepPaint);

    // Centro blanco (mascara interior)
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.55,
      Paint()..color = Colors.white,
    );

    // Barra blanca horizontal derecha (la "G")
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.13, r * 0.9, r * 0.26),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
