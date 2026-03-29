// Pre-Offer Fiscal Summary Screen (V35).
//
// Shown before the user confirms and submits a formal offer.
// Displays an itemised breakdown of estimated acquisition costs
// (ITP, notary, registry, agency) derived from the offer amount and
// the CCAA inferred from the property's postal code.
//
// For foral regimes (Pais Vasco, Navarra) and Canarias the ITP row
// is replaced by a fiscal truth clause directing the user to their
// own tax advisor, because these territories have distinct frameworks
// that cannot be estimated with a single flat rate.
//
// All amounts use CurrencyInputFormatter.format() — integers, Spanish
// thousands separator (dot convention).

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/currency_input_formatter.dart';
import '../../../core/utils/ccaa_utils.dart';
import '../../../core/utils/tax_calculator.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const Color _textPrimary = Color(0xFF1E293B);
const Color _textSecondary = Color(0xFF64748B);
const Color _textMuted = Color(0xFF94A3B8);
const Color _blue = Color(0xFF135BEC);
const Color _orange = Color(0xFFF59E0B);

class PreOfferTaxSummaryScreen extends StatelessWidget {
  const PreOfferTaxSummaryScreen({
    super.key,
    required this.offerAmount,
    required this.propertyId,
    required this.postalCode,
  });

  final int offerAmount;
  final String propertyId;
  final String postalCode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ccaa = ccaaFromPostalCode(postalCode);
    final result = calculateBuyingCosts(offerAmount, ccaa);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
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
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Inmu', style: TextStyle(color: colorScheme.primary)),
                      TextSpan(text: 'Fácil', style: TextStyle(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))),
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
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, size: 16, color: colorScheme.onPrimary),
                    const SizedBox(width: 5),
                    Text('Inicio', style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
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
            // Offer amount hero
            _OfferAmountHero(offerAmount: offerAmount),
            const SizedBox(height: 20),

            // Fiscal breakdown card
            _FiscalBreakdownCard(result: result),
            const SizedBox(height: 16),

            // Disclaimer
            _DisclaimerCard(),
            const SizedBox(height: 32),

            // Action buttons
            _ActionButtons(onBack: () => context.pop()),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Offer Amount Hero ─────────────────────────────────────────────────────────

class _OfferAmountHero extends StatelessWidget {
  const _OfferAmountHero({required this.offerAmount});

  final int offerAmount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            'pre_offer_tax.offer_amount_label'.tr(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${CurrencyInputFormatter.format(offerAmount)} €',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'pre_offer_tax.offer_subtitle'.tr(),
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Fiscal Breakdown Card ─────────────────────────────────────────────────────

class _FiscalBreakdownCard extends StatelessWidget {
  const _FiscalBreakdownCard({required this.result});

  final TaxResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calculate_outlined, size: 18, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'pre_offer_tax.header'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Text(
                    result.ccaaName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ITP row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: result.isForal
                ? _ForalClauseRow()
                : _CostRow(
                    label: 'pre_offer_tax.itp_label'.tr(
                      namedArgs: {
                        'rate':
                            '${((result.itpRate ?? 0) * 100).toStringAsFixed(0)} %',
                      },
                    ),
                    amount: result.itpAmount,
                    icon: Icons.account_balance_outlined,
                    iconColor: _blue,
                    dataSource: result.dataSource,
                  ),
          ),

          // Notary row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _CostRow(
              label: 'pre_offer_tax.notary_label'.tr(),
              sublabel: 'pre_offer_tax.notary_sublabel'.tr(),
              amount: result.notaryFee,
              icon: Icons.gavel_outlined,
              iconColor: const Color(0xFF7C3AED),
              dataSource: result.dataSource,
            ),
          ),

          // Registry row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _CostRow(
              label: 'pre_offer_tax.registry_label'.tr(),
              sublabel: 'pre_offer_tax.registry_sublabel'.tr(),
              amount: result.registryFee,
              icon: Icons.article_outlined,
              iconColor: const Color(0xFF0891B2),
              dataSource: result.dataSource,
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 16),

          // Agency row (separate, not in total)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: _CostRow(
              label: 'pre_offer_tax.agency_label'.tr(),
              sublabel: 'pre_offer_tax.agency_sublabel'.tr(),
              amount: result.agencyFee,
              icon: Icons.handshake_outlined,
              iconColor: _orange,
              isOptional: true,
              dataSource: result.dataSource,
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),

          // Total row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'pre_offer_tax.total_label'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'pre_offer_tax.total_sublabel'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${CurrencyInputFormatter.format(result.total)} €',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Notarial disclaimer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'pre_offer_tax.notarial_disclaimer'.tr(),
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cost Row ──────────────────────────────────────────────────────────────────

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    this.sublabel,
    this.isOptional = false,
    this.dataSource,
  });

  final String label;
  final String? sublabel;
  final int amount;
  final IconData icon;
  final Color iconColor;
  final bool isOptional;
  final String? dataSource;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (isOptional) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainer : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'pre_offer_tax.optional_badge'.tr(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textMuted,
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${CurrencyInputFormatter.format(amount)} €',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isOptional ? _textSecondary : _textPrimary,
              ),
            ),
            if (dataSource != null)
              Text(
                dataSource!,
                style: const TextStyle(
                  fontSize: 9,
                  color: _textMuted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Foral Clause Row ──────────────────────────────────────────────────────────

class _ForalClauseRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'pre_offer_tax.foral_clause'.tr(),
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

// ── Disclaimer Card ───────────────────────────────────────────────────────────

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'pre_offer_tax.disclaimer'.tr(),
              style: TextStyle(
                fontSize: 11,
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

// ── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onBack});

  final VoidCallback onBack;

  static const _blue = Color(0xFF135BEC);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Confirm and send offer: pop twice to go back to make_offer_screen
        // and let it submit, or directly navigate. Per spec: context.pop() twice.
        FilledButton(
          onPressed: () {
            context.pop();
            context.pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: _blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'pre_offer_tax.confirm_button'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onBack,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'pre_offer_tax.back_button'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}
