import 'package:flutter/material.dart';

class VisitCancelDialog extends StatefulWidget {
  const VisitCancelDialog({super.key});

  @override
  State<VisitCancelDialog> createState() => _VisitCancelDialogState();
}

class _VisitCancelDialogState extends State<VisitCancelDialog> {
  String? _selectedReason;
  final _otherReasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _reasons = [
    'Retirar oferta',
    'Indisposición / Problemas de agenda',
    'Otros',
  ];

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Anular ', style: TextStyle(color: Color(0xFF2563EB))),
            TextSpan(text: 'visita', style: TextStyle(color: Color(0xFF16A34A))),
          ],
        ),
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Por favor, indica el motivo de la anulación:',
              style: TextStyle(fontSize: 14, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            ..._reasons.map((reason) => ListTile(
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  leading: Radio<String>(
                    value: reason,
                    groupValue: _selectedReason,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (val) {
                      setState(() => _selectedReason = val);
                    },
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () {
                    setState(() => _selectedReason = reason);
                  },
                )),
            if (_selectedReason == 'Otros') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _otherReasonController,
                decoration: InputDecoration(
                  labelText: 'Especifica el motivo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El motivo es obligatorio.';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver', style: TextStyle(color: Color(0xFF64748B))),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (_selectedReason == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selecciona un motivo.')),
              );
              return;
            }
            if (_selectedReason == 'Otros' && !_formKey.currentState!.validate()) {
              return;
            }
            
            final finalReason = _selectedReason == 'Otros' 
                ? _otherReasonController.text.trim()
                : _selectedReason!;
                
            Navigator.pop(context, finalReason);
          },
          child: const Text('Anular Visita'),
        ),
      ],
    );
  }
}
