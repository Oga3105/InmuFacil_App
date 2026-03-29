// Tax cost calculator for residential property purchases in Spain.
//
// Provides a breakdown of the main buyer-side acquisition costs:
//   - ITP (Impuesto de Transmisiones Patrimoniales): rate per CCAA.
//   - Notary fee: 0.5 % of offer amount.
//   - Land Registry fee: 0.3 % of offer amount.
//   - Agency fee: 3 % of offer amount (shown separately, not in total).
//
// All monetary amounts are integers (euros, no decimals).
//
// IMPORTANT: These are indicative estimates. Actual costs depend on specific
// municipal taxes, negotiated rates, and other variable factors.

import 'ccaa_utils.dart';

/// Result of a buying-cost calculation for a property purchase.
class TaxResult {
  const TaxResult({
    required this.itpAmount,
    required this.notaryFee,
    required this.registryFee,
    required this.agencyFee,
    required this.total,
    required this.isForal,
    required this.ccaaName,
    required this.itpRate,
    this.dataSource = 'Fuente: Ley ITP y AJD vigente 2026',
  });

  /// ITP amount in euros. Zero when [isForal] is true.
  final int itpAmount;

  /// Notary fee estimate in euros (0.5 % of offer amount).
  final int notaryFee;

  /// Land registry fee estimate in euros (0.3 % of offer amount).
  final int registryFee;

  /// Agency fee estimate in euros (3 % of offer amount).
  /// Shown separately — NOT included in [total].
  final int agencyFee;

  /// Total acquisition cost: [itpAmount] + [notaryFee] + [registryFee].
  /// Agency fee is excluded because it is optional and conditional.
  final int total;

  /// True when the CCAA uses a foral fiscal regime (Pais Vasco, Navarra)
  /// or belongs to Canarias. In these cases [itpAmount] is 0 and callers
  /// must display the fiscal truth clause instead of a fixed ITP figure.
  final bool isForal;

  /// Human-readable name of the detected CCAA.
  final String ccaaName;

  /// The ITP rate applied (e.g. 0.07 for 7 %). Null when [isForal] is true.
  final double? itpRate;

  /// Legal source attribution for the tax rates used in this calculation.
  final String dataSource;
}

/// Calculates the estimated buying costs for a property in [ccaa].
///
/// [offerAmount] must be a positive integer (euros).
TaxResult calculateBuyingCosts(int offerAmount, ComunidadAutonoma ccaa) {
  final rate = itpRateForCcaa(ccaa);
  final isForal = rate == null;

  final itpAmount = isForal ? 0 : (offerAmount * rate!).truncate();
  final notaryFee = (offerAmount * 0.005).truncate();
  final registryFee = (offerAmount * 0.003).truncate();
  final agencyFee = (offerAmount * 0.03).truncate();
  final total = itpAmount + notaryFee + registryFee;

  return TaxResult(
    itpAmount: itpAmount,
    notaryFee: notaryFee,
    registryFee: registryFee,
    agencyFee: agencyFee,
    total: total,
    isForal: isForal,
    ccaaName: ccaaDisplayName[ccaa] ?? 'Desconocida',
    itpRate: rate,
  );
}
