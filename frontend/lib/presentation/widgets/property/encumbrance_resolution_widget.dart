import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------

const _kBlue = Color(0xFF2563EB);
const _kOrange = Color(0xFFF59E0B);
const _kRed = Color(0xFFEF4444);

const _kOrangeSoftBg = Color(0xFFFEF3C7);
const _kBlueLightBg = Color(0xFFEFF6FF);
const _kGreyBg = Color(0xFFF8FAFC);

// ---------------------------------------------------------------------------
// Encumbrance Resolution Widget
// ---------------------------------------------------------------------------

/// Displays a legal resolution roadmap for each detected registry charge.
///
/// [charges] is a list of maps with keys:
///   - "charge_type": "judicial" | "financiera" | "administrativa"
///   - "description": string
///   - "risk_level": "alto" | "estandar" | "informativo"
class EncumbranceResolutionWidget extends StatelessWidget {
  const EncumbranceResolutionWidget({
    super.key,
    required this.charges,
  });

  final List<Map<String, String>> charges;

  void _handleDownloadTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('nota_simple.download_guide_unavailable'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.shield_outlined, color: _kBlue, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'nota_simple.encumbrance_resolution_title'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _kBlue,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Resolution cards
        ...charges.map(
          (charge) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ResolutionCard(charge: charge),
          ),
        ),

        const SizedBox(height: 8),

        // Download button
        OutlinedButton.icon(
          onPressed: () => _handleDownloadTap(context),
          icon: const Icon(Icons.download_outlined, size: 18),
          label: Text('nota_simple.download_guide_button'.tr()),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kBlue,
            side: const BorderSide(color: _kBlue),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),

        const SizedBox(height: 12),

        // Mandatory disclaimer
        Text(
          'nota_simple.encumbrance_disclaimer'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Resolution card
// ---------------------------------------------------------------------------

class _ResolutionCard extends StatelessWidget {
  const _ResolutionCard({required this.charge});

  final Map<String, String> charge;

  String get _chargeType => charge['charge_type'] ?? 'administrativa';
  String get _description => charge['description'] ?? '';

  _ChargeVisual get _visual {
    switch (_chargeType) {
      case 'judicial':
        return const _ChargeVisual(
          background: _kOrangeSoftBg,
          borderColor: _kOrange,
          badgeKey: 'nota_simple.judicial_risk_badge',
          badgeColor: _kRed,
          buyerActionKey: 'nota_simple.judicial_buyer_action',
          sellerActionKey: 'nota_simple.judicial_seller_action',
          icon: Icons.gavel_outlined,
          iconColor: _kRed,
        );
      case 'financiera':
        return const _ChargeVisual(
          background: _kBlueLightBg,
          borderColor: _kBlue,
          badgeKey: 'nota_simple.financiera_risk_badge',
          badgeColor: _kOrange,
          buyerActionKey: 'nota_simple.financiera_buyer_action',
          sellerActionKey: 'nota_simple.financiera_seller_action',
          icon: Icons.account_balance_outlined,
          iconColor: _kBlue,
        );
      default:
        return const _ChargeVisual(
          background: _kGreyBg,
          borderColor: Color(0xFFCBD5E1),
          badgeKey: 'nota_simple.administrativa_risk_badge',
          badgeColor: _kBlue,
          buyerActionKey: 'nota_simple.administrativa_buyer_action',
          sellerActionKey: 'nota_simple.administrativa_seller_action',
          icon: Icons.business_outlined,
          iconColor: Color(0xFF64748B),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = _visual;

    return Container(
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: visual.borderColor.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Charge header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(visual.icon, color: visual.iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _RiskBadge(
                label: visual.badgeKey.tr(),
                color: visual.badgeColor,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Buyer action
          _ActionRow(
            role: 'Comprador',
            action: visual.buyerActionKey.tr(),
            roleColor: _kBlue,
          ),

          const SizedBox(height: 8),

          // Seller action
          _ActionRow(
            role: 'Vendedor',
            action: visual.sellerActionKey.tr(),
            roleColor: _kOrange,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Visual configuration value object
// ---------------------------------------------------------------------------

class _ChargeVisual {
  const _ChargeVisual({
    required this.background,
    required this.borderColor,
    required this.badgeKey,
    required this.badgeColor,
    required this.buyerActionKey,
    required this.sellerActionKey,
    required this.icon,
    required this.iconColor,
  });

  final Color background;
  final Color borderColor;
  final String badgeKey;
  final Color badgeColor;
  final String buyerActionKey;
  final String sellerActionKey;
  final IconData icon;
  final Color iconColor;
}

// ---------------------------------------------------------------------------
// Action row
// ---------------------------------------------------------------------------

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.role,
    required this.action,
    required this.roleColor,
  });

  final String role;
  final String action;
  final Color roleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            role,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: roleColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            action,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Risk badge
// ---------------------------------------------------------------------------

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
