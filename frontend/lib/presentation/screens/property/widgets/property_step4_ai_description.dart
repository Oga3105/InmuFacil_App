import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/property_form_provider.dart';
import '../../../../core/services/ai_consent_service.dart';
import '../../../widgets/ai/ai_consent_dialog.dart';

class PropertyStep4AiDescription extends ConsumerStatefulWidget {
  const PropertyStep4AiDescription({super.key});

  @override
  ConsumerState<PropertyStep4AiDescription> createState() =>
      _PropertyStep4AiDescriptionState();
}

class _PropertyStep4AiDescriptionState
    extends ConsumerState<PropertyStep4AiDescription> {
  late final TextEditingController _descCtrl;
  final _descFocus = FocusNode();

  static const _blue = Color(0xFF135BEC);
  static const _green = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    final s = ref.read(propertyFormProvider);
    _descCtrl = TextEditingController(text: s.descriptionText);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  void _syncDesc(String value) {
    if (!_descFocus.hasFocus && _descCtrl.text != value) {
      _descCtrl.text = value;
      _descCtrl.selection =
          TextSelection.collapsed(offset: _descCtrl.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(propertyFormProvider);
    final notifier = ref.read(propertyFormProvider.notifier);
    final isGenerating = s.isGeneratingAiDescription;
    final hasImages = s.visibleMedia.isNotEmpty;

    _syncDesc(s.descriptionText);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Description card ───────────────────────────────────────────────
          Builder(builder: (context) {
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
                // Header: icon + title + AI button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.description_outlined,
                          color: colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Descripcion del inmueble',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: isGenerating
                          ? null
                          : () async {
                              final accepted = await AiConsentDialog.show(
                                context: context,
                                config: AiConsentConfig.propertyDescription,
                              );
                              if (accepted && context.mounted) {
                                notifier.generateAiDescription();
                              }
                            },
                      icon: const Icon(Icons.auto_awesome, size: 15),
                      label: Text(
                        isGenerating ? 'Generando...' : 'Generar con IA',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _blue.withOpacity(0.5),
                        disabledForegroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                // Loading indicator
                if (isGenerating) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      backgroundColor: Color(0xFFDCFCE7),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_green),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasImages
                        ? 'La IA esta analizando datos e imagenes...'
                        : 'La IA esta generando la descripcion...',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Text field
                TextField(
                  controller: _descCtrl,
                  focusNode: _descFocus,
                  maxLines: 12,
                  maxLength: 10000,
                  enabled: !isGenerating,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Escribe aqui un borrador o pulsa "Generar con IA" para obtener una descripcion comercial profesional. El texto generado es totalmente editable.',
                    hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: colorScheme.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    filled: isGenerating,
                    fillColor: isGenerating
                        ? colorScheme.surfaceContainerHighest
                        : null,
                  ),
                  onChanged: notifier.setDescription,
                ),

                // Character counter hint
                if (s.descriptionText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${s.descriptionText.length} / 10000 caracteres',
                      style: TextStyle(
                        fontSize: 11,
                        color: s.descriptionText.length < 20
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          );
          }),

          // ── Error banner ───────────────────────────────────────────────────
          if (s.step4Error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: s.step4Error!),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.error.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                color: colorScheme.onErrorContainer, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                    color: colorScheme.onErrorContainer, fontSize: 13),
              ),
            ),
          ],
        ),
      );
  }
}
