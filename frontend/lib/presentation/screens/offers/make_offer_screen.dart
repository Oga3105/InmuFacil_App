import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/offers_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';

class MakeOfferScreen extends ConsumerStatefulWidget {
  const MakeOfferScreen({
    super.key,
    required this.propertyId,
    this.askingPrice = 0,
  });

  final String propertyId;
  final double askingPrice;

  @override
  ConsumerState<MakeOfferScreen> createState() =>
      _MakeOfferScreenState();
}

class _MakeOfferScreenState extends ConsumerState<MakeOfferScreen> {
  final _amountController = TextEditingController();
  final _conditionsController = TextEditingController();
  String _paymentTerm = 'cash';
  DateTime? _closingDate;
  bool _agreed = false;

  @override
  void dispose() {
    _amountController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  double get _offerAmount =>
      double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

  bool get _isLowOffer =>
      widget.askingPrice > 0 && _offerAmount > 0 && _offerAmount < widget.askingPrice * 0.9;

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
    final property = properties
        .where((p) => p.id == widget.propertyId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(
            onPressed: () => context.pop(),
          ),
        ),
        title: const Text(
          'Hacer una Oferta',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Property summary card
            if (property != null)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: property.images.isNotEmpty
                            ? Image.network(
                                property.images.first,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholder64(),
                              )
                            : _placeholder64(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              property.address,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Precio de salida: ${property.formattedPrice}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Offer amount
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu oferta',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '\u20AC',
                          style: TextStyle(
                            fontSize: 28,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isLowOffer) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 16,
                                color: Color(0xFFF59E0B)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Las ofertas muy bajas tienen menos probabilidades de ser aceptadas',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment terms
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Forma de pago',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text('Al contado / Transferencia'),
                      value: 'cash',
                      groupValue: _paymentTerm,
                      onChanged: (v) =>
                          setState(() => _paymentTerm = v!),
                      activeColor: const Color(0xFF2563EB),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('Necesito hipoteca'),
                      value: 'mortgage',
                      groupValue: _paymentTerm,
                      onChanged: (v) =>
                          setState(() => _paymentTerm = v!),
                      activeColor: const Color(0xFF2563EB),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Closing date
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF2563EB),
                ),
                title: const Text('Fecha deseada de escritura'),
                subtitle: Text(
                  _closingDate != null
                      ? '${_closingDate!.day}/${_closingDate!.month}/${_closingDate!.year}'
                      : 'Seleccionar fecha',
                  style: TextStyle(
                    color: _closingDate != null
                        ? const Color(0xFF1E293B)
                        : Colors.grey.shade400,
                  ),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now()
                        .add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 730)),
                  );
                  if (picked != null) {
                    setState(() => _closingDate = picked);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Message to seller
            TextField(
              controller: _conditionsController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Mensaje para el vendedor (opcional)',
                labelStyle:
                    const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Agreement checkbox
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _agreed
                      ? const Color(0xFF2563EB)
                      : Colors.grey.shade200,
                ),
              ),
              child: CheckboxListTile(
                value: _agreed,
                onChanged: (v) =>
                    setState(() => _agreed = v ?? false),
                activeColor: const Color(0xFF2563EB),
                title: const Text(
                  'Entiendo que esta oferta es un compromiso serio de compra',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_offerAmount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Oferta Total: \u20AC${_offerAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: (_agreed &&
                      _offerAmount > 0 &&
                      formState.status !=
                          OfferSubmitStatus.loading)
                  ? () {
                      ref.read(makeOfferProvider.notifier).submit(
                        propertyId: widget.propertyId,
                        amount: _offerAmount,
                        conditions: _conditionsController.text.trim(),
                        paymentTerm: _paymentTerm,
                        closingDate: _closingDate,
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: formState.status == OfferSubmitStatus.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Enviar Oferta Formal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder64() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey.shade200,
      child: const Icon(Icons.home_outlined, color: Color(0xFF64748B)),
    );
  }
}
