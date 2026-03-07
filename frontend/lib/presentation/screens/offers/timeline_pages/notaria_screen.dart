import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/common/app_bar_back_button.dart';
import '../../../providers/offers_provider.dart';
import '../../../providers/auth_provider.dart';

const _kBlue  = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);

/// Pantalla de Notaria — comprador elige lugar, fecha y hora.
/// Muestra checklist de documentos obligatorios para entregar en notaria.
class NotariaScreen extends ConsumerStatefulWidget {
  const NotariaScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<NotariaScreen> createState() => _NotariaScreenState();
}

class _NotariaScreenState extends ConsumerState<NotariaScreen> {
  final _cityCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _confirmed = false;

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 15)),
      firstDate: DateTime.now().add(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _kBlue)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 11, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _kBlue)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _confirm() {
    if (_cityCtrl.text.isEmpty || _selectedDate == null || _selectedTime == null) return;
    setState(() => _confirmed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cita en notaria propuesta. Se notificara al vendedor.'),
        backgroundColor: _kGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isBuyer = currentUser?.id == widget.offer.buyerId;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBarBackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text(
          'Cita en Notaria',
          style: TextStyle(
              color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info
          _buildInfoBanner(),
          const SizedBox(height: 20),

          if (isBuyer && !_confirmed)
            _buildBuyerForm()
          else if (isBuyer && _confirmed)
            _buildConfirmedBanner()
          else
            _buildSellerView(),

          const SizedBox(height: 24),
          _buildDocumentChecklist(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kBlue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBlue.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_balance_outlined, color: _kBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Firma ante notario',
                    style: TextStyle(
                        color: _kBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'El comprador propone la fecha y el lugar de la notaria. '
                  'El vendedor confirma o propone una alternativa. '
                  'Ambas partes deben acudir con la documentacion completa.',
                  style: TextStyle(
                      color: _kBlue.withOpacity(0.85), fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Proponer cita notarial',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F))),
          const SizedBox(height: 16),
          // City field
          TextField(
            controller: _cityCtrl,
            decoration: InputDecoration(
              labelText: 'Ciudad / Notaria',
              hintText: 'Ej: Notaria Hernandez, Sevilla',
              prefixIcon: const Icon(Icons.location_on_outlined, color: _kBlue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kBlue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DatePickerRow(
            label: 'Fecha',
            value: _selectedDate != null
                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                : 'Seleccionar fecha',
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          _DatePickerRow(
            label: 'Hora',
            value: _selectedTime != null
                ? _selectedTime!.format(context)
                : 'Seleccionar hora',
            icon: Icons.access_time_outlined,
            onTap: _pickTime,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_cityCtrl.text.isNotEmpty &&
                      _selectedDate != null &&
                      _selectedTime != null)
                  ? _confirm
                  : null,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Proponer al vendedor'),
              style: FilledButton.styleFrom(
                backgroundColor: _kBlue,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmedBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: _kGreen, size: 40),
          const SizedBox(height: 12),
          const Text('Propuesta enviada',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: _kGreen)),
          const SizedBox(height: 6),
          Text(
            '${_cityCtrl.text}\n'
            '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
            ' a las ${_selectedTime!.format(context)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, color: Colors.orange.shade700, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Esperando propuesta del comprador',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'El comprador esta eligiendo la notaria y la fecha.',
                  style:
                      TextStyle(color: Colors.orange.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentChecklist() {
    const buyerDocs = [
      'DNI / NIE en vigor (original)',
      'Preaprobacion hipotecaria del banco',
      'Certificado de solvencia (si aplica)',
      'Poder notarial (si actua por tercero)',
    ];
    const sellerDocs = [
      'Escritura de propiedad original',
      'DNI / NIE en vigor (original)',
      'Ultimo recibo IBI pagado',
      'Certificado de estar al corriente en la comunidad',
      'Certificado energetico (CEE)',
      'Certificado de deuda cero de hipoteca (si aplica)',
      'Nota simple actualizada (no mas de 3 meses)',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentos para la firma',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
        ),
        const SizedBox(height: 16),
        _DocsSection(title: 'Comprador', icon: Icons.person_outline, docs: buyerDocs),
        const SizedBox(height: 12),
        _DocsSection(title: 'Vendedor', icon: Icons.home_outlined, docs: sellerDocs),
      ],
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: _kBlue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF1E3A5F))),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DocsSection extends StatelessWidget {
  const _DocsSection({required this.title, required this.icon, required this.docs});

  final String title;
  final IconData icon;
  final List<String> docs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _kBlue, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A5F))),
            ],
          ),
          const SizedBox(height: 12),
          ...docs.map((doc) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_box_outline_blank,
                        color: _kBlue, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(doc,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade700))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
