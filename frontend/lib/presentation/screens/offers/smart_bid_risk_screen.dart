// Smart Bidding & Risk Gauge Screen (V36).
//
// Displays a visual risk thermometer comparing the buyer's offer amount
// against the property's asking price. The risk level is computed from
// the percentage difference between offer and asking price.
//
// Risk thresholds:
//   diff >= 0        : LOW    (green)   "Oferta al precio o superior"
//   -3 <= diff < 0   : MEDIUM (orange)  "Oferta ligeramente bajo precio"
//   -10 <= diff < -3 : MED-HI (orange-red) "Oferta negociable"
//   diff < -10       : HIGH   (red)     "Oferta muy por debajo del precio"
//
// A fiscal truth clause is always shown at the bottom:
//   "El riesgo es estadistico, no una prediccion del comportamiento humano.
//    Sin datos historicos suficientes."
//
// No real historical data is consumed — the disclaimer communicates this.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/currency_input_formatter.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

// ── Risk level enum ───────────────────────────────────────────────────────────

enum _RiskLevel { low, medium, mediumHigh, high }

_RiskLevel _computeRisk(double diffPct) {
  if (diffPct >= 0) return _RiskLevel.low;
  if (diffPct >= -3) return _RiskLevel.medium;
  if (diffPct >= -10) return _RiskLevel.mediumHigh;
  return _RiskLevel.high;
}

Color _riskColor(_RiskLevel level) {
  switch (level) {
    case _RiskLevel.low:
      return const Color(0xFF16A34A);
    case _RiskLevel.medium:
      return const Color(0xFFF59E0B);
    case _RiskLevel.mediumHigh:
      return const Color(0xFFEA580C);
    case _RiskLevel.high:
      return const Color(0xFFEF4444);
  }
}

String _riskLabelKey(_RiskLevel level) {
  switch (level) {
    case _RiskLevel.low:
      return 'smart_bid_risk.label_low';
    case _RiskLevel.medium:
      return 'smart_bid_risk.label_medium';
    case _RiskLevel.mediumHigh:
      return 'smart_bid_risk.label_medium_high';
    case _RiskLevel.high:
      return 'smart_bid_risk.label_high';
  }
}

/// Fill fraction for the thermometer bar (0.0 = no risk, 1.0 = maximum risk).
double _riskFill(_RiskLevel level) {
  switch (level) {
    case _RiskLevel.low:
      return 0.12;
    case _RiskLevel.medium:
      return 0.40;
    case _RiskLevel.mediumHigh:
      return 0.65;
    case _RiskLevel.high:
      return 0.90;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SmartBidRiskScreen extends StatelessWidget {
  const SmartBidRiskScreen({
    super.key,
    required this.offerAmount,
    required this.askingPrice,
  });

  final int offerAmount;
  final int askingPrice;

  static const _surface = Color(0xFFF1F5F9);
  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);
  static const _textMuted = Color(0xFF94A3B8);

  double get _diffPct {
    if (askingPrice <= 0 || offerAmount <= 0) return 0;
    return (offerAmount - askingPrice) / askingPrice * 100;
  }

  @override
  Widget build(BuildContext context) {
    final diff = _diffPct;
    final level = _computeRisk(diff);
    final color = _riskColor(level);
    final fill = _riskFill(level);
    final diffAbs = diff.abs();
    final diffText = diff >= 0
        ? '+${diffAbs.toStringAsFixed(1)} %'
        : '-${diffAbs.toStringAsFixed(1)} %';

    return Scaffold(
      backgroundColor: _surface,
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
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF135BEC))),
                      TextSpan(text: 'Fácil', style: TextStyle(color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 650)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF135BEC),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF135BEC).withOpacity(0.25),
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
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Offer vs asking price hero
            _PriceComparisonHero(
              offerAmount: offerAmount,
              askingPrice: askingPrice,
              diffText: diffText,
              diffIsPositive: diff >= 0,
              color: color,
            ),
            const SizedBox(height: 20),

            // Risk gauge card
            _RiskGaugeCard(
              level: level,
              fill: fill,
              color: color,
              diffText: diffText,
              diffPct: diff,
            ),
            const SizedBox(height: 16),

            // Historical data notice
            _HistoricalDataNotice(),
            const SizedBox(height: 16),

            // Statistical disclaimer
            _StatisticalDisclaimer(),
            const SizedBox(height: 32),

            // Understood button
            FilledButton(
              onPressed: () => context.pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'smart_bid_risk.understood_button'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Price Comparison Hero ─────────────────────────────────────────────────────

class _PriceComparisonHero extends StatelessWidget {
  const _PriceComparisonHero({
    required this.offerAmount,
    required this.askingPrice,
    required this.diffText,
    required this.diffIsPositive,
    required this.color,
  });

  final int offerAmount;
  final int askingPrice;
  final String diffText;
  final bool diffIsPositive;
  final Color color;

  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);
  static const _textMuted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'smart_bid_risk.your_offer_label'.tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyInputFormatter.format(offerAmount)} €',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF135BEC),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  diffText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'smart_bid_risk.asking_price_label'.tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyInputFormatter.format(askingPrice)} €',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Risk Gauge Card ───────────────────────────────────────────────────────────

class _RiskGaugeCard extends StatelessWidget {
  const _RiskGaugeCard({
    required this.level,
    required this.fill,
    required this.color,
    required this.diffText,
    required this.diffPct,
  });

  final _RiskLevel level;
  final double fill;
  final Color color;
  final String diffText;
  final double diffPct;

  static const _extremeRed = Color(0xFFEF4444);

  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.show_chart_rounded,
                  size: 18, color: Color(0xFF135BEC)),
              const SizedBox(width: 8),
              Text(
                'smart_bid_risk.gauge_title'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Risk label and percentage badge
          if (diffPct < -30)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'smart_bid_risk.extreme_low_offer'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _extremeRed,
                  height: 1.4,
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _riskLabelKey(level).tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    diffText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),

          // Thermometer bar background
          Stack(
            children: [
              // Track
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: fill.clamp(0.0, 1.0),
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Scale labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'smart_bid_risk.scale_low'.tr(),
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF16A34A)),
              ),
              Text(
                'smart_bid_risk.scale_high'.tr(),
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFFEF4444)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Risk interpretation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.20)),
            ),
            child: Text(
              '${_riskLabelKey(level)}_detail'.tr(),
              style: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Historical Data Notice ────────────────────────────────────────────────────

class _HistoricalDataNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bar_chart_outlined,
              size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'smart_bid_risk.no_historical_data'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Statistical Disclaimer ────────────────────────────────────────────────────

class _StatisticalDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'smart_bid_risk.statistical_disclaimer'.tr(),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
