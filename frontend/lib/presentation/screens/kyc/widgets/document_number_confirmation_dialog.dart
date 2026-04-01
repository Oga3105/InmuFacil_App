import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/document_number_validator.dart';
import '../../../providers/verification_provider.dart';

/// Dialog shown after both document images are uploaded.
///
/// States:
///   loading    — Gemini OCR in progress
///   result     — number extracted, user confirms or rejects
///   unreadable — OCR failed, guide to re-upload
///
/// On the second attempt the result state also shows an expandable manual
/// entry field. The field validates the number in real-time according to the
/// document type and blocks confirmation while the input is invalid or a CIF
/// is detected.
///
/// All strings use easy_localization (`.tr()`). Keys live under
/// `kyc.doc_number_dialog.*` in each locale file.
class DocumentNumberConfirmationDialog extends StatefulWidget {
  const DocumentNumberConfirmationDialog._({
    required this.isLoading,
    required this.docNumber,
    required this.readable,
    required this.isSecondAttempt,
    required this.documentType,
    required this.documentTypeLabel,
    required this.onConfirm,
    required this.onReject,
    required this.onReupload,
  });

  final bool isLoading;
  final String? docNumber;
  final bool readable;
  final bool isSecondAttempt;
  final DocumentType? documentType;
  final String documentTypeLabel;

  /// Called with the confirmed document number (OCR or manually entered).
  final void Function(String number) onConfirm;
  final VoidCallback onReject;
  final VoidCallback onReupload;

  static Future<void> show({
    required BuildContext context,
    required bool isLoading,
    required String? docNumber,
    required bool readable,
    required bool isSecondAttempt,
    required DocumentType? documentType,
    required String documentTypeLabel,
    required void Function(String number) onConfirm,
    required VoidCallback onReject,
    required VoidCallback onReupload,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DocumentNumberConfirmationDialog._(
        isLoading: isLoading,
        docNumber: docNumber,
        readable: readable,
        isSecondAttempt: isSecondAttempt,
        documentType: documentType,
        documentTypeLabel: documentTypeLabel,
        onConfirm: onConfirm,
        onReject: onReject,
        onReupload: onReupload,
      ),
    );
  }

  @override
  State<DocumentNumberConfirmationDialog> createState() =>
      _DocumentNumberConfirmationDialogState();
}

class _DocumentNumberConfirmationDialogState
    extends State<DocumentNumberConfirmationDialog> {
  static const String _ns = 'kyc.doc_number_dialog';

  final _manualController = TextEditingController();
  bool _useManual = false;
  DocumentValidationResult? _validationResult;

  @override
  void initState() {
    super.initState();
    _manualController.addListener(_onManualChanged);
  }

  @override
  void dispose() {
    _manualController.removeListener(_onManualChanged);
    _manualController.dispose();
    super.dispose();
  }

  void _onManualChanged() {
    final result = DocumentNumberValidator.validate(
      _manualController.text,
      widget.documentType,
    );
    setState(() => _validationResult = result);
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  String _placeholder() {
    switch (widget.documentType) {
      case DocumentType.nie:
        return '$_ns.placeholder_nie'.tr();
      case DocumentType.pasaporte:
        return '$_ns.placeholder_passport'.tr();
      default:
        return '$_ns.placeholder_dni'.tr();
    }
  }

  bool get _canConfirm {
    if (!_useManual) return true;
    return _validationResult?.isValid == true;
  }

  String get _confirmedNumber {
    if (_useManual) {
      return _manualController.text
          .trim()
          .toUpperCase()
          .replaceAll(RegExp(r'[\s\-]'), '');
    }
    return widget.docNumber ?? '';
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: _buildTitle(),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(child: _buildContent()),
      ),
      actions: _buildActions(context),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    );
  }

  Widget _buildTitle() {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.isLoading) {
      return Text(
        '$_ns.title_loading'.tr(),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      );
    }
    if (!widget.readable) {
      return Text(
        '$_ns.title_unreadable'.tr(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.error,
        ),
      );
    }
    return Text(
      widget.isSecondAttempt
          ? '$_ns.title_second_attempt'.tr()
          : '$_ns.title_confirm'.tr(),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) return _buildLoadingBody();
    if (!widget.readable) return _buildUnreadableBody();
    return _buildResultBody();
  }

  Widget _buildLoadingBody() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            '$_ns.loading_body'
                .tr(namedArgs: {'doc_type': widget.documentTypeLabel}),
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadableBody() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _alertBox(
            icon: Icons.warning_amber_rounded,
            iconColor: colorScheme.error,
            bg: colorScheme.errorContainer,
            border: colorScheme.error.withOpacity(0.3),
            text: '$_ns.unreadable_body'.tr(),
            textColor: colorScheme.onErrorContainer,
          ),
          const SizedBox(height: 12),
          Text(
            '$_ns.unreadable_hint'.tr(),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() {
              _useManual = !_useManual;
              if (!_useManual) {
                _manualController.clear();
                _validationResult = null;
              }
            }),
            child: Row(
              children: [
                Icon(
                  _useManual
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _useManual
                      ? '$_ns.manual_toggle_close'.tr()
                      : '$_ns.manual_toggle_open'.tr(),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_useManual) ...[
            const SizedBox(height: 12),
            _buildManualField(),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResultBody() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isSecondAttempt)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _alertBox(
              icon: Icons.info_outline,
              iconColor: const Color(0xFFD97706),
              bg: const Color(0xFFFFFBEB),
              border: const Color(0xFFFDE68A),
              text: '$_ns.second_attempt_warning'.tr(),
              textColor: const Color(0xFF92400E),
            ),
          ),
        Text(
          '$_ns.extracted_number_label'
              .tr(namedArgs: {'doc_type': widget.documentTypeLabel}),
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 12),
        _docNumberBox(widget.docNumber ?? ''),
        const SizedBox(height: 12),
        Text(
          '$_ns.confirm_question'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$_ns.confirm_hint'.tr(),
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),

        // Manual entry — only on second attempt
        if (widget.isSecondAttempt) ...[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() {
              _useManual = !_useManual;
              if (!_useManual) {
                _manualController.clear();
                _validationResult = null;
              }
            }),
            child: Row(
              children: [
                Icon(
                  _useManual
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _useManual
                      ? '$_ns.manual_toggle_close'.tr()
                      : '$_ns.manual_toggle_open'.tr(),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_useManual) ...[
            const SizedBox(height: 12),
            _buildManualField(),
          ],
        ],

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildManualField() {
    final result = _validationResult;
    final isCif = result?.isCif == true;
    final hasError =
        result != null && !result.isValid && _manualController.text.isNotEmpty;

    // Translate the error message (with optional named args)
    final String? errorText = hasError && !isCif && result?.errorKey != null
        ? result!.errorKey!.tr(namedArgs: result.errorArgs ?? {})
        : null;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isCif || (hasError && !isCif)
        ? colorScheme.error
        : colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _manualController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: _placeholder(),
            hintStyle: TextStyle(color: Colors.grey.shade400),
            errorText: errorText,
            errorMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: isCif
                  ? BorderSide(color: colorScheme.error)
                  : BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: result?.isValid == true
                ? Icon(Icons.check_circle,
                    color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A), size: 20)
                : null,
          ),
          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
        ),
        if (isCif) ...[
          const SizedBox(height: 10),
          _alertBox(
            icon: Icons.business_center_outlined,
            iconColor: const Color(0xFFD97706),
            bg: const Color(0xFFFFFBEB),
            border: const Color(0xFFFDE68A),
            text: '$_ns.cif_banner'.tr(),
            textColor: const Color(0xFF92400E),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  List<Widget> _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.isLoading) return [];

    if (!widget.readable) {
      if (_useManual) {
        return [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onReupload();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.upload_file, size: 16),
            label: Text('$_ns.btn_reupload'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: _canConfirm
                ? () {
                    Navigator.of(context).pop();
                    widget.onConfirm(_confirmedNumber);
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
              disabledBackgroundColor:
                  colorScheme.onSurface.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text('$_ns.btn_confirm'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ];
      }
      return [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onReupload();
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text(
              '$_ns.btn_reupload'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ];
    }

    return [
      OutlinedButton(
        onPressed: () {
          Navigator.of(context).pop();
          widget.onReject();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade700,
          side: BorderSide(color: Colors.red.shade300),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: Text(
          '$_ns.btn_reject'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      FilledButton(
        onPressed: _canConfirm
            ? () {
                Navigator.of(context).pop();
                widget.onConfirm(_confirmedNumber);
              }
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
          disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: Text(
          '$_ns.btn_confirm'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ];
  }

  // -------------------------------------------------------------------------
  // Shared sub-widgets
  // -------------------------------------------------------------------------

  Widget _docNumberBox(String number) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
      child: Text(
        number,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: colorScheme.onPrimaryContainer,
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _alertBox({
    required IconData icon,
    required Color iconColor,
    required Color bg,
    required Color border,
    required String text,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
