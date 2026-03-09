import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ============================================================================
// Models
// ============================================================================

class SolvencyPassport {
  final int id;
  final int buyerId;
  final String? solvencyLevel;   // bronze | silver | gold
  final String? stressIndex;     // low_risk | medium_risk | high_risk
  final bool? knowsExtraCosts;
  final double? debtRatio;
  final bool? hasEmergencyFund;
  final String? paymentMethod;
  final bool? hasInitialSavings;
  final bool? hasPreApproval;
  final String? preApprovalPdfUrl;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const SolvencyPassport({
    required this.id,
    required this.buyerId,
    this.solvencyLevel,
    this.stressIndex,
    this.knowsExtraCosts,
    this.debtRatio,
    this.hasEmergencyFund,
    this.paymentMethod,
    this.hasInitialSavings,
    this.hasPreApproval,
    this.preApprovalPdfUrl,
    this.expiresAt,
    this.createdAt,
  });

  factory SolvencyPassport.fromJson(Map<String, dynamic> j) => SolvencyPassport(
        id: j['id'] as int,
        buyerId: j['buyer_id'] as int,
        solvencyLevel: j['solvency_level'] as String?,
        stressIndex: j['stress_index'] as String?,
        knowsExtraCosts: j['knows_extra_costs'] as bool?,
        debtRatio: (j['debt_ratio'] as num?)?.toDouble(),
        hasEmergencyFund: j['has_emergency_fund'] as bool?,
        paymentMethod: j['payment_method'] as String?,
        hasInitialSavings: j['has_initial_savings'] as bool?,
        hasPreApproval: j['has_pre_approval'] as bool?,
        preApprovalPdfUrl: j['pre_approval_pdf_url'] as String?,
        expiresAt: j['expires_at'] != null ? DateTime.tryParse(j['expires_at'] as String) : null,
        createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'] as String) : null,
      );

  bool get isValid => expiresAt != null && expiresAt!.isAfter(DateTime.now());
}

class PropertyViability {
  final int propertyId;
  final int propertyPrice;
  final int entryCostEstimate;
  final String verdict;          // "green" | "amber" | "red" | "insufficient_data"
  final String verdictLabel;
  final double? savingsCoveragePct;
  final double? dtiRatio;
  final int? monthlyMortgageEstimate;
  final bool hasFinancialDna;

  const PropertyViability({
    required this.propertyId,
    required this.propertyPrice,
    required this.entryCostEstimate,
    required this.verdict,
    required this.verdictLabel,
    this.savingsCoveragePct,
    this.dtiRatio,
    this.monthlyMortgageEstimate,
    required this.hasFinancialDna,
  });

  factory PropertyViability.fromJson(Map<String, dynamic> j) => PropertyViability(
        propertyId: j['property_id'] as int,
        propertyPrice: j['property_price'] as int,
        entryCostEstimate: j['entry_cost_estimate'] as int,
        verdict: j['verdict'] as String,
        verdictLabel: j['verdict_label'] as String,
        savingsCoveragePct: (j['savings_coverage_pct'] as num?)?.toDouble(),
        dtiRatio: (j['dti_ratio'] as num?)?.toDouble(),
        monthlyMortgageEstimate: j['monthly_mortgage_estimate'] as int?,
        hasFinancialDna: j['has_financial_dna'] as bool? ?? false,
      );
}

class AnonymisedPassport {
  final int buyerId;
  final String? solvencyLevel;
  final String? stressIndex;
  final bool knowsExtraCosts;
  final bool hasInitialSavings;
  final bool hasPreApproval;
  final String? paymentMethod;
  final DateTime? expiresAt;

  const AnonymisedPassport({
    required this.buyerId,
    this.solvencyLevel,
    this.stressIndex,
    required this.knowsExtraCosts,
    required this.hasInitialSavings,
    required this.hasPreApproval,
    this.paymentMethod,
    this.expiresAt,
  });

  factory AnonymisedPassport.fromJson(Map<String, dynamic> j) => AnonymisedPassport(
        buyerId: j['buyer_id'] as int,
        solvencyLevel: j['solvency_level'] as String?,
        stressIndex: j['stress_index'] as String?,
        knowsExtraCosts: j['knows_extra_costs'] as bool? ?? false,
        hasInitialSavings: j['has_initial_savings'] as bool? ?? false,
        hasPreApproval: j['has_pre_approval'] as bool? ?? false,
        paymentMethod: j['payment_method'] as String?,
        expiresAt: j['expires_at'] != null ? DateTime.tryParse(j['expires_at'] as String) : null,
      );

  bool get isValid => expiresAt != null && expiresAt!.isAfter(DateTime.now());
}

// ============================================================================
// Providers
// ============================================================================

const _storage = FlutterSecureStorage();

Future<String?> _getToken() => _storage.read(key: 'auth_token');

/// Fetches the current buyer's own solvency passport.
final mySolvencyProvider = FutureProvider.autoDispose<SolvencyPassport?>((ref) async {
  final token = await _getToken();
  if (token == null) return null;

  final dio = Dio();
  try {
    final resp = await dio.get(
      'http://localhost:8000/api/v1/solvency/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return SolvencyPassport.fromJson(resp.data as Map<String, dynamic>);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});

/// Fetches property-specific viability for the current buyer. Buyer-only — never shared with seller.
final propertyViabilityProvider = FutureProvider.autoDispose.family<PropertyViability?, String>((ref, propertyId) async {
  final token = await _getToken();
  if (token == null) return null;

  final dio = Dio();
  try {
    final resp = await dio.get(
      'http://localhost:8000/api/v1/solvency/viability/$propertyId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return PropertyViability.fromJson(resp.data as Map<String, dynamic>);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});

/// Fetches the anonymised buyer passport visible to the seller for a given offer.
final buyerPassportProvider = FutureProvider.autoDispose.family<AnonymisedPassport?, String>((ref, offerId) async {
  final token = await _getToken();
  if (token == null) return null;

  final dio = Dio();
  try {
    final resp = await dio.get(
      'http://localhost:8000/api/v1/solvency/offer/$offerId/buyer',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return AnonymisedPassport.fromJson(resp.data as Map<String, dynamic>);
  } on DioException catch (e) {
    // 404 = buyer has no passport yet; 403 = current user is the buyer (not seller)
    if (e.response?.statusCode == 404 || e.response?.statusCode == 403) return null;
    rethrow;
  }
});

/// Notifier for submitting the solvency wizard.
class SolvencyNotifier extends AsyncNotifier<SolvencyPassport?> {
  @override
  Future<SolvencyPassport?> build() async => null;

  Future<SolvencyPassport> submit({
    required bool termsAccepted,
    required bool knowsExtraCosts,
    required double debtRatio,
    required bool hasEmergencyFund,
    required String paymentMethod,
    required bool hasInitialSavings,
    required bool hasPreApproval,
    String? preApprovalPdfUrl,
    // ADN Financiero (Sprint V9)
    int? netMonthlyIncome,
    int? totalSavings,
    int? totalMonthlyDebt,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    state = const AsyncLoading();
    final dio = Dio();
    final resp = await dio.post(
      'http://localhost:8000/api/v1/solvency/me',
      data: {
        'terms_accepted': termsAccepted,
        'knows_extra_costs': knowsExtraCosts,
        'debt_ratio': debtRatio,
        'has_emergency_fund': hasEmergencyFund,
        'payment_method': paymentMethod,
        'has_initial_savings': hasInitialSavings,
        'has_pre_approval': hasPreApproval,
        if (preApprovalPdfUrl != null) 'pre_approval_pdf_url': preApprovalPdfUrl,
        if (netMonthlyIncome != null) 'net_monthly_income': netMonthlyIncome,
        if (totalSavings != null) 'total_savings': totalSavings,
        if (totalMonthlyDebt != null) 'total_monthly_debt': totalMonthlyDebt,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final passport = SolvencyPassport.fromJson(resp.data as Map<String, dynamic>);
    state = AsyncData(passport);
    ref.invalidate(mySolvencyProvider);
    return passport;
  }
}

final solvencyNotifierProvider =
    AsyncNotifierProvider<SolvencyNotifier, SolvencyPassport?>(SolvencyNotifier.new);
