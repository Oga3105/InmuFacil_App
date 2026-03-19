// Tests for solvency passport level calculation logic.
//
// These tests validate the pure scoring algorithm and max offer capacity
// formula without any widget rendering or network calls.
//
// Scoring formula:
//   score = (net_monthly_income * 0.35 / 1000)
//          + (job_tenure_months / 12)
//          + (1 if contract_type == 'indefinido' else 0)
//
// Level thresholds:
//   platinum >= 8, gold >= 5, silver >= 3, bronze < 3
//
// Max offer capacity:
//   (net_monthly_income - existing_debts) * 0.35 / 0.004

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Pure Dart re-implementation of the backend scoring logic for unit tests.
// These functions mirror backend/src/routes/solvency_passport.py exactly.
// ---------------------------------------------------------------------------

String computeSolvencyLevel({
  int? netMonthlyIncome,
  int? jobTenureMonths,
  String? contractType,
}) {
  double score = 0.0;

  if (netMonthlyIncome != null && netMonthlyIncome > 0) {
    score += (netMonthlyIncome * 0.35) / 1000.0;
  }

  if (jobTenureMonths != null && jobTenureMonths > 0) {
    score += jobTenureMonths / 12.0;
  }

  if (contractType != null && contractType.toLowerCase() == 'indefinido') {
    score += 1.0;
  }

  if (score >= 8.0) return 'platinum';
  if (score >= 5.0) return 'gold';
  if (score >= 3.0) return 'silver';
  return 'bronze';
}

int? computeMaxOfferCapacity({
  int? netMonthlyIncome,
  int? existingDebts,
}) {
  if (netMonthlyIncome == null || netMonthlyIncome <= 0) return null;

  final debts = (existingDebts != null && existingDebts > 0) ? existingDebts : 0;
  final availableMonthly = netMonthlyIncome - debts;

  if (availableMonthly <= 0) return null;

  final capacity = (availableMonthly * 0.35) / 0.004;
  return capacity.floor().clamp(0, 9999999999);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('computeSolvencyLevel — level thresholds', () {
    test('returns bronze when all inputs are null', () {
      expect(
        computeSolvencyLevel(),
        equals('bronze'),
      );
    });

    test('returns bronze for low income, short tenure, no indefinido', () {
      // score = (1500 * 0.35 / 1000) + (6 / 12) + 0 = 0.525 + 0.5 = 1.025
      expect(
        computeSolvencyLevel(
          netMonthlyIncome: 1500,
          jobTenureMonths: 6,
          contractType: 'temporal',
        ),
        equals('bronze'),
      );
    });

    test('returns silver when score is exactly 3.0', () {
      // We need score = 3.0 exactly:
      // (income * 0.35 / 1000) + (months / 12) + 0 = 3.0
      // Use income=0, months=36 -> 36/12 = 3.0
      expect(
        computeSolvencyLevel(
          netMonthlyIncome: null,
          jobTenureMonths: 36,
          contractType: 'temporal',
        ),
        equals('silver'),
      );
    });

    test('returns silver for typical mid-range profile', () {
      // score = (2000 * 0.35 / 1000) + (24 / 12) + 0 = 0.7 + 2.0 = 2.7 -> bronze
      // Adjust: add indefinido (+1) => 3.7 -> silver
      expect(
        computeSolvencyLevel(
          netMonthlyIncome: 2000,
          jobTenureMonths: 24,
          contractType: 'indefinido',
        ),
        equals('silver'),
      );
    });

    test('returns gold when score is exactly 5.0', () {
      // (income * 0.35 / 1000) + (months / 12) + 1 = 5.0
      // Use income=0, months=48, indefinido: 0 + 4.0 + 1 = 5.0
      expect(
        computeSolvencyLevel(
          netMonthlyIncome: null,
          jobTenureMonths: 48,
          contractType: 'indefinido',
        ),
        equals('gold'),
      );
    });

    test('returns gold for solid professional profile', () {
      // score = (3500 * 0.35 / 1000) + (60 / 12) + 1 = 1.225 + 5.0 + 1 = 7.225
      // -> gold (< 8)
      expect(
        computeSolvencyLevel(
          netMonthlyIncome: 3500,
          jobTenureMonths: 60,
          contractType: 'indefinido',
        ),
        equals('gold'),
      );
    });

    test('returns platinum when score is exactly 8.0', () {
      // (income * 0.35 / 1000) + (months / 12) + 1 = 8.0
      // income=0, months=84, indefinido: 0 + 7.0 + 1 = 8.0
      expect(
        computeSolvencyLevel(
          netMonthlyIncome: null,
          jobTenureMonths: 84,
          contractType: 'indefinido',
        ),
        equals('platinum'),
      );
    });

    test('returns platinum for senior high-income profile', () {
      // score = (6000 * 0.35 / 1000) + (120 / 12) + 1 = 2.1 + 10 + 1 = 13.1
      expect(
        computeSolvencyLevel(
          netMonthlyIncome: 6000,
          jobTenureMonths: 120,
          contractType: 'indefinido',
        ),
        equals('platinum'),
      );
    });

    test('indefinido bonus applies only when contract is exactly indefinido', () {
      const cases = ['temporal', 'autonomo', 'otros', 'TEMPORAL', 'AUTONOMO'];
      for (final c in cases) {
        // With 0 income and 0 tenure, only the contract bonus matters.
        // Non-indefinido contracts should yield score = 0 -> bronze.
        expect(
          computeSolvencyLevel(contractType: c),
          equals('bronze'),
          reason: 'Expected bronze for contract_type=$c',
        );
      }
    });

    test('indefinido matching is case-insensitive', () {
      // Dart implementation normalizes to lower — verify both cases
      expect(
        computeSolvencyLevel(
          netMonthlyIncome: null,
          jobTenureMonths: 84,
          contractType: 'INDEFINIDO',
        ),
        equals('platinum'),
      );
    });

    test('zero income does not contribute to score', () {
      // score = 0 + (12/12) + 0 = 1.0 -> bronze
      expect(
        computeSolvencyLevel(
          netMonthlyIncome: 0,
          jobTenureMonths: 12,
          contractType: 'temporal',
        ),
        equals('bronze'),
      );
    });
  });

  group('computeMaxOfferCapacity — capacity formula', () {
    test('returns null when income is null', () {
      expect(computeMaxOfferCapacity(), isNull);
    });

    test('returns null when income is zero', () {
      expect(computeMaxOfferCapacity(netMonthlyIncome: 0), isNull);
    });

    test('returns null when income equals existing debts', () {
      expect(
        computeMaxOfferCapacity(
          netMonthlyIncome: 2000,
          existingDebts: 2000,
        ),
        isNull,
      );
    });

    test('returns null when debts exceed income', () {
      expect(
        computeMaxOfferCapacity(
          netMonthlyIncome: 1000,
          existingDebts: 1500,
        ),
        isNull,
      );
    });

    test('calculates correctly with no debts', () {
      // (2000 - 0) * 0.35 / 0.004 = 700 / 0.004 = 175000
      expect(
        computeMaxOfferCapacity(netMonthlyIncome: 2000),
        equals(175000),
      );
    });

    test('calculates correctly with partial debts', () {
      // (3000 - 500) * 0.35 / 0.004 = 875 / 0.004 = 218750
      expect(
        computeMaxOfferCapacity(
          netMonthlyIncome: 3000,
          existingDebts: 500,
        ),
        equals(218750),
      );
    });

    test('null debts treated as zero', () {
      // (2500 - 0) * 0.35 / 0.004 = 875 / 0.004 = 218750
      expect(
        computeMaxOfferCapacity(
          netMonthlyIncome: 2500,
          existingDebts: null,
        ),
        equals(218750),
      );
    });

    test('zero debts treated as zero', () {
      // Same as no debts: (2500 * 0.35 / 0.004) = 218750
      expect(
        computeMaxOfferCapacity(
          netMonthlyIncome: 2500,
          existingDebts: 0,
        ),
        equals(218750),
      );
    });

    test('result is always a non-negative integer', () {
      final result = computeMaxOfferCapacity(netMonthlyIncome: 1200);
      expect(result, isNotNull);
      expect(result, greaterThanOrEqualTo(0));
      expect(result, isA<int>());
    });
  });

  group('solvency level + capacity integration', () {
    test('bronze profile has lower capacity than gold profile', () {
      final bronzeCapacity = computeMaxOfferCapacity(netMonthlyIncome: 1500);
      final goldCapacity = computeMaxOfferCapacity(netMonthlyIncome: 4000);

      expect(bronzeCapacity, isNotNull);
      expect(goldCapacity, isNotNull);
      expect(goldCapacity!, greaterThan(bronzeCapacity!));
    });

    test('platinum profile: level is platinum and capacity is high', () {
      final level = computeSolvencyLevel(
        netMonthlyIncome: 6000,
        jobTenureMonths: 120,
        contractType: 'indefinido',
      );
      final capacity = computeMaxOfferCapacity(netMonthlyIncome: 6000);

      expect(level, equals('platinum'));
      expect(capacity, isNotNull);
      expect(capacity!, greaterThan(500000));
    });
  });
}
