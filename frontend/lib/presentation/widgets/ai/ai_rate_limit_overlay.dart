import 'package:easy_localization/easy_localization.dart';
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
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFBBF24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.block_outlined,
            size: 40,
            color: Color(0xFFD97706),
          ),
          const SizedBox(height: 12),
          Text(
            'ai_rate_limit.title'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF92400E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'ai_rate_limit.message'.tr(namedArgs: {'category': category.name}),
            style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
