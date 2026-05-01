import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class VisitCancelDialog extends StatefulWidget {
  const VisitCancelDialog({super.key});

  @override
  State<VisitCancelDialog> createState() => _VisitCancelDialogState();
}

class _VisitCancelDialogState extends State<VisitCancelDialog> {
  String? _selectedReasonKey;
  final _otherReasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _keyWithdraw = 'visit_cancel.reason_withdraw';
  static const _keySchedule = 'visit_cancel.reason_schedule';
  static const _keyOther = 'visit_cancel.reason_other';

  final List<String> _reasonKeys = [
    _keyWithdraw,
    _keySchedule,
    _keyOther,
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
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text:
                  '${'visit_cancel.title_part1'.tr()} ${'visit_cancel.title_part2'.tr()}',
              style: const TextStyle(color: Color(0xFF135BEC)),
            ),
          ],
        ),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'visit_cancel.reason_prompt'.tr(),
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            ..._reasonKeys.map((key) => ListTile(
                  title: Text(key.tr(), style: const TextStyle(fontSize: 14)),
                  leading: Radio<String>(
                    value: key,
                    groupValue: _selectedReasonKey,
                    activeColor: const Color(0xFF135BEC),
                    onChanged: (val) {
                      setState(() => _selectedReasonKey = val);
                    },
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () {
                    setState(() => _selectedReasonKey = key);
                  },
                )),
            if (_selectedReasonKey == _keyOther) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _otherReasonController,
                decoration: InputDecoration(
                  labelText: 'visit_cancel.reason_other_label'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'visit_cancel.reason_other_required'.tr();
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
          child: Text('visit_cancel.back_btn'.tr(),
              style: const TextStyle(color: Color(0xFF64748B))),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            if (_selectedReasonKey == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('visit_cancel.reason_required'.tr())),
              );
              return;
            }
            if (_selectedReasonKey == _keyOther &&
                !_formKey.currentState!.validate()) {
              return;
            }

            final finalReason = _selectedReasonKey == _keyOther
                ? _otherReasonController.text.trim()
                : _selectedReasonKey!.tr();

            Navigator.pop(context, finalReason);
          },
          child: Text('visit_cancel.confirm_btn'.tr()),
        ),
      ],
    );
  }
}
