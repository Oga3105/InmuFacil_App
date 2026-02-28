import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/property_form_provider.dart';

class PropertyStepperHeader extends ConsumerWidget {
  const PropertyStepperHeader({super.key});

  static const _steps = ['Tipo y Ubicación', 'Detalles y Precio', 'Fotos y Extras'];

  static const _blue = Color(0xFF2563EB);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate400 = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(propertyFormProvider.select((s) => s.currentStep));

    return Container(
      color: Colors.white,
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
                color: completed ? _blue : _slate200,
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

  static const _blue = Color(0xFF2563EB);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate400 = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final circleColor = (isActive || isCompleted) ? _blue : Colors.transparent;
    final borderColor = (isActive || isCompleted) ? _blue : _slate200;
    final numberColor = (isActive || isCompleted) ? Colors.white : _slate400;
    final labelWeight = isActive ? FontWeight.bold : FontWeight.normal;
    final labelColor = isActive ? _blue : (isCompleted ? _blue : _slate400);

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
                ? const Icon(Icons.check, color: Colors.white, size: 18)
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
