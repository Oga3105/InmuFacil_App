import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/ccaa_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/property_form_provider.dart';

class PropertyStep3DocVerification extends ConsumerWidget {
  const PropertyStep3DocVerification({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postalCode = ref.watch(
      propertyFormProvider.select((s) => s.postalCodeText),
    );
    final ccaa = ccaaFromPostalCode(postalCode);
    final requiresCedula = ccaaRequiereCedula(ccaa);
    final dniStatus = ref.watch(
      authProvider.select((s) => s.user?.dniStatus),
    );
    final isIdentityVerified = dniStatus == 'validado';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            icon: Icons.verified_outlined,
            title: 'doc_verification.mandatory_docs_title'.tr(),
            child: Column(
              children: [
                // CEE — coming soon
                _ComingSoonDocRow(
                  icon: Icons.energy_savings_leaf_outlined,
                  title: 'doc_verification.cee_title'.tr(),
                  subtitle: 'doc_verification.cee_subtitle'.tr(),
                ),
                const SizedBox(height: 12),
                // Nota Simple — coming soon
                _ComingSoonDocRow(
                  icon: Icons.description_outlined,
                  title: 'doc_verification.nota_simple_title'.tr(),
                  subtitle: 'doc_verification.nota_simple_subtitle'.tr(),
                  warningText: 'doc_verification.nota_simple_warning'.tr(),
                ),
                const SizedBox(height: 12),
                // DNI — real KYC check
                _DniDocRow(
                  isVerified: isIdentityVerified,
                  onVerify: () => context.go('/verify-identity'),
                ),
              ],
            ),
          ),
          if (requiresCedula) ...[
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.home_work_outlined,
              title: 'doc_verification.regional_doc_title'.tr(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF3B82F6), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${'doc_verification.cedula_ccaa_required'.tr()} ${ccaaDisplayName[ccaa] ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cedula — coming soon
                  _ComingSoonDocRow(
                    icon: Icons.apartment_outlined,
                    title: 'doc_verification.cedula_title'.tr(),
                    subtitle: 'doc_verification.cedula_subtitle'.tr(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Builder(builder: (context) {
            final colorScheme = Theme.of(context).colorScheme;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'doc_verification.mvp_info'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Coming-soon document row ──────────────────────────────────────────────────

/// Document row for CEE, Nota Simple, and Cedula.
/// The upload is not yet available; shows a "Proximamente" request button.
class _ComingSoonDocRow extends StatelessWidget {
  const _ComingSoonDocRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.warningText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? warningText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (warningText != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 12, color: colorScheme.tertiary),
                const SizedBox(width: 4),
                Text(
                  warningText!,
                  style: TextStyle(
                      fontSize: 11, color: colorScheme.onTertiaryContainer),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: null, // disabled — coming soon
              icon: const Icon(Icons.send_outlined, size: 14),
              label: Text(
                'doc_verification.request_coming_soon'.tr(),
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
                side: BorderSide(color: colorScheme.outlineVariant),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DNI document row ──────────────────────────────────────────────────────────

/// Document row for DNI/NIE.
/// Shows KYC verification status and routes to /verify-identity if needed.
class _DniDocRow extends StatelessWidget {
  const _DniDocRow({
    required this.isVerified,
    required this.onVerify,
  });

  final bool isVerified;
  final VoidCallback onVerify;

  static const _green = Color(0xFF16A34A);
  static const _greenBg = Color(0xFFF0FDF4);
  static const _greenBorder = Color(0xFFBBF7D0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isVerified ? _greenBg : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? _greenBorder : colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.badge_outlined,
                size: 20,
                color: isVerified ? _green : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'doc_verification.dni_title'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color:
                            isVerified ? _green : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isVerified
                          ? 'doc_verification.dni_verified_subtitle'.tr()
                          : 'doc_verification.dni_subtitle'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        color: isVerified
                            ? _green
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified)
                const Icon(Icons.verified_user,
                    color: _green, size: 22),
            ],
          ),
          if (!isVerified) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onVerify,
                icon: const Icon(Icons.shield_outlined, size: 14),
                label: Text(
                  'doc_verification.dni_verify_button'.tr(),
                  style: const TextStyle(fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
