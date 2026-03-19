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
/// document type and blocks confirmation while the input is invalid.
///
/// [onConfirm] receives the confirmed number (OCR-extracted or manually
/// entered). [onReject] is called when the user says the number is wrong.
/// [onReupload] is called when the image is unreadable.
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

  /// Called with the confirmed document number (may be the manual input).
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
        return 'Ej: X1234567L';
      case DocumentType.pasaporte:
        return 'Ej: PAA123456';
      default:
        return 'Ej: 12345678Z';
    }
  }

  /// Whether the confirm button should be enabled.
  bool get _canConfirm {
    if (!_useManual) return true; // OCR path: always confirmable
    return _validationResult?.isValid == true;
  }

  /// The number that will be passed to [onConfirm].
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
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    );
  }

  Widget _buildTitle() {
    if (widget.isLoading) {
      return const Text(
        'Leyendo documento',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      );
    }
    if (!widget.readable) {
      return const Text(
        'Imagen ilegible',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFFDC2626),
        ),
      );
    }
    return Text(
      widget.isSecondAttempt
          ? 'Segunda lectura'
          : 'Confirma tu numero de documento',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) return _buildLoadingBody();
    if (!widget.readable) return _buildUnreadableBody();
    return _buildResultBody();
  }

  Widget _buildLoadingBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
          const SizedBox(height: 16),
          Text(
            'Leyendo el numero de tu ${widget.documentTypeLabel}...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadableBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _alertBox(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFDC2626),
            bg: const Color(0xFFFEF2F2),
            border: const Color(0xFFFECACA),
            text: 'No se ha podido leer el numero del documento en esta imagen. '
                'Asegurate de que la foto sea nitida, con buena iluminacion y sin reflejos.',
            textColor: const Color(0xFFB91C1C),
          ),
          const SizedBox(height: 12),
          Text(
            'Sube de nuevo el documento para intentarlo otra vez.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBody() {
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
              text: 'Segundo intento. Si el numero sigue siendo incorrecto '
                  'puedes introducirlo manualmente.',
              textColor: const Color(0xFF92400E),
            ),
          ),
        Text(
          'El sistema ha leido el siguiente numero en tu ${widget.documentTypeLabel}:',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 12),
        _docNumberBox(widget.docNumber ?? ''),
        const SizedBox(height: 12),
        const Text(
          '¿Es este el numero correcto de tu documento?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Compruebalo en el documento fisico antes de confirmar.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 4),
                Text(
                  _useManual
                      ? 'Cancelar entrada manual'
                      : 'Introducir el numero manualmente',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
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

    // CIF notice overrides the normal field error
    if (isCif) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _manualController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: _placeholder(),
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDC2626)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDC2626)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFFDC2626), width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          _alertBox(
            icon: Icons.business_center_outlined,
            iconColor: const Color(0xFFD97706),
            bg: const Color(0xFFFFFBEB),
            border: const Color(0xFFFDE68A),
            text: 'Este parece ser un CIF de empresa. Por el momento, '
                'InmuFacil solo gestiona operaciones entre particulares. '
                'Si eres una empresa, contacta con nosotros para mas informacion.',
            textColor: const Color(0xFF92400E),
          ),
        ],
      );
    }

    return TextField(
      controller: _manualController,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        hintText: _placeholder(),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        errorText: hasError ? result!.errorMessage : null,
        errorMaxLines: 2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError
                ? const Color(0xFFDC2626)
                : const Color(0xFF2563EB),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        // Green check when valid
        suffixIcon: result?.isValid == true
            ? const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20)
            : null,
      ),
      style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
    );
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  List<Widget> _buildActions(BuildContext context) {
    if (widget.isLoading) return [];

    if (!widget.readable) {
      return [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onReupload();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Subir documento de nuevo',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ];
    }

    final confirmDisabled = !_canConfirm;

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
        child: const Text('No, es incorrecto',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      FilledButton(
        onPressed: confirmDisabled
            ? null
            : () {
                Navigator.of(context).pop();
                widget.onConfirm(_confirmedNumber);
              },
        style: FilledButton.styleFrom(
          backgroundColor:
              confirmDisabled ? Colors.grey.shade400 : const Color(0xFF16A34A),
          disabledBackgroundColor: Colors.grey.shade300,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: const Text('Si, es correcto',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ];
  }

  // -------------------------------------------------------------------------
  // Shared sub-widgets
  // -------------------------------------------------------------------------

  Widget _docNumberBox(String number) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2563EB), width: 2),
      ),
      child: Text(
        number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1E3A8A),
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
