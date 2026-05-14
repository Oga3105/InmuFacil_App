import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/search_provider.dart';

// ─── Dialog ──────────────────────────────────────────────────────────────────

class ContactEmailDialog extends ConsumerStatefulWidget {
  const ContactEmailDialog({super.key});

  @override
  ConsumerState<ContactEmailDialog> createState() => _ContactEmailDialogState();
}

class _ContactEmailDialogState extends ConsumerState<ContactEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  static const _kBlue = Color(0xFF135BEC);

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.client.post<void>(
        '/contact/message',
        data: {
          'subject': _subjectCtrl.text.trim(),
          'message': _messageCtrl.text.trim(),
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('info.contact.dialog.success'.tr()),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on DioException catch (e) {
      String msg;
      if (e.response?.statusCode == 429) {
        msg = 'info.contact.dialog.rate_limit'.tr();
      } else {
        msg = 'info.contact.dialog.error'.tr();
      }
      setState(() => _errorMessage = msg);
    } catch (_) {
      setState(() => _errorMessage = 'info.contact.dialog.error'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kBlue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.email_outlined,
                          color: _kBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'info.contact.dialog.title'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _kBlue,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Name (read-only) ────────────────────────────────────────
                _ReadOnlyField(
                  label: 'info.contact.dialog.name_label'.tr(),
                  value: user?.name ?? user?.email ?? '',
                ),
                const SizedBox(height: 12),

                // ── Email (read-only) ───────────────────────────────────────
                _ReadOnlyField(
                  label: 'info.contact.dialog.email_label'.tr(),
                  value: user?.email ?? '',
                ),
                const SizedBox(height: 12),

                // ── Subject ─────────────────────────────────────────────────
                TextFormField(
                  controller: _subjectCtrl,
                  enabled: !_isLoading,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: 'info.contact.dialog.subject_label'.tr(),
                    hintText: 'info.contact.dialog.subject_hint'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 3) {
                      return 'info.contact.dialog.subject_label'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── Message ─────────────────────────────────────────────────
                TextFormField(
                  controller: _messageCtrl,
                  enabled: !_isLoading,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    labelText: 'info.contact.dialog.message_label'.tr(),
                    hintText: 'info.contact.dialog.message_hint'.tr(),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'info.contact.dialog.message_label'.tr();
                    }
                    return null;
                  },
                ),

                // ── Error ───────────────────────────────────────────────────
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                                color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Send button ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('info.contact.dialog.send_button'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Read-only field helper ───────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      child: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
