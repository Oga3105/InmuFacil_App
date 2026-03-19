import 'package:flutter/material.dart';

/// Dialog shown after both document images are uploaded.
/// States:
///   loading  — Gemini OCR in progress
///   result   — number extracted, user confirms or rejects
///   unreadable — OCR failed, guide to re-upload
///   manual   — 2nd attempt, includes manual entry field as fallback
class DocumentNumberConfirmationDialog extends StatefulWidget {
  const DocumentNumberConfirmationDialog._({
    required this.isLoading,
    required this.docNumber,
    required this.readable,
    required this.isSecondAttempt,
    required this.documentTypeLabel,
    required this.onConfirm,
    required this.onReject,
    required this.onReupload,
  });

  final bool isLoading;
  final String? docNumber;
  final bool readable;
  final bool isSecondAttempt;
  final String documentTypeLabel;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onReupload;

  /// Show the dialog.
  /// [onConfirm] is called when the user confirms the number is correct.
  /// [onReject] is called when the user says it is wrong.
  /// [onReupload] is called when the image is unreadable and the user must re-upload.
  static Future<void> show({
    required BuildContext context,
    required bool isLoading,
    required String? docNumber,
    required bool readable,
    required bool isSecondAttempt,
    required String documentTypeLabel,
    required VoidCallback onConfirm,
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

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  String _formatHint(String documentTypeLabel) {
    switch (documentTypeLabel.toUpperCase()) {
      case 'NIE':
        return 'Formato: X1234567L';
      case 'PASAPORTE':
      case 'PASAP.':
        return 'Formato: PAA123456';
      default:
        return 'Formato: 12345678Z';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: _buildTitle(),
      content: SizedBox(
        width: 360,
        child: _buildContent(),
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
      widget.isSecondAttempt ? 'Segunda lectura' : 'Confirma tu numero de documento',
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No se ha podido leer el numero del documento en esta imagen. '
                    'Asegurate de que la foto sea nitida, con buena iluminacion y sin reflejos.',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
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
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Segundo intento. Si el numero sigue siendo incorrecto, '
                    'se te pedira que subas el documento de nuevo.',
                    style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 12,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        Text(
          'El sistema ha leido el siguiente numero en tu ${widget.documentTypeLabel}:',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 12),
        // Doc number display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2563EB), width: 2),
          ),
          child: Text(
            widget.docNumber ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E3A8A),
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '¿Es este el numero correcto de tu documento?',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Si no recuerdas tu numero, compruebalo en el documento fisico.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        if (widget.isSecondAttempt) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _useManual = !_useManual),
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
                      ? 'Ocultar entrada manual'
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
            const SizedBox(height: 10),
            TextField(
              controller: _manualController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: _formatHint(widget.documentTypeLabel),
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2563EB)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ],
        const SizedBox(height: 4),
      ],
    );
  }

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

    return [
      // No button
      OutlinedButton(
        onPressed: () {
          Navigator.of(context).pop();
          widget.onReject();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade700,
          side: BorderSide(color: Colors.red.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: const Text('No, es incorrecto',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      // Yes button
      FilledButton(
        onPressed: () {
          Navigator.of(context).pop();
          widget.onConfirm();
        },
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: const Text('Si, es correcto',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ];
  }
}
