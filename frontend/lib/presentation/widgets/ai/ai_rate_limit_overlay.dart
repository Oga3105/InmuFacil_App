import 'package:flutter/material.dart';
import '../../../core/services/ai_types.dart';

/// Overlay displayed when the user has reached their daily AI call limit
/// for a given [category]. Uses the red/warning color palette.
class AiRateLimitOverlay extends StatelessWidget {
  const AiRateLimitOverlay({
    super.key,
    required this.category,
  });

  final AiTaskCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.block_outlined,
            size: 40,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 12),
          const Text(
            'Limite de seguridad alcanzado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF991B1B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Para proteger la integridad de la plataforma, el uso de IA para '
            '${category.name} se restablecera en 24 horas.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
