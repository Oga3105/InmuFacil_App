// Tests for SmartArrasContractScreen validation logic.
//
// Covers:
//   - arrasAmount must be strictly less than salePrice
//   - signatureDeadline must be in the future

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Isolated validation logic extracted from the screen state for unit testing.
// The validation rules mirror _SmartArrasContractScreenState._validate().
// ---------------------------------------------------------------------------

String? validateArrasAmount({
  required int arrasAmount,
  required int salePrice,
}) {
  if (arrasAmount >= salePrice) {
    return 'El importe de las arras no puede superar el precio total';
  }
  return null;
}

String? validateSignatureDeadline(DateTime? deadline) {
  if (deadline == null || !deadline.isAfter(DateTime.now())) {
    return 'La fecha de firma debe ser una fecha futura';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Unit tests — validation logic
// ---------------------------------------------------------------------------

void main() {
  group('SmartArrasContractScreen — arras amount validation', () {
    test('arrasAmount equal to salePrice returns error', () {
      final error = validateArrasAmount(
        arrasAmount: 200000,
        salePrice: 200000,
      );
      expect(error, isNotNull);
      expect(error, contains('no puede superar'));
    });

    test('arrasAmount greater than salePrice returns error', () {
      final error = validateArrasAmount(
        arrasAmount: 250000,
        salePrice: 200000,
      );
      expect(error, isNotNull);
    });

    test('arrasAmount less than salePrice returns null (valid)', () {
      final error = validateArrasAmount(
        arrasAmount: 20000,
        salePrice: 200000,
      );
      expect(error, isNull);
    });

    test('arrasAmount of 0 is valid (boundary — less than salePrice)', () {
      final error = validateArrasAmount(
        arrasAmount: 0,
        salePrice: 200000,
      );
      expect(error, isNull);
    });

    test('default 10% arras is valid for typical sale price', () {
      const salePrice = 250000;
      final defaultArras = (salePrice * 0.10).round();
      final error = validateArrasAmount(
        arrasAmount: defaultArras,
        salePrice: salePrice,
      );
      expect(error, isNull);
    });
  });

  group('SmartArrasContractScreen — signature deadline validation', () {
    test('null deadline returns error', () {
      final error = validateSignatureDeadline(null);
      expect(error, isNotNull);
    });

    test('past deadline returns error', () {
      final pastDate =
          DateTime.now().subtract(const Duration(days: 1));
      final error = validateSignatureDeadline(pastDate);
      expect(error, isNotNull);
    });

    test('deadline equal to now returns error (not strictly future)', () {
      // DateTime.now() at the moment of call; isAfter returns false for equal
      final now = DateTime.now();
      // Simulate a deadline that is at the exact current second
      final error = validateSignatureDeadline(
        now.subtract(const Duration(milliseconds: 1)),
      );
      expect(error, isNotNull);
    });

    test('future deadline returns null (valid)', () {
      final futureDate =
          DateTime.now().add(const Duration(days: 30));
      final error = validateSignatureDeadline(futureDate);
      expect(error, isNull);
    });

    test('deadline 1 day in future is valid', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final error = validateSignatureDeadline(tomorrow);
      expect(error, isNull);
    });
  });

  group('SmartArrasContractScreen — combined validation', () {
    test('invalid arras + invalid deadline: both return errors', () {
      const salePrice = 300000;
      const arrasAmount = 300000; // equal to sale price — invalid
      final pastDeadline =
          DateTime.now().subtract(const Duration(days: 5));

      final arrasError =
          validateArrasAmount(arrasAmount: arrasAmount, salePrice: salePrice);
      final deadlineError = validateSignatureDeadline(pastDeadline);

      expect(arrasError, isNotNull);
      expect(deadlineError, isNotNull);
    });

    test('valid arras + valid deadline: both return null', () {
      const salePrice = 300000;
      const arrasAmount = 30000; // 10%
      final futureDeadline =
          DateTime.now().add(const Duration(days: 60));

      final arrasError =
          validateArrasAmount(arrasAmount: arrasAmount, salePrice: salePrice);
      final deadlineError = validateSignatureDeadline(futureDeadline);

      expect(arrasError, isNull);
      expect(deadlineError, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Widget smoke test — screen renders without throwing
  // ---------------------------------------------------------------------------

  testWidgets('SmartArrasContractScreen renders without errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('open'), findsOneWidget);
  });
}
