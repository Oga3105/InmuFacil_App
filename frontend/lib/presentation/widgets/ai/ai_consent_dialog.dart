import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/ai_consent_service.dart';

/// Muestra el diálogo de consentimiento RGPD para uso de IA.
///
/// Uso:
/// ```dart
/// final accepted = await AiConsentDialog.show(
///   context: context,
///   config: AiConsentConfig.propertyDescription,
/// );
/// if (accepted) { /* proceder con la accion */ }
/// ```
///
/// Si el usuario acepta, el consentimiento SE REGISTRA EN BD antes de devolver true.
/// Si el registro falla, se muestra un error y se devuelve false.
/// Si el usuario cancela, se devuelve false sin registrar nada.
class AiConsentDialog extends StatefulWidget {
  const AiConsentDialog._({required this.config});

  final AiConsentConfig config;

  /// Muestra el diálogo y devuelve true si el usuario aceptó Y el registro fue exitoso.
  static Future<bool> show({
    required BuildContext context,
    required AiConsentConfig config,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AiConsentDialog._(config: config),
    );
    return result ?? false;
  }

  @override
  State<AiConsentDialog> createState() => _AiConsentDialogState();
}

class _AiConsentDialogState extends State<AiConsentDialog> {
  bool _loading = false;
  String? _error;

  static const _blue = Color(0xFF135BEC);
  static const _bgBlue = Color(0xFFEFF6FF);

  Future<void> _onAccept() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AiConsentService.instance.record(widget.config);
      if (mounted) Navigator.of(context).pop(true);
    } on AiConsentException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'ai_consent.error_generic'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _bgBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.privacy_tip_outlined,
                        color: _blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ai_consent.title'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _InfoRow(
                icon: Icons.bolt_outlined,
                label: 'ai_consent.action_label'.tr(),
                value: config.actionLabel,
              ),
              const SizedBox(height: 10),

              _InfoRow(
                icon: Icons.upload_outlined,
                label: 'ai_consent.data_sent_label'.tr(),
                value: config.dataCategories.map((c) => '• $c').join('\n'),
              ),
              const SizedBox(height: 10),

              _InfoRow(
                icon: Icons.smart_toy_outlined,
                label: 'ai_consent.ai_provider_label'.tr(),
                value: config.aiProvider,
              ),
              const SizedBox(height: 10),

              _InfoRow(
                icon: Icons.flag_outlined,
                label: 'ai_consent.purpose_label'.tr(),
                value: config.purpose,
              ),
              const SizedBox(height: 16),

              // Texto legal
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFBBF24)),
                ),
                child: Text(
                  'ai_consent.legal_warning'
                      .tr(namedArgs: {'provider': config.aiProvider}),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF92400E),
                    height: 1.5,
                  ),
                ),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          _error!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('ai_consent.cancel_btn'.tr()),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _loading ? null : _onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'ai_consent.accept_btn'.tr(),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
