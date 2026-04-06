import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_factory.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class ComfortDimension {
  const ComfortDimension({
    required this.score,
    required this.label,
    required this.factors,
  });

  final int score;
  final String label;
  final List<String> factors;

  factory ComfortDimension.fromJson(Map<String, dynamic> j) =>
      ComfortDimension(
        score: (j['score'] as int?) ?? 0,
        label: j['label'] as String? ?? '',
        factors: List<String>.from(j['factors'] as List? ?? []),
      );
}

class ComfortIndexResult {
  const ComfortIndexResult({
    required this.overallScore,
    required this.grade,
    required this.noiseDimension,
    required this.lightDimension,
    required this.airDimension,
    required this.connectivityDimension,
    required this.thermalDimension,
    required this.lowData,
    required this.disclaimer,
  });

  final int overallScore;
  final String grade;
  final ComfortDimension noiseDimension;
  final ComfortDimension lightDimension;
  final ComfortDimension airDimension;
  final ComfortDimension connectivityDimension;
  final ComfortDimension thermalDimension;
  final bool lowData;
  final String disclaimer;

  factory ComfortIndexResult.fromJson(Map<String, dynamic> j) =>
      ComfortIndexResult(
        overallScore: (j['overall_score'] as int?) ?? 0,
        grade: j['grade'] as String? ?? 'D',
        noiseDimension: ComfortDimension.fromJson(
            j['noise_dimension'] as Map<String, dynamic>? ?? {}),
        lightDimension: ComfortDimension.fromJson(
            j['light_dimension'] as Map<String, dynamic>? ?? {}),
        airDimension: ComfortDimension.fromJson(
            j['air_dimension'] as Map<String, dynamic>? ?? {}),
        connectivityDimension: ComfortDimension.fromJson(
            j['connectivity_dimension'] as Map<String, dynamic>? ?? {}),
        thermalDimension: ComfortDimension.fromJson(
            j['thermal_dimension'] as Map<String, dynamic>? ?? {}),
        lowData: j['low_data'] as bool? ?? true,
        disclaimer: j['disclaimer'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

class _ComfortArgs {
  const _ComfortArgs({
    required this.postalCode,
    required this.address,
    this.floor,
    this.orientation,
    this.buildingYear,
  });

  final String postalCode;
  final String address;
  final String? floor;
  final String? orientation;
  final int? buildingYear;

  @override
  bool operator ==(Object other) =>
      other is _ComfortArgs &&
      other.postalCode == postalCode &&
      other.address == address &&
      other.floor == floor &&
      other.orientation == orientation &&
      other.buildingYear == buildingYear;

  @override
  int get hashCode => Object.hash(postalCode, address, floor, orientation, buildingYear);
}

final _comfortIndexProvider =
    FutureProvider.autoDispose.family<ComfortIndexResult, _ComfortArgs>(
  (ref, args) async {
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);

    final dio = buildAuthDio();
    final resp = await dio.post(
      '/ai/comfort-index',
      data: {
        'postal_code': args.postalCode,
        'address': args.address,
        if (args.floor != null) 'floor': int.tryParse(args.floor!),
        if (args.orientation != null) 'orientation': args.orientation,
        if (args.buildingYear != null) 'building_year': args.buildingYear,
      },
      cancelToken: cancelToken,
    );
    return ComfortIndexResult.fromJson(resp.data as Map<String, dynamic>);
  },
);

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

class ComfortRadarChart extends ConsumerWidget {
  const ComfortRadarChart({
    super.key,
    required this.postalCode,
    required this.address,
    this.floor,
    this.orientation,
    this.buildingYear,
  });

  final String postalCode;
  final String address;
  final String? floor;
  final String? orientation;
  final int? buildingYear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = _ComfortArgs(
      postalCode: postalCode,
      address: address,
      floor: floor,
      orientation: orientation,
      buildingYear: buildingYear,
    );
    final asyncValue = ref.watch(_comfortIndexProvider(args));

    return asyncValue.when(
      loading: () => const _ComfortLoading(),
      error: (_, __) => const _ComfortError(),
      data: (result) => _ComfortCard(result: result),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / Error / LowData states
// ---------------------------------------------------------------------------

class _ComfortLoading extends StatelessWidget {
  const _ComfortLoading();

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

class _ComfortError extends StatelessWidget {
  const _ComfortError();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade500, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'comfort.error'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComfortLowData extends StatelessWidget {
  const _ComfortLowData();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade500, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'comfort.low_data'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main card
// ---------------------------------------------------------------------------

class _ComfortCard extends StatelessWidget {
  const _ComfortCard({required this.result});

  final ComfortIndexResult result;

  Color get _gradeColor {
    switch (result.grade) {
      case 'A+':
      case 'A':
        return const Color(0xFF16A34A);
      case 'B':
        return const Color(0xFF135BEC);
      case 'C':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimensions = [
      (label: 'comfort.dim_noise'.tr(), dim: result.noiseDimension),
      (label: 'comfort.dim_light'.tr(), dim: result.lightDimension),
      (label: 'comfort.dim_air'.tr(), dim: result.airDimension),
      (label: 'comfort.dim_connectivity'.tr(), dim: result.connectivityDimension),
      (label: 'comfort.dim_thermal'.tr(), dim: result.thermalDimension),
    ];

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
                const Icon(Icons.self_improvement_rounded,
                    color: Color(0xFF135BEC), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'comfort.title'.tr(),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                // Grade badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gradeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _gradeColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    result.grade,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _gradeColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),
            Text(
              'comfort.overall_score'.tr(args: [result.overallScore.toString()]),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey.shade500),
            ),

            if (result.lowData) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'comfort.low_data_banner'.tr(),
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Radar pentagon
            SizedBox(
              height: 180,
              child: _RadarChart(dimensions: dimensions),
            ),

            const SizedBox(height: 16),

            // Dimension list
            ...dimensions.map((d) => _DimensionRow(
                  axisLabel: d.label,
                  dimension: d.dim,
                )),

            const SizedBox(height: 12),

            // Disclaimer
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
// Radar chart painter
// ---------------------------------------------------------------------------

class _RadarChart extends StatelessWidget {
  const _RadarChart({required this.dimensions});

  final List<({String label, ComfortDimension dim})> dimensions;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 180),
      painter: _RadarPainter(dimensions),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.dimensions);

  final List<({String label, ComfortDimension dim})> dimensions;

  static const _kRings = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.min(cx, cy) - 28;
    final n = dimensions.length;
    final angleStep = (2 * math.pi) / n;

    // Grid rings
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= _kRings; ring++) {
      final r = maxR * ring / _kRings;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = -math.pi / 2 + i * angleStep;
        final x = cx + r * math.cos(angle);
        final y = cy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axis lines
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + maxR * math.cos(angle), cy + maxR * math.sin(angle)),
        gridPaint,
      );
    }

    // Data polygon
    final dataPaint = Paint()
      ..color = const Color(0xFF135BEC).withOpacity(0.20)
      ..style = PaintingStyle.fill;
    final dataStrokePaint = Paint()
      ..color = const Color(0xFF135BEC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final r = maxR * dimensions[i].dim.score / 100;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, dataStrokePaint);

    // Labels
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final labelR = maxR + 18;
      final x = cx + labelR * math.cos(angle);
      final y = cy + labelR * math.sin(angle);

      textPainter.text = TextSpan(
        text: dimensions[i].label,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF475569),
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout(maxWidth: 64);
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.dimensions != dimensions;
}

// ---------------------------------------------------------------------------
// Dimension row
// ---------------------------------------------------------------------------

class _DimensionRow extends StatelessWidget {
  const _DimensionRow({required this.axisLabel, required this.dimension});

  final String axisLabel;
  final ComfortDimension dimension;

  Color get _barColor {
    if (dimension.score >= 75) return const Color(0xFF16A34A);
    if (dimension.score >= 50) return const Color(0xFF135BEC);
    if (dimension.score >= 30) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  axisLabel,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: dimension.score / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${dimension.score}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _barColor,
                ),
              ),
            ],
          ),
          if (dimension.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 100),
              child: Text(
                dimension.label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
