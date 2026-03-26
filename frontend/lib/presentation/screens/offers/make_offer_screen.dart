import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/currency_input_formatter.dart';
import '../../providers/offers_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

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
    final formState = ref.watch(makeOfferProvider);

    ref.listen<OfferFormState>(makeOfferProvider, (prev, next) {
      if (next.status == OfferSubmitStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oferta enviada correctamente'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        ref.read(makeOfferProvider.notifier).reset();
        context.pop();
      } else if (next.status == OfferSubmitStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Error al enviar oferta'),
            backgroundColor: Colors.red,
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
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF2563EB))),
                      TextSpan(text: 'Fácil', style: TextStyle(color: Color(0xFF16A34A))),
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
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text('Inicio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                children: [
                  Text(
                    'Hacer una Oferta Formal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Envía una propuesta vinculante al vendedor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
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
                            const Text(
                              'Forma de Pago',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _PaymentOption(
                              label: 'Al contado',
                              sublabel: 'Fondos propios disponibles',
                              value: 'cash',
                              groupValue: _paymentTerm,
                              onChanged: (v) => setState(() => _paymentTerm = v),
                            ),
                            const SizedBox(height: 8),
                            _PaymentOption(
                              label: 'Necesito Hipoteca',
                              sublabel: 'Pendiente de aprobación bancaria',
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
                            const Text(
                              'Fecha deseada de escritura',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
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
                                              : 'dd/mm/aaaa',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _closingDate != null
                                                ? const Color(0xFF1E293B)
                                                : Colors.grey.shade400,
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
                              'La fecha final será acordada de mutuo acuerdo ante notario.',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Message to seller ─────────────────────────────────────
                  const Text(
                    'Mensaje al vendedor (opcional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'Añade algún detalle que quieras comentar al propietario...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
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
                        color: _agreed ? const Color(0xFF2563EB) : Colors.grey.shade300,
                        width: _agreed ? 1.5 : 1,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      activeColor: const Color(0xFF2563EB),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: const Text(
                        'Entiendo que esta oferta es un compromiso serio de compra y estoy dispuesto a formalizarla mediante contrato de arras.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Total + Submit (dark block) ───────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'OFERTA TOTAL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${CurrencyInputFormatter.format(_offerAmount)} €',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
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
                            backgroundColor: const Color(0xFF2563EB),
                            disabledBackgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.5),
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
                          label: const Text(
                            'Enviar Oferta Formal',
                            style: TextStyle(
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: Color(0xFF16A34A)),
                          SizedBox(width: 6),
                          Text(
                            'OFERTA PROTEGIDA POR INMUFÁCIL SECURE TECH',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
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
                    'Al enviar esta oferta, la plataforma notificará instantáneamente al vendedor. Sus datos personales están protegidos por el RGPD y sólo se compartirán tras la aceptación de la oferta para los trámites legales correspondientes.',
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B)),
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
                      const TextSpan(
                        text: 'Precio de salida:  ',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      TextSpan(
                        text: property.formattedPrice,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
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
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DISPONIBLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const Text(
            'TU PROPUESTA ECONÓMICA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '€',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF94A3B8),
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
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFCBD5E1),
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
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 15, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Text(
                    'Tu oferta es un ${diffPct.abs().toStringAsFixed(0)}% inferior al precio de salida',
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
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _selected ? const Color(0xFF2563EB) : Colors.grey.shade300,
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
                  color: _selected ? const Color(0xFF2563EB) : Colors.grey.shade400,
                  width: _selected ? 5 : 1.5,
                ),
                color: _selected ? const Color(0xFF2563EB) : Colors.white,
              ),
              child: _selected
                  ? const Center(
                      child: Icon(Icons.circle, size: 6, color: Colors.white),
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
                      color: _selected ? const Color(0xFF1E40AF) : const Color(0xFF1E293B),
                    )),
                Text(sublabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: _selected ? const Color(0xFF3B82F6) : Colors.grey.shade500,
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
            _FooterLink('Aviso Legal'),
            _FooterLink('Privacidad'),
            _FooterLink('Seguridad'),
            _FooterLink('Ayuda'),
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
