import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/formatters/currency_input_formatter.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class MarketPriceResult {
  const MarketPriceResult({
    required this.pricePerM2,
    required this.sampleSize,
    required this.zoneLabel,
    required this.confidence,
    required this.lowDensity,
    this.message,
    this.sourceLabel =
        'Fuente: Sistema Estatal de Referencia de Precios / Catastro',
  });

  final int pricePerM2;
  final int sampleSize;
  final String zoneLabel;
  final String confidence;
  final bool lowDensity;
  final String? message;

  /// Attribution label for the data source of this market price result.
  final String sourceLabel;

  factory MarketPriceResult.fromJson(Map<String, dynamic> j) =>
      MarketPriceResult(
        pricePerM2: (j['price_per_m2'] as num?)?.toInt() ?? 0,
        sampleSize: (j['sample_size'] as num?)?.toInt() ?? 0,
        zoneLabel: j['zone_label'] as String? ?? '',
        confidence: j['confidence'] as String? ?? 'LOW',
        lowDensity: j['low_density'] as bool? ?? true,
        message: j['message'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

class _MarketPriceArgs {
  const _MarketPriceArgs({
    required this.postalCode,
    required this.surfaceArea,
    required this.propertyType,
  });

  final String postalCode;
  final double surfaceArea;
  final String propertyType;

  @override
  bool operator ==(Object other) =>
      other is _MarketPriceArgs &&
      other.postalCode == postalCode &&
      other.surfaceArea == surfaceArea &&
      other.propertyType == propertyType;

  @override
  int get hashCode => Object.hash(postalCode, surfaceArea, propertyType);
}

const _storage = FlutterSecureStorage();

final _marketPriceProvider =
    FutureProvider.autoDispose.family<MarketPriceResult, _MarketPriceArgs>(
  (ref, args) async {
    final token = await _storage.read(key: 'auth_token');
    final dio = Dio();
    try {
      final resp = await dio.post(
        'http://localhost:8000/api/v1/ai/market-price',
        data: {
          'postal_code': args.postalCode,
          'surface_area': args.surfaceArea,
          'property_type': args.propertyType,
        },
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      return MarketPriceResult.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode != null) {
        return const MarketPriceResult(
          pricePerM2: 0,
          sampleSize: 0,
          zoneLabel: '',
          confidence: 'LOW',
          lowDensity: true,
          message: null,
        );
      }
      rethrow;
    }
  },
);

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class MarketPriceWidget extends ConsumerWidget {
  const MarketPriceWidget({
    super.key,
    required this.postalCode,
    required this.surfaceArea,
    required this.propertyType,
  });

  final String postalCode;
  final double surfaceArea;
  final String propertyType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = _MarketPriceArgs(
      postalCode: postalCode,
      surfaceArea: surfaceArea,
      propertyType: propertyType,
    );
    final asyncValue = ref.watch(_marketPriceProvider(args));

    return asyncValue.when(
      loading: () => const _MarketPriceLoading(),
      error: (_, __) => const _MarketPriceError(),
      data: (result) => result.lowDensity
          ? const _MarketPriceLowDensity()
          : _MarketPriceCard(result: result),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading state
// ---------------------------------------------------------------------------

class _MarketPriceLoading extends StatelessWidget {
  const _MarketPriceLoading();

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
// Low-density state (sample_size < 5)
// ---------------------------------------------------------------------------

class _MarketPriceLowDensity extends StatelessWidget {
  const _MarketPriceLowDensity();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade500, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'market_price.low_density'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
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
// Error state
// ---------------------------------------------------------------------------

class _MarketPriceError extends StatelessWidget {
  const _MarketPriceError();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade500, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'market_price.unavailable'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
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

class _MarketPriceCard extends StatelessWidget {
  const _MarketPriceCard({required this.result});

  final MarketPriceResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedPrice = CurrencyInputFormatter.format(result.pricePerM2);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined,
                    color: const Color(0xFF2563EB), size: 20),
                const SizedBox(width: 8),
                Text(
                  'market_price.title'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$formattedPrice EUR/m2',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              result.sourceLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 6),
            if (result.zoneLabel.isNotEmpty)
              Text(
                result.zoneLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'market_price.no_extrapolation'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 10),
            _ConfidenceBadge(confidence: result.confidence),
          ],
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

  Color get _badgeColor {
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
        return 'market_price.confidence_high'.tr();
      case 'MEDIUM':
        return 'market_price.confidence_medium'.tr();
      default:
        return 'market_price.confidence_low'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _badgeColor.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _badgeColor,
        ),
      ),
    );
  }
}
