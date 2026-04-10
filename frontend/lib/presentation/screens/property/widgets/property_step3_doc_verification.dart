import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/ccaa_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/property_form_provider.dart';

// ── Color palette ─────────────────────────────────────────────────────────────

const _blueBg = Color(0xFFEFF6FF);
const _blueBorder = Color(0xFFBFDBFE);
const _blueIcon = Color(0xFF2563EB);
const _blueDark = Color(0xFF1E40AF);
const _blueSubtle = Color(0xFF64748B);

const _greenBg = Color(0xFFF0FDF4);
const _greenBorder = Color(0xFFBBF7D0);
const _green = Color(0xFF16A34A);
const _greenDark = Color(0xFF166534);

// ── Screen ────────────────────────────────────────────────────────────────────

class PropertyStep3DocVerification extends ConsumerStatefulWidget {
  const PropertyStep3DocVerification({super.key});

  @override
  ConsumerState<PropertyStep3DocVerification> createState() =>
      _PropertyStep3DocVerificationState();
}

class _PropertyStep3DocVerificationState
    extends ConsumerState<PropertyStep3DocVerification> {
  bool _ceeUploaded = false;
  bool _notaSimpleUploaded = false;
  bool _cedulaUploaded = false;

  void _simulateUpload(BuildContext context, VoidCallback toggle) {
    toggle();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('doc_verification.upload_coming_soon'.tr()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2563EB),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                // CEE
                _DocRow(
                  icon: Icons.energy_savings_leaf_outlined,
                  title: 'doc_verification.cee_title'.tr(),
                  subtitle: 'doc_verification.cee_subtitle'.tr(),
                  isUploaded: _ceeUploaded,
                  onUpload: () => _simulateUpload(
                    context,
                    () => setState(() => _ceeUploaded = !_ceeUploaded),
                  ),
                ),
                const SizedBox(height: 12),
                // Nota Simple
                _DocRow(
                  icon: Icons.description_outlined,
                  title: 'doc_verification.nota_simple_title'.tr(),
                  subtitle: 'doc_verification.nota_simple_subtitle'.tr(),
                  warningText: 'doc_verification.nota_simple_warning'.tr(),
                  isUploaded: _notaSimpleUploaded,
                  onUpload: () {
                    _simulateUpload(
                      context,
                      () => setState(
                        () => _notaSimpleUploaded = !_notaSimpleUploaded,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // DNI — KYC flow
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _blueBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _blueBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: _blueIcon,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${'doc_verification.cedula_ccaa_required'.tr()} ${ccaaDisplayName[ccaa] ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _blueDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cedula
                  _DocRow(
                    icon: Icons.apartment_outlined,
                    title: 'doc_verification.cedula_title'.tr(),
                    subtitle: 'doc_verification.cedula_subtitle'.tr(),
                    isUploaded: _cedulaUploaded,
                    onUpload: () => _simulateUpload(
                      context,
                      () => setState(() => _cedulaUploaded = !_cedulaUploaded),
                    ),
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
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
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
          },),
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
            color: Colors.black.withValues(alpha: 0.06),
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

// ── Doc row (CEE / Nota Simple / Cédula) ──────────────────────────────────────

/// Displays a document row with:
/// - Blue-soft background when the document is missing.
/// - Green-soft background when it has been uploaded.
/// - Inline compact upload button + disabled "Próximamente" button on the right.
class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isUploaded,
    required this.onUpload,
    this.warningText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isUploaded;
  final VoidCallback onUpload;
  final String? warningText;

  @override
  Widget build(BuildContext context) {
    final bgColor = isUploaded ? _greenBg : _blueBg;
    final borderColor = isUploaded ? _greenBorder : _blueBorder;
    final iconColor = isUploaded ? _green : _blueIcon;
    final titleColor = isUploaded ? _greenDark : _blueDark;
    final subtitleColor = isUploaded ? _green : _blueSubtle;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: iconColor),
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
                        color: titleColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isUploaded)
                const Icon(Icons.check_circle, color: _green, size: 22)
              else ...[
                // Upload button (restore prior functionality)
                _InlineButton(
                  onPressed: onUpload,
                  icon: Icons.upload_file,
                  label: 'doc_verification.select_file'.tr(),
                  color: _blueIcon,
                ),
                const SizedBox(width: 6),
                // Coming-soon button (disabled, informative)
                _InlineButton(
                  onPressed: null,
                  icon: Icons.pending_outlined,
                  label: 'doc_verification.request_coming_soon'.tr(),
                  color: const Color(0xFF94A3B8),
                  isDisabled: true,
                ),
              ],
            ],
          ),
          if (warningText != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 12, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(
                  warningText!,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── DNI row ──────────────────────────────────────────────────────────────────

/// DNI/NIE row driven by KYC status (no file upload — goes through /verify-identity).
class _DniDocRow extends StatelessWidget {
  const _DniDocRow({
    required this.isVerified,
    required this.onVerify,
  });

  final bool isVerified;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final bgColor = isVerified ? _greenBg : _blueBg;
    final borderColor = isVerified ? _greenBorder : _blueBorder;
    final iconColor = isVerified ? _green : _blueIcon;
    final titleColor = isVerified ? _greenDark : _blueDark;
    final subtitleColor = isVerified ? _green : _blueSubtle;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.badge_outlined, size: 20, color: iconColor),
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
                    color: titleColor,
                  ),
                ),
                Text(
                  isVerified
                      ? 'doc_verification.dni_verified_subtitle'.tr()
                      : 'doc_verification.dni_subtitle'.tr(),
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isVerified)
            const Icon(Icons.verified_user, color: _green, size: 22)
          else
            _InlineButton(
              onPressed: onVerify,
              icon: Icons.shield_outlined,
              label: 'doc_verification.dni_verify_button'.tr(),
              color: _blueIcon,
            ),
        ],
      ),
    );
  }
}

// ── Compact inline button ─────────────────────────────────────────────────────

class _InlineButton extends StatelessWidget {
  const _InlineButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.isDisabled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDisabled ? const Color(0xFF94A3B8) : color;
    final borderColor =
        isDisabled ? const Color(0xFFCBD5E1) : color.withValues(alpha: 0.6);

    // Active buttons match the AppBar button size (h:14 v:10, font 13).
    // Disabled "Proximamente" keeps compact padding with smaller font.
    final padding = isDisabled
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    final fontSize = isDisabled ? 11.0 : 13.0;
    final iconSize = isDisabled ? 13.0 : 15.0;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize),
      label: Text(label, style: TextStyle(fontSize: fontSize)),
      style: OutlinedButton.styleFrom(
        foregroundColor: effectiveColor,
        side: BorderSide(color: borderColor),
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
