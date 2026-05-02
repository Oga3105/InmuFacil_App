import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/currency_input_formatter.dart';
import '../../providers/offers_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
// import '../../widgets/offers/price_validator_widget.dart'; // DESHACER: kept for future use
// import '../../widgets/offers/market_gap_widget.dart'; // DESHACER: kept for future use

class MakeOfferScreen extends ConsumerStatefulWidget {
  const MakeOfferScreen({
    super.key,
    required this.propertyId,
    this.askingPrice = 0,
  });

  final String propertyId;
  final int askingPrice;

  @override
  ConsumerState<MakeOfferScreen> createState() => _MakeOfferScreenState();
}

class _MakeOfferScreenState extends ConsumerState<MakeOfferScreen> {
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  String _paymentTerm = 'cash';
  DateTime? _closingDate;
  bool _agreed = false;

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  int get _offerAmount =>
      CurrencyInputFormatter.parse(_amountController.text) ?? 0;

  double get _diffPct {
    if (widget.askingPrice <= 0 || _offerAmount <= 0) return 0;
    return ((_offerAmount - widget.askingPrice) / widget.askingPrice) * 100;
  }

  bool get _isLowOffer =>
      widget.askingPrice > 0 &&
      _offerAmount > 0 &&
      _offerAmount < widget.askingPrice * 0.97;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formState = ref.watch(makeOfferProvider);

    ref.listen<OfferFormState>(makeOfferProvider, (prev, next) {
      if (next.status == OfferSubmitStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('offers.success_snackbar'.tr()),
            backgroundColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
          ),
        );
        ref.read(makeOfferProvider.notifier).reset();
        context.pop();
      } else if (next.status == OfferSubmitStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'offers.error_snackbar'.tr()),
            backgroundColor: colorScheme.error,
          ),
        );
        ref.read(makeOfferProvider.notifier).reset();
      }
    });

    final properties = ref.watch(searchProvider).filteredProperties;
    final property = properties.where((p) => p.id == widget.propertyId).firstOrNull;

    final isLoading = formState.status == OfferSubmitStatus.loading;
    final canSubmit = _agreed && _offerAmount > 0 && !isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(onPressed: () => context.pop()),
        ),
        title: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_inmufacil.png', height: 28),
                const SizedBox(width: 8),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Inmu', style: TextStyle(color: colorScheme.primary)),
                      TextSpan(text: 'Fácil', style: TextStyle(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 650)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, size: 16, color: colorScheme.onPrimary),
                    const SizedBox(width: 5),
                    Text('common.home'.tr(), style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const UserAvatarMenu(),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                children: [
                  Text(
                    'offers.make_offer_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'offers.make_offer_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Property card ─────────────────────────────────────────
                  if (property != null) _PropertyCard(property: property),
                  if (property != null) const SizedBox(height: 20),

                  // ── Offer amount card ─────────────────────────────────────
                  _OfferAmountCard(
                    controller: _amountController,
                    isLowOffer: _isLowOffer,
                    diffPct: _diffPct,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // ── Payment + Date (side by side) ─────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Forma de Pago
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'offers.payment_method'.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _PaymentOption(
                              label: 'offers.cash_label'.tr(),
                              sublabel: 'offers.cash_subtitle'.tr(),
                              value: 'cash',
                              groupValue: _paymentTerm,
                              onChanged: (v) => setState(() => _paymentTerm = v),
                            ),
                            const SizedBox(height: 8),
                            _PaymentOption(
                              label: 'offers.mortgage_label'.tr(),
                              sublabel: 'offers.mortgage_subtitle'.tr(),
                              value: 'mortgage',
                              groupValue: _paymentTerm,
                              onChanged: (v) => setState(() => _paymentTerm = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Fecha escritura
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'offers.signing_date_label'.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().add(const Duration(days: 30)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 730)),
                                  );
                                  if (picked != null) setState(() => _closingDate = picked);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_month_outlined,
                                          size: 16, color: Colors.grey.shade500),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _closingDate != null
                                              ? '${_closingDate!.day.toString().padLeft(2, '0')}/'
                                                '${_closingDate!.month.toString().padLeft(2, '0')}/'
                                                '${_closingDate!.year}'
                                              : 'offers.date_placeholder'.tr(),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _closingDate != null
                                                ? colorScheme.onSurface
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'offers.signing_date_note'.tr(),
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Message to seller ─────────────────────────────────────
                  Text(
                    'offers.message_label'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'offers.message_hint'.tr(),
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Agreement checkbox ────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _agreed ? colorScheme.primary : colorScheme.outlineVariant,
                        width: _agreed ? 1.5 : 1,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      activeColor: colorScheme.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text(
                        'offers.binding_commitment'.tr(),
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Total + Submit (dark block) ───────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'offers.total_label'.tr(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.surface.withOpacity(0.6),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${CurrencyInputFormatter.format(_offerAmount)} €',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.surface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: canSubmit
                              ? () {
                                  ref.read(makeOfferProvider.notifier).submit(
                                    propertyId: widget.propertyId,
                                    amount: _offerAmount,
                                    conditions: _messageController.text.trim(),
                                    paymentTerm: _paymentTerm,
                                    closingDate: _closingDate,
                                  );
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.chevron_right_rounded, size: 20),
                          iconAlignment: IconAlignment.end,
                          label: Text(
                            'offers.send_offer'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Security badge ────────────────────────────────────────
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          Text(
                            'offers.protected_badge'.tr(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Legal disclaimer ──────────────────────────────────────
                  Text(
                    'offers.disclaimer_text'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 32),

                  // ── Footer ────────────────────────────────────────────────
                  const _Footer(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Property Card ─────────────────────────────────────────────────────────────

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});
  final dynamic property;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: property.images.isNotEmpty
                ? Image.network(property.images.first,
                    width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15, color: colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        property.address,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'offers.asking_price_label'.tr(),
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                      ),
                      TextSpan(
                        text: property.formattedPrice,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status + ID
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainer : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'offers.available_status'.tr(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ID: ${property.id.substring(0, property.id.length.clamp(0, 8)).toUpperCase()}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 64, height: 64,
        color: Colors.grey.shade100,
        child: const Icon(Icons.home_outlined, color: Color(0xFF94A3B8)),
      );
}

// ─── Offer Amount Card ─────────────────────────────────────────────────────────

class _OfferAmountCard extends StatelessWidget {
  const _OfferAmountCard({
    required this.controller,
    required this.isLowOffer,
    required this.diffPct,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isLowOffer;
  final double diffPct;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          Text(
            'offers.economic_proposal'.tr(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '€',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.outlineVariant,
                    ),
                    isCollapsed: true,
                    constraints: BoxConstraints(minWidth: 80),
                  ),
                ),
              ),
            ],
          ),
          if (isLowOffer) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainer : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 15, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Text(
                    'offers.low_offer_warning'.tr(args: [diffPct.abs().toStringAsFixed(0)]),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Payment Option ────────────────────────────────────────────────────────────

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String sublabel;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _selected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: _selected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  width: _selected ? 5 : 1.5,
                ),
                color: _selected ? colorScheme.primary : colorScheme.surface,
              ),
              child: _selected
                  ? Center(
                      child: Icon(Icons.circle, size: 6, color: colorScheme.onPrimary),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                    )),
                Text(sublabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: _selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 18, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Text('InmuFácil',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                )),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          children: [
            _FooterLink('offers.legal_notice'.tr()),
            _FooterLink('offers.privacy'.tr()),
            _FooterLink('offers.security_link'.tr()),
            _FooterLink('offers.help_link'.tr()),
          ],
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
      );
}
