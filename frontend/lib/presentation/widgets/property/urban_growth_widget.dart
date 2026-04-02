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

class UrbanGrowthResult {
  const UrbanGrowthResult({
    required this.baseGrowthRate,
    required this.neighborhoodBonus,
    this.projectedValue5yrPct,
    required this.growthSignals,
    required this.urbanMilestones,
    required this.zoneType,
    required this.lowData,
    this.message,
    required this.disclaimer,
  });

  final double baseGrowthRate;
  final double neighborhoodBonus;
  final double? projectedValue5yrPct;
  final List<String> growthSignals;
  final List<String> urbanMilestones;
  final String zoneType;
  final bool lowData;
  final String? message;
  final String disclaimer;

  factory UrbanGrowthResult.fromJson(Map<String, dynamic> j) =>
      UrbanGrowthResult(
        baseGrowthRate: (j['base_growth_rate'] as num?)?.toDouble() ?? 0.0,
        neighborhoodBonus:
            (j['neighborhood_bonus'] as num?)?.toDouble() ?? 0.0,
        projectedValue5yrPct:
            (j['projected_value_5yr_pct'] as num?)?.toDouble(),
        growthSignals: List<String>.from(j['growth_signals'] as List? ?? []),
        urbanMilestones:
            List<String>.from(j['urban_milestones'] as List? ?? []),
        zoneType: j['zone_type'] as String? ?? 'unknown',
        lowData: j['low_data'] as bool? ?? true,
        message: j['message'] as String?,
        disclaimer: j['disclaimer'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// Provider args
// ---------------------------------------------------------------------------

class _UrbanGrowthArgs {
  const _UrbanGrowthArgs({
    required this.postalCode,
    required this.address,
  });

  final String postalCode;
  final String address;

  @override
  bool operator ==(Object other) =>
      other is _UrbanGrowthArgs &&
      other.postalCode == postalCode &&
      other.address == address;

  @override
  int get hashCode => Object.hash(postalCode, address);
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

const _storage = FlutterSecureStorage();

final _urbanGrowthProvider =
    FutureProvider.autoDispose.family<UrbanGrowthResult, _UrbanGrowthArgs>(
  (ref, args) async {
    final token = await _storage.read(key: 'auth_token');
    final dio = buildAuthDio();
    try {
      final resp = await dio.post(
        '${EnvConfig.apiBaseUrl}/ai/urban-growth',
        data: {
          'postal_code': args.postalCode,
          'address': args.address,
        },
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      return UrbanGrowthResult.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode != null) {
        return const UrbanGrowthResult(
          baseGrowthRate: 0.0,
          neighborhoodBonus: 0.0,
          projectedValue5yrPct: null,
          growthSignals: [],
          urbanMilestones: [],
          zoneType: 'unknown',
          lowData: true,
          message: null,
          disclaimer: '',
        );
      }
      rethrow;
    }
  },
);

// ---------------------------------------------------------------------------
// Public Widget
// ---------------------------------------------------------------------------

class UrbanGrowthWidget extends ConsumerWidget {
  const UrbanGrowthWidget({
    super.key,
    required this.postalCode,
    required this.address,
  });

  final String postalCode;
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = _UrbanGrowthArgs(postalCode: postalCode, address: address);
    final asyncValue = ref.watch(_urbanGrowthProvider(args));

    return asyncValue.when(
      loading: () => const _UrbanGrowthLoading(),
      error: (_, __) => const _UrbanGrowthError(),
      data: (result) =>
          result.lowData ? _UrbanGrowthLowData(result: result) : _UrbanGrowthCard(result: result),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading
// ---------------------------------------------------------------------------

class _UrbanGrowthLoading extends StatelessWidget {
  const _UrbanGrowthLoading();

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
// Error
// ---------------------------------------------------------------------------

class _UrbanGrowthError extends StatelessWidget {
  const _UrbanGrowthError();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade500, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'urban_growth.error'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
// Low data state
// ---------------------------------------------------------------------------

class _UrbanGrowthLowData extends StatelessWidget {
  const _UrbanGrowthLowData({required this.result});

  final UrbanGrowthResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final msg = result.message ?? 'urban_growth.low_data_default'.tr();
    return Card(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade500, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
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
// Main data card
// ---------------------------------------------------------------------------

class _UrbanGrowthCard extends StatelessWidget {
  const _UrbanGrowthCard({required this.result});

  final UrbanGrowthResult result;

  Color get _projectedColor {
    if (result.zoneType == 'mature') return const Color(0xFF135BEC);
    return const Color(0xFF16A34A);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = result.projectedValue5yrPct;
    final pctText = pct != null
        ? '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%'
        : 'urban_growth.no_projection'.tr();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: const Color(0xFF135BEC),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'urban_growth.title'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _ZoneTypeBadge(zoneType: result.zoneType),
              ],
            ),

            const SizedBox(height: 14),

            // Projected percentage
            Text(
              'urban_growth.projected_label'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pctText,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _projectedColor,
              ),
            ),

            if (result.message != null) ...[
              const SizedBox(height: 6),
              Text(
                result.message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Urban milestones
            if (result.urbanMilestones.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'urban_growth.milestones_title'.tr(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ...result.urbanMilestones.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\u2022',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF135BEC),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          m,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Growth signals chips
            if (result.growthSignals.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'urban_growth.signals_title'.tr(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: result.growthSignals
                    .map((s) => _SignalChip(label: s))
                    .toList(),
              ),
            ],

            // Disclaimer
            const SizedBox(height: 14),
            Text(
              result.disclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade400,
                fontStyle: FontStyle.italic,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Zone type badge
// ---------------------------------------------------------------------------

class _ZoneTypeBadge extends StatelessWidget {
  const _ZoneTypeBadge({required this.zoneType});

  final String zoneType;

  Color get _color {
    switch (zoneType) {
      case 'mature':
        return const Color(0xFF135BEC);
      case 'emerging':
        return const Color(0xFF16A34A);
      case 'declining':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey.shade500;
    }
  }

  String get _label {
    switch (zoneType) {
      case 'mature':
        return 'urban_growth.zone_mature'.tr();
      case 'emerging':
        return 'urban_growth.zone_emerging'.tr();
      case 'declining':
        return 'urban_growth.zone_declining'.tr();
      default:
        return 'urban_growth.zone_unknown'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.35)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Growth signal chip
// ---------------------------------------------------------------------------

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
              fontSize: 11,
            ),
      ),
    );
  }
}
