import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Categories for reporting a suspected professional agent.
enum ReportCategory {
  profesionalCamuflado,
  pideComision,
  datosInexactos,
}

/// Extension to map enum values to API-compatible strings.
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

/// A button that opens a modal to report a suspected professional agent.
///
/// Place this widget on property detail screens or user profile cards.
/// It requires the [reportedUserId] of the user being reported and an
/// [onReport] callback that handles the API call.
class ReportButton extends StatelessWidget {
  final int reportedUserId;
  final Future<void> Function(int reportedUserId, ReportCategory category, String? description) onReport;

  const ReportButton({
    super.key,
    required this.reportedUserId,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.flag_outlined),
      tooltip: 'report.button_tooltip'.tr(),
      onPressed: () => _showReportModal(context),
    );
  }

  Future<void> _showReportModal(BuildContext context) async {
    final result = await showModalBottomSheet<_ReportResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ReportModalContent(),
    );

    if (result != null && context.mounted) {
      try {
        await onReport(reportedUserId, result.category, result.description);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('report.success'.tr())),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('report.error'.tr())),
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

class _ReportModalContent extends StatefulWidget {
  @override
  State<_ReportModalContent> createState() => _ReportModalContentState();
}

class _ReportModalContentState extends State<_ReportModalContent> {
  ReportCategory? _selectedCategory;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'report.modal_title'.tr(),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'report.modal_subtitle'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...ReportCategory.values.map((category) => RadioListTile<ReportCategory>(
            title: Text(category.translationKey.tr()),
            value: category,
            groupValue: _selectedCategory,
            onChanged: (value) => setState(() => _selectedCategory = value),
          )),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'report.description_label'.tr(),
              hintText: 'report.description_hint'.tr(),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
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
                child: Text('report.submit'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
