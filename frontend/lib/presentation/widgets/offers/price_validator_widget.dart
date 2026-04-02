import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/dio_factory.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class PriceValidationResult {
  const PriceValidationResult({
    required this.verdict,
    required this.confidence,
    required this.reasoning,
    required this.riskLevel,
  });

  final String verdict;
  final String confidence;
  final String reasoning;
  final String riskLevel;

  factory PriceValidationResult.fromJson(Map<String, dynamic> j) =>
      PriceValidationResult(
        verdict: j['verdict'] as String? ?? 'JUSTO',
        confidence: j['confidence'] as String? ?? 'LOW',
        reasoning: j['reasoning'] as String? ?? '',
        riskLevel: j['risk_level'] as String? ?? 'MEDIUM',
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

class _PriceValidatorArgs {
  const _PriceValidatorArgs({
    required this.offerPrice,
    required this.askingPrice,
    required this.postalCode,
    required this.surfaceArea,
  });

  final int offerPrice;
  final int askingPrice;
  final String postalCode;
  final double surfaceArea;

  @override
  bool operator ==(Object other) =>
      other is _PriceValidatorArgs &&
      other.offerPrice == offerPrice &&
      other.askingPrice == askingPrice &&
      other.postalCode == postalCode &&
      other.surfaceArea == surfaceArea;

  @override
  int get hashCode =>
      Object.hash(offerPrice, askingPrice, postalCode, surfaceArea);
}

const _storage = FlutterSecureStorage();

final _priceValidatorProvider = FutureProvider.autoDispose
    .family<PriceValidationResult, _PriceValidatorArgs>(
  (ref, args) async {
    final token = await _storage.read(key: 'auth_token');
    final dio = buildAuthDio();
    final resp = await dio.post(
      '${EnvConfig.apiBaseUrl}/ai/validate-price',
      data: {
        'offer_price': args.offerPrice,
        'asking_price': args.askingPrice,
        'postal_code': args.postalCode,
        'surface_area': args.surfaceArea,
      },
      options: token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null,
    );
    return PriceValidationResult.fromJson(resp.data as Map<String, dynamic>);
  },
);

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class PriceValidatorWidget extends ConsumerWidget {
  const PriceValidatorWidget({
    super.key,
    required this.offerPrice,
    required this.askingPrice,
    required this.postalCode,
    required this.surfaceArea,
  });

  final int offerPrice;
  final int askingPrice;
  final String postalCode;
  final double surfaceArea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = _PriceValidatorArgs(
      offerPrice: offerPrice,
      askingPrice: askingPrice,
      postalCode: postalCode,
      surfaceArea: surfaceArea,
    );
    final asyncValue = ref.watch(_priceValidatorProvider(args));

    return asyncValue.when(
      loading: () => const _PriceValidatorLoading(),
      error: (err, _) => _PriceValidatorError(error: err.toString()),
      data: (result) => _PriceValidatorCard(result: result),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading state
// ---------------------------------------------------------------------------

class _PriceValidatorLoading extends StatelessWidget {
  const _PriceValidatorLoading();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _PriceValidatorError extends StatelessWidget {
  const _PriceValidatorError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: const Color(0xFFFFF1F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'price_validator.error'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data card
// ---------------------------------------------------------------------------

class _PriceValidatorCard extends StatelessWidget {
  const _PriceValidatorCard({required this.result});

  final PriceValidationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.balance_outlined,
                    color: const Color(0xFF135BEC), size: 20),
                const SizedBox(width: 8),
                Text(
                  'price_validator.title'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _VerdictBadge(verdict: result.verdict),
            const SizedBox(height: 10),
            if (result.reasoning.isNotEmpty)
              Text(
                result.reasoning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.45,
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                _ConfidenceBadge(confidence: result.confidence),
                const SizedBox(width: 8),
                _RiskBadge(riskLevel: result.riskLevel),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'price_validator.disclaimer'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verdict badge
// ---------------------------------------------------------------------------

class _VerdictBadge extends StatelessWidget {
  const _VerdictBadge({required this.verdict});

  final String verdict;

  Color get _color {
    switch (verdict.toUpperCase()) {
      case 'JUSTO':
        return const Color(0xFF16A34A);
      case 'ALGO_ALTO':
      case 'ALGO_BAJO':
        return const Color(0xFFF59E0B);
      case 'MUY_ALTO':
      case 'MUY_BAJO':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey.shade500;
    }
  }

  String _label() {
    switch (verdict.toUpperCase()) {
      case 'JUSTO':
        return 'price_validator.verdict_justo'.tr();
      case 'ALGO_ALTO':
        return 'price_validator.verdict_algo_alto'.tr();
      case 'ALGO_BAJO':
        return 'price_validator.verdict_algo_bajo'.tr();
      case 'MUY_ALTO':
        return 'price_validator.verdict_muy_alto'.tr();
      case 'MUY_BAJO':
        return 'price_validator.verdict_muy_bajo'.tr();
      default:
        return verdict;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confidence badge
// ---------------------------------------------------------------------------

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final String confidence;

  Color get _color {
    switch (confidence.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFF16A34A);
      case 'MEDIUM':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey.shade500;
    }
  }

  String get _label {
    switch (confidence.toUpperCase()) {
      case 'HIGH':
        return 'price_validator.confidence_high'.tr();
      case 'MEDIUM':
        return 'price_validator.confidence_medium'.tr();
      default:
        return 'price_validator.confidence_low'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Risk badge
// ---------------------------------------------------------------------------

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.riskLevel});

  final String riskLevel;

  Color get _color {
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return const Color(0xFF16A34A);
      case 'HIGH':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String get _label {
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return 'price_validator.risk_low'.tr();
      case 'HIGH':
        return 'price_validator.risk_high'.tr();
      default:
        return 'price_validator.risk_medium'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
