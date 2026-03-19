/// Unit tests for charge classification logic used in NotaSimpleAnalyzerWidget
/// and EncumbranceResolutionWidget.
///
/// These tests validate:
/// - Charge type to color/risk mapping
/// - Surface discrepancy detection threshold (>5%)
/// - GDPR anonymization helpers (titular/DNI partial)
/// - Risk level label assignment
library;

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Isolated logic extracted from widgets for unit testing
// ---------------------------------------------------------------------------

/// Returns the risk color code string for a given charge type.
/// Maps to the UI color rules in EncumbranceResolutionWidget.
String chargeTypeToColorCode(String chargeType) {
  switch (chargeType) {
    case 'judicial':
      return 'red';
    case 'financiera':
      return 'orange';
    case 'administrativa':
      return 'blue';
    default:
      return 'blue';
  }
}

/// Returns the risk badge key for a given risk level.
String riskLevelToBadgeKey(String riskLevel) {
  switch (riskLevel) {
    case 'alto':
      return 'nota_simple.charge_risk_alto';
    case 'estandar':
      return 'nota_simple.charge_risk_estandar';
    default:
      return 'nota_simple.charge_risk_informativo';
  }
}

/// Returns whether a surface discrepancy exceeds the alert threshold (5%).
bool hasSurfaceAlert(double extractedM2, double advertisedM2) {
  if (advertisedM2 == 0) return false;
  final discrepancy =
      (extractedM2 - advertisedM2).abs() / advertisedM2;
  return discrepancy > 0.05;
}

/// Computes surface discrepancy percentage, rounded to 2 decimal places.
double? computeDiscrepancyPct(double? extractedM2, double advertisedM2) {
  if (extractedM2 == null || advertisedM2 == 0) return null;
  final discrepancy =
      (extractedM2 - advertisedM2).abs() / advertisedM2 * 100;
  return double.parse(discrepancy.toStringAsFixed(2));
}

/// Validates that a DNI partial contains only the last 4 characters
/// (GDPR rule: never store/display full NIF).
bool isValidDniPartial(String dniPartial) {
  return dniPartial.length <= 4;
}

/// Returns resolution card background color key for a charge type.
String chargeTypeToCardBackground(String chargeType) {
  switch (chargeType) {
    case 'judicial':
      return 'orange_soft';
    case 'financiera':
      return 'blue_light';
    default:
      return 'grey';
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('chargeTypeToColorCode', () {
    test('judicial maps to red', () {
      expect(chargeTypeToColorCode('judicial'), 'red');
    });

    test('financiera maps to orange', () {
      expect(chargeTypeToColorCode('financiera'), 'orange');
    });

    test('administrativa maps to blue', () {
      expect(chargeTypeToColorCode('administrativa'), 'blue');
    });

    test('unknown type defaults to blue', () {
      expect(chargeTypeToColorCode('unknown'), 'blue');
    });

    test('empty string defaults to blue', () {
      expect(chargeTypeToColorCode(''), 'blue');
    });
  });

  group('riskLevelToBadgeKey', () {
    test('alto returns alto key', () {
      expect(riskLevelToBadgeKey('alto'), 'nota_simple.charge_risk_alto');
    });

    test('estandar returns estandar key', () {
      expect(
          riskLevelToBadgeKey('estandar'), 'nota_simple.charge_risk_estandar');
    });

    test('informativo returns informativo key', () {
      expect(riskLevelToBadgeKey('informativo'),
          'nota_simple.charge_risk_informativo');
    });

    test('unknown level defaults to informativo key', () {
      expect(
          riskLevelToBadgeKey('unknown'), 'nota_simple.charge_risk_informativo');
    });
  });

  group('hasSurfaceAlert — 5% threshold', () {
    test('exact match does not trigger alert', () {
      expect(hasSurfaceAlert(90.0, 90.0), isFalse);
    });

    test('4.9% discrepancy does not trigger alert', () {
      expect(hasSurfaceAlert(94.41, 90.0), isFalse);
    });

    test('5.0% discrepancy does not trigger alert (boundary exclusive)', () {
      // 90 * 1.05 = 94.5 => discrepancy = 5.0%, boundary is > 5% so false
      expect(hasSurfaceAlert(94.5, 90.0), isFalse);
    });

    test('5.1% discrepancy triggers alert', () {
      // 90 * 1.051 = 94.59
      expect(hasSurfaceAlert(94.59, 90.0), isTrue);
    });

    test('large discrepancy triggers alert', () {
      expect(hasSurfaceAlert(110.0, 90.0), isTrue);
    });

    test('registered smaller than advertised triggers alert if >5%', () {
      // advertised=100, extracted=90 => 10% discrepancy
      expect(hasSurfaceAlert(90.0, 100.0), isTrue);
    });

    test('zero advertised surface does not trigger alert', () {
      expect(hasSurfaceAlert(90.0, 0.0), isFalse);
    });
  });

  group('computeDiscrepancyPct', () {
    test('returns null when extractedM2 is null', () {
      expect(computeDiscrepancyPct(null, 90.0), isNull);
    });

    test('returns null when advertised is zero', () {
      expect(computeDiscrepancyPct(90.0, 0.0), isNull);
    });

    test('returns 0.0 for identical surfaces', () {
      expect(computeDiscrepancyPct(90.0, 90.0), 0.0);
    });

    test('returns correct percentage for 10% discrepancy', () {
      expect(computeDiscrepancyPct(99.0, 90.0), 10.0);
    });

    test('returns correct percentage for 5% discrepancy', () {
      expect(computeDiscrepancyPct(94.5, 90.0), 5.0);
    });

    test('rounds to 2 decimal places', () {
      // 1/3 = 33.333...% -> should round to 33.33
      final result = computeDiscrepancyPct(90.0 + 90.0 / 3, 90.0);
      expect(result, closeTo(33.33, 0.01));
    });
  });

  group('isValidDniPartial — GDPR rule', () {
    test('4-digit partial is valid', () {
      expect(isValidDniPartial('1234'), isTrue);
    });

    test('mask **** is valid', () {
      expect(isValidDniPartial('****'), isTrue);
    });

    test('3-digit partial is valid', () {
      expect(isValidDniPartial('123'), isTrue);
    });

    test('full 9-char NIF is invalid', () {
      expect(isValidDniPartial('12345678Z'), isFalse);
    });

    test('5-char string is invalid', () {
      expect(isValidDniPartial('12345'), isFalse);
    });

    test('empty string is valid (no data shown)', () {
      expect(isValidDniPartial(''), isTrue);
    });
  });

  group('chargeTypeToCardBackground', () {
    test('judicial returns orange_soft', () {
      expect(chargeTypeToCardBackground('judicial'), 'orange_soft');
    });

    test('financiera returns blue_light', () {
      expect(chargeTypeToCardBackground('financiera'), 'blue_light');
    });

    test('administrativa returns grey', () {
      expect(chargeTypeToCardBackground('administrativa'), 'grey');
    });

    test('unknown defaults to grey', () {
      expect(chargeTypeToCardBackground('unknown'), 'grey');
    });
  });
}
