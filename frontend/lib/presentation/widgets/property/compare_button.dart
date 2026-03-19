import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../providers/comparison_provider.dart';

/// Button that adds a property to the side-by-side comparison.
///
/// - Not in comparison: OutlinedButton "Comparar" (blue #2563EB).
/// - In comparison (A or B): filled ElevatedButton "En comparacion" (green).
/// - When tap completes the pair (both A and B are set): automatically
///   navigates to PropertyComparisonScreen.
class CompareButton extends ConsumerWidget {
  const CompareButton({super.key, required this.propertyId});

  final String propertyId;

  static const _blue = Color(0xFF2563EB);
  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparison = ref.watch(comparisonProvider);
    final notifier = ref.read(comparisonProvider.notifier);
    final inComparison = notifier.isInComparison(propertyId);

    if (inComparison) {
      return ElevatedButton.icon(
        onPressed: () => _handleTap(context, ref),
        icon: const Icon(Icons.compare_arrows, size: 16),
        label: Text('property.compare.in_comparison'.tr()),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _handleTap(context, ref),
      icon: const Icon(Icons.compare_arrows, size: 16),
      label: Text('property.compare.add'.tr()),
      style: OutlinedButton.styleFrom(
        foregroundColor: _blue,
        side: const BorderSide(color: _blue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(comparisonProvider.notifier);
    notifier.addToComparison(propertyId);

    // Re-read the state after mutation to check if the pair is complete
    final updated = ref.read(comparisonProvider);
    if (updated != null &&
        updated.propertyAId.isNotEmpty &&
        updated.propertyBId.isNotEmpty) {
      context.push(
        '/property-comparison',
        extra: {
          'propertyAId': updated.propertyAId,
          'propertyBId': updated.propertyBId,
        },
      );
    }
  }
}
