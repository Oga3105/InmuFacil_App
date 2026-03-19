import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Mock data for UI demonstration (upload flow reserved for next version)
// ---------------------------------------------------------------------------

class _NotaSimpleResult {
  const _NotaSimpleResult({
    required this.titular,
    required this.dniPartial,
    required this.surfaceM2,
    required this.description,
    required this.charges,
    required this.surfaceDiscrepancyPct,
    required this.surfaceAlert,
    required this.documentValid,
    this.invalidityReason,
    required this.disclaimer,
  });

  final String titular;
  final String dniPartial;
  final double? surfaceM2;
  final String description;
  final List<_ChargeItem> charges;
  final double? surfaceDiscrepancyPct;
  final bool surfaceAlert;
  final bool documentValid;
  final String? invalidityReason;
  final String disclaimer;
}

class _ChargeItem {
  const _ChargeItem({
    required this.chargeType,
    required this.description,
    required this.riskLevel,
  });

  final String chargeType;
  final String description;
  final String riskLevel;
}

const _mockResult = _NotaSimpleResult(
  titular: 'Maria G. R.',
  dniPartial: '4521',
  surfaceM2: 87.5,
  description: 'Piso en planta tercera, Calle Mayor 14, 3B. Finca registral 12345.',
  charges: [
    _ChargeItem(
      chargeType: 'financiera',
      description: 'Hipoteca a favor de Banco Ejemplo S.A. por importe de 180.000 EUR.',
      riskLevel: 'estandar',
    ),
    _ChargeItem(
      chargeType: 'judicial',
      description: 'Anotacion preventiva de embargo por procedimiento 234/2023.',
      riskLevel: 'alto',
    ),
  ],
  surfaceDiscrepancyPct: 2.9,
  surfaceAlert: false,
  documentValid: true,
  invalidityReason: null,
  disclaimer:
      'Este analisis es una asistencia basada en IA. Debe ser validado por un profesional juridico antes de cualquier firma.',
);

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------

const _kBlue = Color(0xFF2563EB);
const _kOrange = Color(0xFFF59E0B);
const _kRed = Color(0xFFEF4444);
const _kGreen = Color(0xFF16A34A);

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class NotaSimpleAnalyzerWidget extends StatefulWidget {
  const NotaSimpleAnalyzerWidget({
    super.key,
    required this.propertyId,
    required this.surfaceM2,
  });

  final String propertyId;
  final double surfaceM2;

  @override
  State<NotaSimpleAnalyzerWidget> createState() =>
      _NotaSimpleAnalyzerWidgetState();
}

class _NotaSimpleAnalyzerWidgetState extends State<NotaSimpleAnalyzerWidget> {
  _NotaSimpleResult? _result;

  void _handleUploadTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('nota_simple.upload_unavailable'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Show mock result to allow UI review
    setState(() {
      _result = _mockResult;
    });
  }

  void _showChargesDialog(List<_ChargeItem> charges) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('nota_simple.charges_dialog_title'.tr()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: charges.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final charge = charges[index];
              return _ChargeDetailTile(charge: charge);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('nota_simple.charges_dialog_close'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Upload button
        OutlinedButton.icon(
          onPressed: _handleUploadTap,
          icon: const Icon(Icons.upload_file_outlined, size: 18),
          label: Text('nota_simple.upload_button'.tr()),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kBlue,
            side: const BorderSide(color: _kBlue),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),

        // Result card
        if (_result != null) ...[
          const SizedBox(height: 16),
          _buildResultCard(theme, _result!),
        ],
      ],
    );
  }

  Widget _buildResultCard(ThemeData theme, _NotaSimpleResult result) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                const Icon(Icons.article_outlined, color: _kBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'nota_simple.summary_title'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _kBlue,
                  ),
                ),
              ],
            ),

            // Invalid document banner
            if (!result.documentValid) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _kRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kRed.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: _kRed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.invalidityReason ??
                            'nota_simple.invalid_document_title'.tr(),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: _kRed),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (result.documentValid) ...[
              const SizedBox(height: 12),

              // Titular
              _InfoRow(
                label: 'nota_simple.titular_label'.tr(),
                value: result.titular,
                valueColor: _kBlue,
              ),

              const SizedBox(height: 8),

              // Surface comparison
              _InfoRow(
                label: 'nota_simple.surface_registered'.tr(),
                value: result.surfaceM2 != null
                    ? '${result.surfaceM2!.toStringAsFixed(1)} m2'
                    : '—',
              ),
              const SizedBox(height: 4),
              _InfoRow(
                label: 'nota_simple.surface_announced'.tr(),
                value: '${widget.surfaceM2.toStringAsFixed(1)} m2',
              ),

              // Surface alert
              if (result.surfaceAlert &&
                  result.surfaceDiscrepancyPct != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _kOrange.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_outlined,
                          color: _kOrange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'nota_simple.surface_alert'.tr(
                            namedArgs: {
                              'pct': result.surfaceDiscrepancyPct!
                                  .toStringAsFixed(1),
                            },
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _kOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Charges section
              Row(
                children: [
                  const Icon(Icons.traffic_outlined,
                      size: 18, color: _kBlue),
                  const SizedBox(width: 6),
                  Text(
                    'nota_simple.charges_title'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (result.charges.isEmpty)
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: _kGreen, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'nota_simple.no_charges'.tr(),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: _kGreen),
                    ),
                  ],
                )
              else
                ...result.charges.map(
                  (charge) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _ChargeSummaryRow(charge: charge),
                  ),
                ),

              // Detail button
              if (result.charges.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        _showChargesDialog(result.charges),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kBlue,
                      side: const BorderSide(color: _kBlue),
                    ),
                    child: Text(
                        'nota_simple.charges_detail_button'.tr()),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Disclaimer
            Text(
              result.disclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
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
// Supporting widgets
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChargeSummaryRow extends StatelessWidget {
  const _ChargeSummaryRow({required this.charge});

  final _ChargeItem charge;

  Color get _indicatorColor {
    switch (charge.chargeType) {
      case 'judicial':
        return _kRed;
      case 'financiera':
        return _kOrange;
      default:
        return _kBlue;
    }
  }

  String get _riskLabel {
    switch (charge.riskLevel) {
      case 'alto':
        return 'nota_simple.charge_risk_alto'.tr();
      case 'estandar':
        return 'nota_simple.charge_risk_estandar'.tr();
      default:
        return 'nota_simple.charge_risk_informativo'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 3, right: 8),
          decoration: BoxDecoration(
            color: _indicatorColor,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                charge.description,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              _RiskBadge(
                label: _riskLabel,
                color: _indicatorColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChargeDetailTile extends StatelessWidget {
  const _ChargeDetailTile({required this.charge});

  final _ChargeItem charge;

  Color get _indicatorColor {
    switch (charge.chargeType) {
      case 'judicial':
        return _kRed;
      case 'financiera':
        return _kOrange;
      default:
        return _kBlue;
    }
  }

  String get _riskLabel {
    switch (charge.riskLevel) {
      case 'alto':
        return 'nota_simple.charge_risk_alto'.tr();
      case 'estandar':
        return 'nota_simple.charge_risk_estandar'.tr();
      default:
        return 'nota_simple.charge_risk_informativo'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 3, right: 10),
            decoration: BoxDecoration(
              color: _indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  charge.description,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                _RiskBadge(
                  label: _riskLabel,
                  color: _indicatorColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
