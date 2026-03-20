import 'package:flutter/material.dart';
import '../../../core/utils/ccaa_utils.dart';

class RegionalLegalDashboardWidget extends StatelessWidget {
  const RegionalLegalDashboardWidget({
    super.key,
    required this.postalCode,
    required this.hasCee,
    required this.hasNotaSimple,
    this.hasCedula,
    this.ceeGrade,
    this.notaSimpleDate,
    this.isOwner = false,
  });

  final String postalCode;
  final bool hasCee;
  final bool hasNotaSimple;
  final bool? hasCedula;
  final String? ceeGrade;
  final DateTime? notaSimpleDate;
  final bool isOwner;

  static const int _notaSimpleValidityDays = 90;

  bool get _isNotaSimpleExpired {
    if (notaSimpleDate == null) return false;
    final expiry = notaSimpleDate!.add(
      const Duration(days: _notaSimpleValidityDays),
    );
    return DateTime.now().isAfter(expiry);
  }

  double _computeCompletionRatio(ComunidadAutonoma ccaa) {
    final requiresCedula = ccaaRequiereCedula(ccaa);
    int total = requiresCedula ? 3 : 2;
    int completed = 0;

    if (hasCee) completed++;
    if (hasNotaSimple && !_isNotaSimpleExpired) completed++;
    if (requiresCedula && (hasCedula ?? false)) completed++;

    return total > 0 ? completed / total : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final ccaa = ccaaFromPostalCode(postalCode);
    final requiresCedula = ccaaRequiereCedula(ccaa);
    final completionRatio = _computeCompletionRatio(ccaa);
    final completionPercent = (completionRatio * 100).round();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ccaa),
            const SizedBox(height: 16),
            _buildProgressSection(context, completionRatio, completionPercent),
            const SizedBox(height: 16),
            _buildDocumentList(context, ccaa, requiresCedula),
            if (isOwner && completionRatio < 1.0) ...[
              const SizedBox(height: 16),
              _buildOwnerWarning(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ComunidadAutonoma ccaa) {
    final ccaaName = ccaaDisplayName[ccaa] ?? '';
    return Row(
      children: [
        const Icon(Icons.gavel_rounded, size: 20, color: Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Documentacion legal',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
              ),
              if (ccaa != ComunidadAutonoma.desconocida)
                Text(
                  ccaaName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    double completionRatio,
    int completionPercent,
  ) {
    final Color progressColor;
    if (completionRatio >= 1.0) {
      progressColor = const Color(0xFF16A34A);
    } else if (completionRatio >= 0.5) {
      progressColor = const Color(0xFFF59E0B);
    } else {
      progressColor = const Color(0xFFEF4444);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completitud de documentacion',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              '$completionPercent%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completionRatio,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentList(
    BuildContext context,
    ComunidadAutonoma ccaa,
    bool requiresCedula,
  ) {
    return Column(
      children: [
        _buildDocumentRow(
          context,
          label: 'Certificado de Eficiencia Energetica (CEE)',
          sublabel: ceeGrade != null ? 'Calificacion: $ceeGrade' : null,
          status: hasCee ? _DocStatus.completed : _DocStatus.pending,
        ),
        const SizedBox(height: 8),
        _buildDocumentRow(
          context,
          label: 'Nota Simple Registral',
          sublabel: _isNotaSimpleExpired ? 'Documento caducado (>90 dias)' : null,
          status: hasNotaSimple
              ? (_isNotaSimpleExpired ? _DocStatus.expired : _DocStatus.completed)
              : _DocStatus.pending,
        ),
        if (requiresCedula) ...[
          const SizedBox(height: 8),
          _buildDocumentRow(
            context,
            label: 'Cedula de Habitabilidad / Licencia 2a Ocupacion',
            status: (hasCedula ?? false)
                ? _DocStatus.completed
                : _DocStatus.pending,
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentRow(
    BuildContext context, {
    required String label,
    String? sublabel,
    required _DocStatus status,
  }) {
    final Color iconColor;
    final IconData icon;

    switch (status) {
      case _DocStatus.completed:
        iconColor = const Color(0xFF16A34A);
        icon = Icons.check_circle_rounded;
      case _DocStatus.pending:
        iconColor = const Color(0xFFF59E0B);
        icon = Icons.radio_button_unchecked_rounded;
      case _DocStatus.expired:
        iconColor = const Color(0xFFEF4444);
        icon = Icons.error_rounded;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
              ),
              if (sublabel != null)
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: status == _DocStatus.expired
                        ? const Color(0xFFEF4444)
                        : Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerWarning(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tu anuncio es visible, pero los compradores veran que la '
              'documentacion aun no ha sido verificada por InmuFácil. '
              'Completalo para generar mas confianza.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF92400E),
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DocStatus { completed, pending, expired }
