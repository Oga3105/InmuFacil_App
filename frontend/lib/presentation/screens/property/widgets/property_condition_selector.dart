import 'package:flutter/material.dart';
import '../../../../../domain/entities/property_condition.dart';

class PropertyConditionSelector extends StatelessWidget {
  const PropertyConditionSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PropertyCondition? selected;
  final ValueChanged<PropertyCondition> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: PropertyCondition.values.map((condition) {
        final isSelected = selected == condition;
        return GestureDetector(
          onTap: () => onSelected(condition),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                      width: isSelected ? 6 : 1.5,
                    ),
                    color: isSelected ? colorScheme.primary : colorScheme.surface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        condition.displayLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        condition.sublabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
