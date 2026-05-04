import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/ai_metrics_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

const _blue = Color(0xFF135BEC);
const _amber = Color(0xFFF59E0B);
const _green = Color(0xFF16A34A);
const _red = Color(0xFFDC2626);

const _kPanicKey = 'ai_panic_mode_active';
const _kPanicModelKey = 'ai_panic_forced_model';
const int _maxDailyRequests = 200;

class AdminAiAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAiAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAiAnalyticsScreen> createState() =>
      _AdminAiAnalyticsScreenState();
}

class _AdminAiAnalyticsScreenState
    extends ConsumerState<AdminAiAnalyticsScreen> {
  List<AiCallLog> _logs = [];
  Map<String, int> _byFeature = {};
  double _resilienceRatio = 1.0;
  int _dailyCount = 0;
  double _dailyRatio = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final service = AiMetricsService.instance;
    final logs = await service.getLogsForLastDays(30);
    final today = await service.getLogsForDate(DateTime.now());

    final byFeature = <String, int>{};
    for (final log in logs) {
      byFeature[log.feature] = (byFeature[log.feature] ?? 0) + 1;
    }

    final successful = logs.where((l) => l.success).length;
    final resilience = logs.isEmpty ? 1.0 : successful / logs.length;
    final dailyCount = today.length;
    final dailyRatio = (dailyCount / _maxDailyRequests).clamp(0.0, 1.0);

    if (!mounted) return;
    setState(() {
      _logs = logs;
      _byFeature = byFeature;
      _resilienceRatio = resilience;
      _dailyCount = dailyCount;
      _dailyRatio = dailyRatio;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.userType == 'admin';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(onPressed: () => context.pop()),
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
                Builder(
                builder: (context) {
                  final cs = Theme.of(context).colorScheme;
                  final dark = Theme.of(context).brightness == Brightness.dark;
                  return Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      children: [
                        TextSpan(text: 'Inmu', style: TextStyle(color: cs.primary)),
                        TextSpan(text: 'Fácil', style: TextStyle(color: dark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))),
                      ],
                    ),
                  );
                },
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadMetrics();
            },
            tooltip: 'common.refresh'.tr(),
          ),

          if (MediaQuery.sizeOf(context).width >= 650)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, size: 16, color: Theme.of(context).colorScheme.onPrimary),
                    const SizedBox(width: 5),
                    Text('transaction.home_btn'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
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
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
      ),
      body: !isAdmin
          ? _buildAccessRestricted()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadMetrics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildResilienceCard(),
                      const SizedBox(height: 12),
                      _buildByFeatureCard(),
                      const SizedBox(height: 12),
                      _buildRealtimeLogCard(),
                      const SizedBox(height: 12),
                      const _PanicControlCard(),
                      const SizedBox(height: 12),
                      _buildDailyBudgetCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAccessRestricted() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'common.restricted_access'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'common.admin_only_section'.tr(),
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildResilienceCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (_resilienceRatio * 100).toStringAsFixed(1);
    final Color gaugeColor;
    if (_resilienceRatio >= 0.9) {
      gaugeColor = _green;
    } else if (_resilienceRatio >= 0.7) {
      gaugeColor = _amber;
    } else {
      gaugeColor = _red;
    }

    return _card(
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _resilienceRatio,
                  strokeWidth: 7,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: gaugeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.ai_resilience_label'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 4),
                Text(
                  '${'admin.ai_resilience_desc'.tr()} '
                  '${_logs.isEmpty ? "common.no_data".tr() : "admin.ai_based_on_calls".tr(namedArgs: {"count": _logs.length.toString()})}',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildByFeatureCard() {
    final entries = _byFeature.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.ai_calls_by_feature'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text('common.no_data'.tr(),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13))

          else
            ...entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.key,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${e.value}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRealtimeLogCard() {
    final recent = _logs.take(10).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.ai_recent_log'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Text('common.no_data'.tr(),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13))

          else
            ...recent.map((log) {
              final h = log.timestamp.hour.toString().padLeft(2, '0');
              final m = log.timestamp.minute.toString().padLeft(2, '0');
              final statusColor = log.success ? _green : _red;
              final statusLabel = log.success ? 'OK' : 'FAIL';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 7),
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$h:${m}h - [${log.feature}] - ${log.latencyMs}ms - $statusLabel',
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDailyBudgetCard() {
    final usedPercent = (_dailyRatio * 100).toStringAsFixed(1);
    final Color barColor;
    if (_dailyRatio < 0.6) {
      barColor = _green;
    } else if (_dailyRatio < 0.85) {
      barColor = _amber;
    } else {
      barColor = _red;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.ai_daily_budget'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'admin.ai_calls_ratio'.tr(namedArgs: {
              'count': _dailyCount.toString(),
              'max': _maxDailyRequests.toString(),
              'percent': usedPercent
            }),
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _dailyRatio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PanicControlCard extends StatefulWidget {
  const _PanicControlCard();

  @override
  State<_PanicControlCard> createState() => _PanicControlCardState();
}

class _PanicControlCardState extends State<_PanicControlCard> {
  bool _panicActive = false;
  String _selectedModel = 'flash';
  bool _isLoading = false;

  static const _models = ['flash', 'flash-lite'];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _panicActive = prefs.getBool(_kPanicKey) ?? false;
        _selectedModel = prefs.getString(_kPanicModelKey) ?? 'flash';
      });
    }
  }

  Future<void> _togglePanic(bool value) async {
    if (value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('admin.ai_panic_confirm_title'.tr()),

          content: Text(
            'admin.ai_panic_confirm_desc'.tr(namedArgs: {'model': _selectedModel.toUpperCase()}),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('common.cancel'.tr()),
            ),

            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _amber),
              onPressed: () => Navigator.pop(context, true),
              child: Text('common.activate'.tr()),
            ),

          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPanicKey, value);
    if (value) {
      await prefs.setString(_kPanicModelKey, _selectedModel);
    } else {
      await prefs.remove(_kPanicModelKey);
    }
    setState(() {
      _panicActive = value;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
        _panicActive ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF);
    final Color titleColor = _panicActive ? _red : _blue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _panicActive ? _amber : const Color(0xFFBFDBFE),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.ai_infra_control'.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'admin.ai_forced_model'.tr(),
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedModel,
                underline: const SizedBox.shrink(),
                isDense: true,
                items: _models
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.toUpperCase(),
                            style: const TextStyle(fontSize: 14)),
                      ),
                    )
                    .toList(),
                onChanged: _panicActive
                    ? null
                    : (v) {
                        if (v != null) setState(() => _selectedModel = v);
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'admin.ai_panic_title'.tr(),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A)),
              ),
              _isLoading
                  ? const SizedBox(
                      width: 36,
                      height: 20,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Switch(
                      value: _panicActive,
                      onChanged: _togglePanic,
                      activeColor: _amber,
                    ),
            ],
          ),
          if (_panicActive) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _amber),
              ),
              child: Text(
                'admin.ai_panic_active'.tr(namedArgs: {'model': _selectedModel.toUpperCase()}),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                  letterSpacing: 0.3,
                ),
              ),

            ),
          ],
        ],
      ),
    );
  }
}
