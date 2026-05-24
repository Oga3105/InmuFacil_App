import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/utils/ccaa_utils.dart';

class DocumentStatusSection extends StatelessWidget {
  const DocumentStatusSection({
    super.key,
    required this.postalCode,
  });

  final String postalCode;

  @override
  Widget build(BuildContext context) {
    final ccaa = ccaaFromPostalCode(postalCode);
    final requiresCedula = ccaaRequiereCedula(ccaa);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.verified_outlined,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'doc_verification.section_title'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DocIndicator(
            label: 'doc_verification.cee_title'.tr(),
            icon: Icons.energy_savings_leaf_outlined,
            isPresent: false,
          ),
          const SizedBox(height: 8),
          _DocIndicator(
            label: 'doc_verification.nota_simple_title'.tr(),
            icon: Icons.description_outlined,
            isPresent: false,
          ),
          if (requiresCedula) ...[
            const SizedBox(height: 8),
            _DocIndicator(
              label: 'doc_verification.cedula_title'.tr(),
              icon: Icons.apartment_outlined,
              isPresent: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _DocIndicator extends StatelessWidget {
  const _DocIndicator({
    required this.label,
    required this.icon,
    required this.isPresent,
  });

  final String label;
  final IconData icon;
  final bool isPresent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor =
        isPresent ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    final statusBg = isPresent
        ? (isDark ? const Color(0xFF0D2010) : const Color(0xFFF0FDF4))
        : (isDark ? const Color(0xFF1F0808) : const Color(0xFFFEF2F2));
    final statusBorder =
        isPresent ? const Color(0xFF16A34A) : const Color(0xFFEF4444);

    return Container(
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusBorder.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          Icon(
            isPresent ? Icons.check_circle : Icons.radio_button_unchecked,
            color: statusColor,
            size: 18,
          ),
        ],
      ),
    );
  }
}
