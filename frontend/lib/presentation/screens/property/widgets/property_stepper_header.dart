import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/property_form_provider.dart';

class PropertyStepperHeader extends ConsumerWidget {
  const PropertyStepperHeader({super.key});

  static const _steps = ['Ubicacion', 'Detalles', 'Fotos', 'Documentos', 'Descripcion', 'Publicar'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(propertyFormProvider.select((s) => s.currentStep));
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final completed = currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: completed ? colorScheme.primary : colorScheme.outlineVariant,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          return _StepCircle(
            index: stepIndex,
            label: _steps[stepIndex],
            isActive: currentStep == stepIndex,
            isCompleted: currentStep > stepIndex,
          );
        }),
      ),
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
    final circleColor = (isActive || isCompleted) ? colorScheme.primary : Colors.transparent;
    final borderColor = (isActive || isCompleted) ? colorScheme.primary : colorScheme.outlineVariant;
    final numberColor = (isActive || isCompleted) ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;
    final labelWeight = isActive ? FontWeight.bold : FontWeight.normal;
    final labelColor = isActive ? colorScheme.primary : (isCompleted ? colorScheme.primary : colorScheme.onSurfaceVariant);

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
