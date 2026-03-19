import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/property_comparison.dart';

final comparisonProvider =
    NotifierProvider<ComparisonNotifier, PropertyComparison?>(
  ComparisonNotifier.new,
);

class ComparisonNotifier extends Notifier<PropertyComparison?> {
  @override
  PropertyComparison? build() => null;

  /// Adds [propertyId] to the comparison slot.
  ///
  /// - If state is null: sets propertyAId.
  /// - If only A is set: sets propertyBId (completing the pair).
  /// - If both are already set: clears and starts over with [propertyId] as A.
  void addToComparison(String propertyId) {
    final current = state;
    if (current == null) {
      state = PropertyComparison(
        propertyAId: propertyId,
        propertyBId: '',
      );
    } else if (current.propertyBId.isEmpty) {
      state = PropertyComparison(
        propertyAId: current.propertyAId,
        propertyBId: propertyId,
      );
    } else {
      // Both slots full — clear and restart
      state = PropertyComparison(
        propertyAId: propertyId,
        propertyBId: '',
      );
    }
  }

  void clearComparison() {
    state = null;
  }

  /// Returns true if [propertyId] is currently in slot A or slot B.
  bool isInComparison(String propertyId) {
    final current = state;
    if (current == null) return false;
    return current.propertyAId == propertyId ||
        current.propertyBId == propertyId;
  }
}
