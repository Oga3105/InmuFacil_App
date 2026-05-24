import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/property_form_provider.dart';

class PropertyStepperHeader extends ConsumerWidget {
  const PropertyStepperHeader({super.key});

  static List<String> _steps() => [
    'property_wizard.step_location'.tr(),
    'property_wizard.step_details'.tr(),
    'property_wizard.step_photos'.tr(),
    'property_wizard.step_documents'.tr(),
    'property_wizard.step_description'.tr(),
    'property_wizard.step_publish'.tr(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(propertyFormProvider.select((s) => s.currentStep));
    final colorScheme = Theme.of(context).colorScheme;
    final steps = _steps();
    final total = steps.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          // Show a sliding window of 3 steps: previous, current, next.
          // At the first step show [0,1,2]; at the last show [total-3, total-2, total-1].
          final start = (currentStep == 0
                  ? 0
                  : currentStep >= total - 1
                      ? total - 3
                      : currentStep - 1)
              .clamp(0, total - 3);
          final visibleIndices = [start, start + 1, start + 2];

          return Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'property_wizard.step_counter'.tr(namedArgs: {
                    'current': '${currentStep + 1}',
                    'total': '$total',
                  }),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(visibleIndices.length * 2 - 1, (i) {
                    if (i.isOdd) {
                      final stepIdx = visibleIndices[i ~/ 2];
                      final completed = currentStep > stepIdx;
                      return Expanded(
                        child: Container(
                          height: 2,
                          color: completed
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                        ),
                      );
                    }
                    final stepIdx = visibleIndices[i ~/ 2];
                    return _StepCircle(
                      index: stepIdx,
                      label: steps[stepIdx],
                      isActive: currentStep == stepIdx,
                      isCompleted: currentStep > stepIdx,
                    );
                  }),
                ),
              ],
            ),
          );
        }

        // Desktop: full 6-step row (unchanged)
        return Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: List.generate(total * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIndex = i ~/ 2;
                final completed = currentStep > stepIndex;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: completed
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                );
              }
              final stepIndex = i ~/ 2;
              return _StepCircle(
                index: stepIndex,
                label: steps[stepIndex],
                isActive: currentStep == stepIndex,
                isCompleted: currentStep > stepIndex,
              );
            }),
          ),
        );
      },
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  final int index;
  final String label;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final circleColor =
        (isActive || isCompleted) ? colorScheme.primary : Colors.transparent;
    final borderColor = (isActive || isCompleted)
        ? colorScheme.primary
        : colorScheme.outlineVariant;
    final numberColor = (isActive || isCompleted)
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;
    final labelWeight = isActive ? FontWeight.bold : FontWeight.normal;
    final labelColor = isActive
        ? colorScheme.primary
        : (isCompleted ? colorScheme.primary : colorScheme.onSurfaceVariant);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: colorScheme.onPrimary, size: 18)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: numberColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: labelColor,
            fontWeight: labelWeight,
          ),
        ),
      ],
    );
  }
}
