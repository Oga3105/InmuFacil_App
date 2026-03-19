import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:inmufacil_frontend/domain/entities/property_comparison.dart';
import 'package:inmufacil_frontend/presentation/providers/comparison_provider.dart';

// ---------------------------------------------------------------------------
// Helper: create an isolated ProviderContainer for each test.
// ---------------------------------------------------------------------------
ProviderContainer _makeContainer() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ComparisonNotifier — slot management', () {
    test('initial state is null', () {
      final container = _makeContainer();
      expect(container.read(comparisonProvider), isNull);
    });

    test('addToComparison sets propertyAId when state is null', () {
      final container = _makeContainer();
      container.read(comparisonProvider.notifier).addToComparison('prop-1');
      final state = container.read(comparisonProvider);
      expect(state?.propertyAId, equals('prop-1'));
      expect(state?.propertyBId, equals(''));
    });

    test('addToComparison sets propertyBId when only A is set', () {
      final container = _makeContainer();
      container.read(comparisonProvider.notifier).addToComparison('prop-1');
      container.read(comparisonProvider.notifier).addToComparison('prop-2');
      final state = container.read(comparisonProvider);
      expect(state?.propertyAId, equals('prop-1'));
      expect(state?.propertyBId, equals('prop-2'));
    });

    test('addToComparison clears and restarts when both slots are full', () {
      final container = _makeContainer();
      final notifier = container.read(comparisonProvider.notifier);
      notifier.addToComparison('prop-1');
      notifier.addToComparison('prop-2');
      notifier.addToComparison('prop-3');
      final state = container.read(comparisonProvider);
      expect(state?.propertyAId, equals('prop-3'));
      expect(state?.propertyBId, equals(''));
    });

    test('clearComparison resets state to null', () {
      final container = _makeContainer();
      final notifier = container.read(comparisonProvider.notifier);
      notifier.addToComparison('prop-1');
      notifier.clearComparison();
      expect(container.read(comparisonProvider), isNull);
    });

    test('isInComparison returns false when state is null', () {
      final container = _makeContainer();
      expect(
        container.read(comparisonProvider.notifier).isInComparison('prop-1'),
        isFalse,
      );
    });

    test('isInComparison returns true for propertyAId', () {
      final container = _makeContainer();
      container.read(comparisonProvider.notifier).addToComparison('prop-1');
      expect(
        container.read(comparisonProvider.notifier).isInComparison('prop-1'),
        isTrue,
      );
    });

    test('isInComparison returns true for propertyBId', () {
      final container = _makeContainer();
      final notifier = container.read(comparisonProvider.notifier);
      notifier.addToComparison('prop-1');
      notifier.addToComparison('prop-2');
      expect(notifier.isInComparison('prop-2'), isTrue);
    });

    test('isInComparison returns false for unknown id', () {
      final container = _makeContainer();
      final notifier = container.read(comparisonProvider.notifier);
      notifier.addToComparison('prop-1');
      notifier.addToComparison('prop-2');
      expect(notifier.isInComparison('prop-999'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Winner highlighting logic (pure unit tests — no widget rendering)
  // ---------------------------------------------------------------------------

  group('Winner highlighting — lower wins (price)', () {
    bool? lowerWins(num? a, num? b) {
      if (a == null || b == null) return null;
      if (a == b) return null;
      return a < b;
    }

    test('A wins when priceA < priceB', () {
      expect(lowerWins(150000, 200000), isTrue);
    });

    test('B wins when priceB < priceA', () {
      expect(lowerWins(200000, 150000), isFalse);
    });

    test('tie returns null', () {
      expect(lowerWins(200000, 200000), isNull);
    });

    test('null A returns null', () {
      expect(lowerWins(null, 200000), isNull);
    });

    test('null B returns null', () {
      expect(lowerWins(200000, null), isNull);
    });
  });

  group('Winner highlighting — higher wins (surface)', () {
    bool? higherWins(num? a, num? b) {
      if (a == null || b == null) return null;
      if (a == b) return null;
      return a > b;
    }

    test('A wins when surfaceA > surfaceB', () {
      expect(higherWins(100, 80), isTrue);
    });

    test('B wins when surfaceB > surfaceA', () {
      expect(higherWins(80, 100), isFalse);
    });

    test('tie returns null', () {
      expect(higherWins(80, 80), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Null handling
  // ---------------------------------------------------------------------------

  group('Null handling — display values', () {
    String displayValue(String? v) =>
        v?.isNotEmpty == true ? v! : 'Sin datos';

    test('null value shows Sin datos', () {
      expect(displayValue(null), equals('Sin datos'));
    });

    test('empty string shows Sin datos', () {
      expect(displayValue(''), equals('Sin datos'));
    });

    test('valid value passes through', () {
      expect(displayValue('120 m²'), equals('120 m²'));
    });
  });

  // ---------------------------------------------------------------------------
  // PropertyComparison entity
  // ---------------------------------------------------------------------------

  group('PropertyComparison entity', () {
    test('stores both property IDs', () {
      const comparison = PropertyComparison(
        propertyAId: 'a-123',
        propertyBId: 'b-456',
      );
      expect(comparison.propertyAId, equals('a-123'));
      expect(comparison.propertyBId, equals('b-456'));
    });
  });
}
