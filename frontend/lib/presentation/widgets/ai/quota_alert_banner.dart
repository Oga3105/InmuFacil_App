import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai_quota_controller.dart';

/// Provider that resolves the current [QuotaAlertLevel].
final _quotaAlertLevelProvider = FutureProvider.autoDispose<QuotaAlertLevel>(
  (_) => AiQuotaController.instance.getAlertLevel(),
);

/// A contextual banner that surfaces the current AI quota alert level.
///
/// Renders nothing ([SizedBox.shrink]) when usage is below the 80 % threshold.
/// Displays a coloured banner with a descriptive message for warning, critical,
/// and exceeded states.
class QuotaAlertBanner extends ConsumerWidget {
  const QuotaAlertBanner({super.key});

  static const Color _colorWarning = Color(0xFFF59E0B);
  static const Color _colorCritical = Color(0xFFF97316);
  static const Color _colorExceeded = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertAsync = ref.watch(_quotaAlertLevelProvider);

    return alertAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (level) {
        switch (level) {
          case QuotaAlertLevel.normal:
            return const SizedBox.shrink();

          case QuotaAlertLevel.warning:
            return _BannerBar(
              color: _colorWarning,
              message: 'Uso de IA al 80%. Considera optimizar el uso.',
              icon: Icons.warning_amber_rounded,
            );

          case QuotaAlertLevel.critical:
            return _BannerBar(
              color: _colorCritical,
              message: 'Uso de IA al 90%. Limite mensual proximo.',
              icon: Icons.error_outline_rounded,
            );

          case QuotaAlertLevel.exceeded:
            return _BannerBar(
              color: _colorExceeded,
              message:
                  'Limite mensual de IA alcanzado. Funciones de IA deshabilitadas.',
              icon: Icons.block_rounded,
            );
        }
      },
    );
  }
}

/// Internal full-width coloured banner row.
class _BannerBar extends StatelessWidget {
  const _BannerBar({
    required this.color,
    required this.message,
    required this.icon,
  });

  final Color color;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withOpacity(0.12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
