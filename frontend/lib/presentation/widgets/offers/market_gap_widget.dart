import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class MarketGapResult {
  const MarketGapResult({
    required this.realTransactionPricePerM2,
    required this.gapPct,
    required this.offerAnalysis,
    required this.recommendation,
    required this.sampleSize,
    required this.lowData,
    required this.dataSource,
    required this.disclaimer,
  });

  final int? realTransactionPricePerM2;
  final double? gapPct;
  final String offerAnalysis;
  final String recommendation;
  final int sampleSize;
  final bool lowData;
  final String dataSource;
  final String disclaimer;

  factory MarketGapResult.fromJson(Map<String, dynamic> j) => MarketGapResult(
        realTransactionPricePerM2:
            j['real_transaction_price_per_m2'] as int?,
        gapPct: (j['gap_pct'] as num?)?.toDouble(),
        offerAnalysis: j['offer_analysis'] as String? ?? '',
        recommendation: j['recommendation'] as String? ?? '',
        sampleSize: j['sample_size'] as int? ?? 0,
        lowData: j['low_data'] as bool? ?? true,
        dataSource: j['data_source'] as String? ?? '',
        disclaimer: j['disclaimer'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// Provider args
// ---------------------------------------------------------------------------

class _MarketGapArgs {
  const _MarketGapArgs({
    required this.postalCode,
    required this.askingPrice,
    required this.surfaceM2,
    required this.userOffer,
  });

  final String postalCode;
  final int askingPrice;
  final double surfaceM2;
  final int userOffer;

  @override
  bool operator ==(Object other) =>
      other is _MarketGapArgs &&
      other.postalCode == postalCode &&
      other.askingPrice == askingPrice &&
      other.surfaceM2 == surfaceM2 &&
      other.userOffer == userOffer;

  @override
  int get hashCode =>
      Object.hash(postalCode, askingPrice, surfaceM2, userOffer);
}

const _storage = FlutterSecureStorage();

final _marketGapProvider =
    FutureProvider.autoDispose.family<MarketGapResult, _MarketGapArgs>(
  (ref, args) async {
    final token = await _storage.read(key: 'auth_token');
    final dio = Dio();
    final resp = await dio.post(
      'http://localhost:8000/api/v1/ai/market-gap',
      data: {
        'postal_code': args.postalCode,
        'asking_price': args.askingPrice,
        'surface_m2': args.surfaceM2,
        'user_offer': args.userOffer,
      },
      options: token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null,
    );
    return MarketGapResult.fromJson(resp.data as Map<String, dynamic>);
  },
);

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class MarketGapWidget extends ConsumerWidget {
  const MarketGapWidget({
    super.key,
    required this.postalCode,
    required this.askingPrice,
    required this.surfaceM2,
    required this.userOffer,
  });

  final String postalCode;
  final int askingPrice;
  final double surfaceM2;
  final int userOffer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = _MarketGapArgs(
      postalCode: postalCode,
      askingPrice: askingPrice,
      surfaceM2: surfaceM2,
      userOffer: userOffer,
    );
    final asyncValue = ref.watch(_marketGapProvider(args));

    return asyncValue.when(
      loading: () => const _MarketGapLoading(),
      error: (err, _) => _MarketGapError(error: err.toString()),
      data: (result) => result.lowData
          ? const _MarketGapLowData()
          : _MarketGapCard(
              result: result,
              askingPrice: askingPrice,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading state
// ---------------------------------------------------------------------------

class _MarketGapLoading extends StatelessWidget {
  const _MarketGapLoading();

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

class _MarketGapError extends StatelessWidget {
  const _MarketGapError({required this.error});

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
            const Icon(
              Icons.error_outline,
              color: Color(0xFFEF4444),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'market_gap.error'.tr(),
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
// Low data state
// ---------------------------------------------------------------------------

class _MarketGapLowData extends StatelessWidget {
  const _MarketGapLowData();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'market_gap.low_data'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.4,
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

class _MarketGapCard extends StatelessWidget {
  const _MarketGapCard({
    required this.result,
    required this.askingPrice,
  });

  final MarketGapResult result;
  final int askingPrice;

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
            // Title
            Row(
              children: [
                const Icon(
                  Icons.bar_chart_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'market_gap.title'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bar comparison: asking price vs real transaction price
            _PriceBarComparison(
              askingPrice: askingPrice,
              realTransactionPrice:
                  (result.realTransactionPricePerM2 ?? 0) * 1,
            ),
            const SizedBox(height: 12),

            // Gap percentage
            if (result.gapPct != null) ...[
              Row(
                children: [
                  Text(
                    'market_gap.gap_label'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${result.gapPct!.toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Offer analysis
            if (result.offerAnalysis.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.35),
                  ),
                ),
                child: Text(
                  result.offerAnalysis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            if (result.offerAnalysis.isNotEmpty) const SizedBox(height: 10),

            // Recommendation
            if (result.recommendation.isNotEmpty)
              Text(
                result.recommendation,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.45,
                ),
              ),
            if (result.recommendation.isNotEmpty) const SizedBox(height: 10),

            // Data source
            Text(
              result.dataSource,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),

            // Disclaimer
            Text(
              result.disclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade400,
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
// Price bar comparison
// ---------------------------------------------------------------------------

class _PriceBarComparison extends StatelessWidget {
  const _PriceBarComparison({
    required this.askingPrice,
    required this.realTransactionPrice,
  });

  final int askingPrice;
  final int realTransactionPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxPrice =
        askingPrice > realTransactionPrice ? askingPrice : realTransactionPrice;

    if (maxPrice <= 0) return const SizedBox.shrink();

    final askingFraction = askingPrice / maxPrice;
    final realFraction = realTransactionPrice > 0
        ? realTransactionPrice / maxPrice
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BarRow(
          label: 'market_gap.asking_price_label'.tr(),
          fraction: askingFraction,
          color: const Color(0xFF2563EB),
          priceLabel: '$askingPrice EUR',
          theme: theme,
        ),
        const SizedBox(height: 8),
        _BarRow(
          label: 'market_gap.real_price_label'.tr(),
          fraction: realFraction.toDouble(),
          color: const Color(0xFF16A34A),
          priceLabel: '$realTransactionPrice EUR/m2',
          theme: theme,
        ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.fraction,
    required this.color,
    required this.priceLabel,
    required this.theme,
  });

  final String label;
  final double fraction;
  final Color color;
  final String priceLabel;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth =
                  (constraints.maxWidth * fraction).clamp(4.0, constraints.maxWidth);
              return Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    height: 12,
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(
          priceLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
