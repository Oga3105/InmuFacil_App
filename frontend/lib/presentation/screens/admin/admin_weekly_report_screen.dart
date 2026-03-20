import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/ai_metrics_service.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

// ── Colour palette ────────────────────────────────────────────────────────────

const _kBlue = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kOrange = Color(0xFFF59E0B);
const _kBg = Color(0xFFF8FAFC);

// ── Data model ────────────────────────────────────────────────────────────────

class _WeeklyStats {
  const _WeeklyStats({
    required this.totalCalls,
    required this.successfulCalls,
    required this.failedCalls,
    required this.totalLatencyMs,
  });

  final int totalCalls;
  final int successfulCalls;
  final int failedCalls;
  final int totalLatencyMs;

  /// Estimated cost saved assuming 0.002 EUR per AI call vs manual process.
  int get estimatedCostSaved => (totalCalls * 0.002).round();

  /// Success rate as a percentage (0 – 100). Returns 0 if no calls.
  double get successRate =>
      totalCalls == 0 ? 0.0 : (successfulCalls / totalCalls) * 100.0;

  /// Average latency in milliseconds. Returns 0 if no calls.
  int get averageLatencyMs =>
      totalCalls == 0 ? 0 : (totalLatencyMs / totalCalls).round();

  static _WeeklyStats empty() => const _WeeklyStats(
        totalCalls: 0,
        successfulCalls: 0,
        failedCalls: 0,
        totalLatencyMs: 0,
      );
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

final _weeklyStatsProvider = FutureProvider.autoDispose<_WeeklyStats>((ref) async {
  final logs = await AiMetricsService.instance.getLogsForLastDays(7);

  if (logs.isEmpty) return _WeeklyStats.empty();

  int successful = 0;
  int failed = 0;
  int totalLatency = 0;

  for (final log in logs) {
    if (log.success) {
      successful++;
    } else {
      failed++;
    }
    totalLatency += log.latencyMs;
  }

  return _WeeklyStats(
    totalCalls: logs.length,
    successfulCalls: successful,
    failedCalls: failed,
    totalLatencyMs: totalLatency,
  );
});

// ── Screen ────────────────────────────────────────────────────────────────────

/// Admin screen that shows a weekly AI usage summary and estimated savings.
class AdminWeeklyReportScreen extends ConsumerWidget {
  const AdminWeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_weeklyStatsProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(
            onPressed: () => context.pop(),
          ),
        ),
        title: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_inmufacil.png', height: 28),
                const SizedBox(width: 8),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF2563EB))),
                      TextSpan(text: 'Fácil', style: TextStyle(color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text('Inicio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const UserAvatarMenu(),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: statsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Error al cargar el informe: $err',
              style: const TextStyle(color: Color(0xFFEF4444)),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (stats) => _WeeklyReportBody(stats: stats),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _WeeklyReportBody extends StatelessWidget {
  const _WeeklyReportBody({required this.stats});

  final _WeeklyStats stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(title: 'Resumen de la semana'),
        const SizedBox(height: 16),
        _StatsGrid(stats: stats),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Distribucion de llamadas'),
        const SizedBox(height: 16),
        _CallDistributionCard(stats: stats),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Impacto economico estimado'),
        const SizedBox(height: 16),
        _EconomicImpactCard(stats: stats),
      ],
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    );
  }
}

// ── Stats grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final _WeeklyStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 2 : 1;
        final itemHeight = 110.0;
        final itemWidth = constraints.maxWidth / crossAxisCount;
        final childAspectRatio = itemWidth / itemHeight;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              label: 'Llamadas IA esta semana',
              value: stats.totalCalls.toString(),
              icon: Icons.bolt_rounded,
              color: _kBlue,
            ),
            _StatCard(
              label: 'Tasa de exito',
              value: '${stats.successRate.toStringAsFixed(1)} %',
              icon: Icons.check_circle_outline_rounded,
              color: _kGreen,
            ),
            _StatCard(
              label: 'Ahorro estimado',
              value: '${stats.estimatedCostSaved} \u20AC',
              icon: Icons.savings_outlined,
              color: _kGreen,
            ),
            _StatCard(
              label: 'Latencia media',
              value: '${stats.averageLatencyMs} ms',
              icon: Icons.timer_outlined,
              color: _kOrange,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Call distribution card ────────────────────────────────────────────────────

class _CallDistributionCard extends StatelessWidget {
  const _CallDistributionCard({required this.stats});

  final _WeeklyStats stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.totalCalls;
    final successPct = total == 0 ? 0.0 : stats.successfulCalls / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DistributionRow(
            label: 'Llamadas exitosas',
            count: stats.successfulCalls,
            total: total,
            color: _kGreen,
          ),
          const SizedBox(height: 12),
          _DistributionRow(
            label: 'Llamadas fallidas',
            count: stats.failedCalls,
            total: total,
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: successPct,
              minHeight: 8,
              backgroundColor: const Color(0xFFEF4444).withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(_kGreen),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? 'Sin datos para esta semana'
                : '${stats.successfulCalls} de $total llamadas completadas con exito',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (count / total) * 100.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ],
        ),
        Text(
          '$count  (${pct.toStringAsFixed(0)} %)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Economic impact card ──────────────────────────────────────────────────────

class _EconomicImpactCard extends StatelessWidget {
  const _EconomicImpactCard({required this.stats});

  final _WeeklyStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.attach_money_rounded,
                    color: _kGreen, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.estimatedCostSaved} \u20AC ahorrados esta semana',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kGreen,
                      ),
                    ),
                    Text(
                      'Frente al proceso manual equivalente',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kGreen.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: _kGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calculo basado en 0,002 EUR por llamada IA vs coste estimado de proceso manual.',
                    style: TextStyle(
                        fontSize: 12,
                        color: _kGreen.withOpacity(0.85),
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
