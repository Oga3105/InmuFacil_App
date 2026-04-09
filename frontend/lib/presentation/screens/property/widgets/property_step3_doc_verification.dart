import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/ccaa_utils.dart';
import '../../../providers/property_form_provider.dart';

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
  bool _dniUploaded = false;
  bool _cedulaUploaded = false;

  void _showUploadSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('doc_verification.upload_coming_soon'.tr()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF135BEC),
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
                _DocumentRow(
                  icon: Icons.energy_savings_leaf_outlined,
                  title: 'doc_verification.cee_title'.tr(),
                  subtitle: 'doc_verification.cee_subtitle'.tr(),
                  isUploaded: _ceeUploaded,
                  onTap: () {
                    setState(() => _ceeUploaded = !_ceeUploaded);
                    if (!_ceeUploaded) _showUploadSnackBar(context);
                  },
                ),
                const SizedBox(height: 12),
                _DocumentRow(
                  icon: Icons.description_outlined,
                  title: 'doc_verification.nota_simple_title'.tr(),
                  subtitle: 'doc_verification.nota_simple_subtitle'.tr(),
                  isUploaded: _notaSimpleUploaded,
                  warningText: 'doc_verification.nota_simple_warning'.tr(),
                  onTap: () {
                    setState(() => _notaSimpleUploaded = !_notaSimpleUploaded);
                    if (!_notaSimpleUploaded) _showUploadSnackBar(context);
                  },
                ),
                const SizedBox(height: 12),
                _DocumentRow(
                  icon: Icons.badge_outlined,
                  title: 'doc_verification.dni_title'.tr(),
                  subtitle: 'doc_verification.dni_subtitle'.tr(),
                  isUploaded: _dniUploaded,
                  onTap: () {
                    setState(() => _dniUploaded = !_dniUploaded);
                    if (!_dniUploaded) _showUploadSnackBar(context);
                  },
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
                  _DocumentRow(
                    icon: Icons.apartment_outlined,
                    title: 'doc_verification.cedula_title'.tr(),
                    subtitle: 'doc_verification.cedula_subtitle'.tr(),
                    isUploaded: _cedulaUploaded,
                    onTap: () {
                      setState(
                          () => _cedulaUploaded = !_cedulaUploaded);
                      if (!_cedulaUploaded) _showUploadSnackBar(context);
                    },
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

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isUploaded,
    required this.onTap,
    this.warningText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isUploaded;
  final VoidCallback onTap;
  final String? warningText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isUploaded ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded
              ? colorScheme.primary.withOpacity(0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isUploaded
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
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
                        color: isUploaded
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
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
              if (isUploaded)
                Icon(Icons.check_circle,
                    color: colorScheme.primary, size: 20)
              else
                OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.upload_file, size: 14),
                  label: Text('doc_verification.select_file'.tr(),
                      style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          if (warningText != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule,
                    size: 12, color: colorScheme.tertiary),
                const SizedBox(width: 4),
                Text(
                  warningText!,
                  style: TextStyle(
                      fontSize: 11, color: colorScheme.onTertiaryContainer),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
