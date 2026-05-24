import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/network/dio_factory.dart';

enum ReportCategory {
  profesionalCamuflado,
  pideComision,
  datosInexactos,
}

extension ReportCategoryExt on ReportCategory {
  String get apiValue {
    switch (this) {
      case ReportCategory.profesionalCamuflado:
        return 'profesional_camuflado';
      case ReportCategory.pideComision:
        return 'pide_comision';
      case ReportCategory.datosInexactos:
        return 'datos_inexactos';
    }
  }

  String get translationKey {
    switch (this) {
      case ReportCategory.profesionalCamuflado:
        return 'report.category_professional';
      case ReportCategory.pideComision:
        return 'report.category_commission';
      case ReportCategory.datosInexactos:
        return 'report.category_inaccurate';
    }
  }
}

class ReportButton extends StatelessWidget {
  final int reportedUserId;

  const ReportButton({
    super.key,
    required this.reportedUserId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextButton.icon(
      icon: Icon(Icons.report_outlined, size: 18, color: colorScheme.error),
      label: Text(
        'report.button_label'.tr(),
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.error.withValues(alpha: 0.3)),
        ),
      ),
      onPressed: () => _showReportDialog(context),
    );
  }

  Future<void> _showReportDialog(BuildContext context) async {
    final result = await showDialog<_ReportResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _ReportDialogContent(),
    );

    if (result != null && context.mounted) {
      try {
        final dio = buildAuthDio();
        await dio.post('/reports/report-agent', data: {
          'reported_id': reportedUserId,
          'reason_category': result.category.apiValue,
          if (result.description != null) 'description': result.description,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('report.success'.tr())),
          );
        }
      } on DioException catch (e) {
        if (context.mounted) {
          final detail = e.response?.data is Map
              ? (e.response?.data as Map)['detail'] ?? 'report.error'.tr()
              : 'report.error'.tr();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(detail.toString())),
          );
        }
      }
    }
  }
}

class _ReportResult {
  final ReportCategory category;
  final String? description;

  _ReportResult({required this.category, this.description});
}

class _ReportDialogContent extends StatefulWidget {
  const _ReportDialogContent();

  @override
  State<_ReportDialogContent> createState() => _ReportDialogContentState();
}

class _ReportDialogContentState extends State<_ReportDialogContent> {
  ReportCategory? _selectedCategory;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.report_outlined,
                      color: colorScheme.onErrorContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'report.modal_title'.tr(),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Warning box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 15,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'report.modal_subtitle'.tr(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Radio options
              ...ReportCategory.values.map(
                (category) => RadioListTile<ReportCategory>(
                  title: Text(
                    category.translationKey.tr(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  value: category,
                  groupValue: _selectedCategory,
                  activeColor: colorScheme.error,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
              ),
              const SizedBox(height: 8),

              // Description field
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'report.description_label'.tr(),
                  hintText: 'report.description_hint'.tr(),
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.error, width: 1.5),
                  ),
                  counterStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('common.cancel'.tr()),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selectedCategory == null
                        ? null
                        : () {
                            Navigator.of(context).pop(_ReportResult(
                              category: _selectedCategory!,
                              description: _descriptionController.text.trim().isNotEmpty
                                  ? _descriptionController.text.trim()
                                  : null,
                            ));
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      disabledBackgroundColor: colorScheme.error.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('report.submit'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
