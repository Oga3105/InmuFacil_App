import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatters/currency_input_formatter.dart';

import 'package:easy_localization/easy_localization.dart';
import '../../../providers/property_form_provider.dart';
import '../../../widgets/property/market_price_widget.dart';
import 'property_condition_selector.dart';

class PropertyStep2DetailsPrice extends ConsumerStatefulWidget {
  const PropertyStep2DetailsPrice({super.key});

  @override
  ConsumerState<PropertyStep2DetailsPrice> createState() =>
      _PropertyStep2DetailsPriceState();
}

class _PropertyStep2DetailsPriceState
    extends ConsumerState<PropertyStep2DetailsPrice> {
  late final TextEditingController _priceCtrl;
  late final TextEditingController _surfaceCtrl;
  late final TextEditingController _titleCtrl;

  final _priceFocus = FocusNode();
  final _surfaceFocus = FocusNode();
  final _titleFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final s = ref.read(propertyFormProvider);
    _priceCtrl = TextEditingController(text: s.priceText);
    _surfaceCtrl = TextEditingController(text: s.surfaceText);
    _titleCtrl = TextEditingController(text: s.titleText);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _surfaceCtrl.dispose();
    _titleCtrl.dispose();
    _priceFocus.dispose();
    _surfaceFocus.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _sync(TextEditingController ctrl, FocusNode focus, String value) {
    if (!focus.hasFocus && ctrl.text != value) {
      ctrl.text = value;
    }
  }

  InputDecoration _inputDec(String hint, {String? suffixSymbol}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        suffixIcon: suffixSymbol != null
            ? Builder(
                builder: (context) {
                  final cs = Theme.of(context).colorScheme;
                  return Container(
                    width: 44,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        suffixSymbol,
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(propertyFormProvider);
    final notifier = ref.read(propertyFormProvider.notifier);
    final cursorColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1E293B);

    _sync(_priceCtrl, _priceFocus, s.priceText);
    _sync(_surfaceCtrl, _surfaceFocus, s.surfaceText);
    _sync(_titleCtrl, _titleFocus, s.titleText);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Detalles y Precio card ────────────────────────────────────────
          _SectionCard(
            icon: Icons.payments_outlined,
            title: 'property_wizard.details_card'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price & Surface
                Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'property_wizard.price_label'.tr(),
                        child: TextField(
                          controller: _priceCtrl,
                          focusNode: _priceFocus,
                          cursorColor: cursorColor,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          decoration: _inputDec('0', suffixSymbol: '€'),
                          onChanged: notifier.setPrice,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _LabeledField(
                        label: 'property_wizard.surface_label'.tr(),
                        child: TextField(
                          controller: _surfaceCtrl,
                          focusNode: _surfaceFocus,
                          cursorColor: cursorColor,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'))
                          ],
                          decoration: _inputDec('0', suffixSymbol: 'm²'),
                          onChanged: notifier.setSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                // ── Market price hint ──────────────────────────
                _MarketPriceHint(
                  postalCode: s.postalCodeText,
                  surfaceText: s.surfaceText,
                  propertyType: s.selectedType?.backendValue ?? 'piso',
                ),
                const SizedBox(height: 16),
                // Bedrooms & Bathrooms (label inline)
                Row(
                  children: [
                    Expanded(
                      child: _CounterRow(
                        label: 'property_wizard.bedrooms_label'.tr(),
                        value: s.bedrooms,
                        onDecrement: notifier.decrementBedrooms,
                        onIncrement: notifier.incrementBedrooms,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _CounterRow(
                        label: 'property_wizard.bathrooms_label'.tr(),
                        value: s.bathrooms,
                        onDecrement: notifier.decrementBathrooms,
                        onIncrement: notifier.incrementBathrooms,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Titulo card ───────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.title_outlined,
            title: 'property_wizard.description_card'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LabeledField(
                  label: 'property_wizard.title_label'.tr(),
                  child: TextField(
                    controller: _titleCtrl,
                    focusNode: _titleFocus,
                    cursorColor: cursorColor,
                    maxLength: 100,
                    decoration:
                        _inputDec('property_wizard.title_hint'.tr()),
                    onChanged: notifier.setTitle,
                  ),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final greenColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
                    final bgColor = isDark ? Theme.of(context).colorScheme.surfaceContainer : const Color(0xFFF0FDF4);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: greenColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, color: greenColor, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'property_wizard.title_ai_hint'.tr(),
                              style: TextStyle(fontSize: 12, color: greenColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Estado del Inmueble card ───────────────────────────────────────
          _SectionCard(
            icon: Icons.home_repair_service_outlined,
            title: 'property_wizard.condition_title'.tr(),
            child: PropertyConditionSelector(
              selected: s.propertyCondition,
              onSelected: (condition) {
                ref.read(propertyFormProvider.notifier).setPropertyCondition(condition);
              },
            ),
          ),

          // ── Validation error ──────────────────────────────────────────────
          if (s.step2Error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: s.step2Error!),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Supporting widgets ──────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          child,
        ],
      );
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });
  final String label;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          _CircleButton(
            icon: Icons.remove,
            onPressed: onDecrement,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '$value',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          _CircleButton(
            icon: Icons.add,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatefulWidget {
  const _CircleButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _pressed ? cs.primary : cs.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: _pressed ? cs.primary : cs.outlineVariant,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _pressed ? cs.onPrimary : cs.onSurface,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Market price suggestion hint — subtle, informational
// Shows a price range based on market data when postal code + surface exist
// ---------------------------------------------------------------------------

class _MarketPriceHint extends ConsumerWidget {
  const _MarketPriceHint({
    required this.postalCode,
    required this.surfaceText,
    required this.propertyType,
  });

  final String postalCode;
  final String surfaceText;
  final String propertyType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = double.tryParse(surfaceText.replaceAll(',', '.'));
    if (postalCode.length != 5 || surface == null || surface <= 0) {
      return const SizedBox.shrink();
    }

    final args = MarketPriceArgs(
      postalCode: postalCode,
      surfaceArea: surface,
      propertyType: propertyType,
    );
    final async = ref.watch(marketPriceProvider(args));

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        if (result.pricePerM2 <= 0 || result.lowDensity) {
          return const SizedBox.shrink();
        }

        final totalEstimate = result.pricePerM2 * surface.round();
        final low = (totalEstimate * 0.85).round();
        final high = (totalEstimate * 1.15).round();
        final lowStr = CurrencyInputFormatter.format(low);
        final highStr = CurrencyInputFormatter.format(high);
        final ppm2Str = CurrencyInputFormatter.format(result.pricePerM2);

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: Colors.blue.shade300),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.4),
                      children: [
                        TextSpan(
                          text: 'property_wizard.market_ref'.tr(),
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                        TextSpan(text: '$lowStr - $highStr EUR '),
                        TextSpan(
                          text: 'property_wizard.market_ref_detail'.tr(args: [ppm2Str, result.zoneLabel]),
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.error),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: cs.error, fontSize: 13)),
            ),
          ],
        ),
      );
  }
}
