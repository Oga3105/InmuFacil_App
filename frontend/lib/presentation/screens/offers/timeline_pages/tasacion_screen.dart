import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/common/app_bar_back_button.dart';
import '../../../providers/offers_provider.dart';
import '../../../providers/auth_provider.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBlue  = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);

/// Pantalla de Tasacion — solo disponible para ofertas con hipoteca.
/// El vendedor acuerda una cita para que el tasador visite la propiedad.
class TasacionScreen extends ConsumerStatefulWidget {
  const TasacionScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<TasacionScreen> createState() => _TasacionScreenState();
}

class _TasacionScreenState extends ConsumerState<TasacionScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _notesCtrl = TextEditingController();
  bool _confirmed       = false;
  bool _reportConfirmed = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _confirmAppointment() {
    if (_selectedDate == null || _selectedTime == null) return;
    setState(() => _confirmed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cita de tasacion confirmada. Se notificara a ambas partes.'),
        backgroundColor: _kGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isSeller = currentUser?.id != widget.offer.buyerId;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBarBackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text(
          'Tasacion de la Vivienda',
          style: TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info card
          _InfoCard(
            icon: Icons.assessment_outlined,
            color: _kBlue,
            title: 'Para que sirve la tasacion?',
            body:
                'El banco necesita una tasacion oficial para conceder la hipoteca. '
                'El tasador visitara la propiedad y emitira un informe de valor de mercado. '
                'El coste corre a cargo del comprador (aprox. 300-500 EUR).',
          ),
          const SizedBox(height: 20),

          if (!_confirmed) ...[
            // Role-specific content
            if (isSeller)
              _TaskCard(
                title: 'Agendar visita del tasador',
                subtitle: 'Elige fecha y hora para que el tasador acceda a la vivienda',
                child: Column(
                  children: [
                    _DateTimeRow(
                      label: 'Fecha',
                      value: _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Seleccionar',
                      icon: Icons.calendar_today_outlined,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 12),
                    _DateTimeRow(
                      label: 'Hora',
                      value: _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Seleccionar',
                      icon: Icons.access_time_outlined,
                      onTap: _pickTime,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notas para el tasador (opcional)',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: (_selectedDate != null && _selectedTime != null)
                            ? _confirmAppointment
                            : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Confirmar cita'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _kGreen,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              _InfoCard(
                icon: Icons.hourglass_empty_outlined,
                color: Colors.orange,
                title: 'Esperando al vendedor',
                body:
                    'El vendedor esta coordinando la cita con el tasador. '
                    'Recibiras una notificacion cuando la fecha este confirmada.',
              ),
          ] else
            _ConfirmedCard(
              date: _selectedDate!,
              time: _selectedTime!,
            ),

          const SizedBox(height: 20),
          // Checklist
          _ChecklistCard(
            title: 'Que necesitas preparar',
            items: const [
              'Acceso libre a todas las estancias',
              'Documentacion de la propiedad disponible',
              'Nota simple actualizada',
              'Plano de la vivienda si dispones de el',
            ],
          ),
          if (_confirmed) ...[
            const SizedBox(height: 20),
            _buildReportConfirmationSection(context, isSeller),
          ],
        ],
      ),
    );
  }

  Widget _buildReportConfirmationSection(BuildContext context, bool isSeller) {
    if (_reportConfirmed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kGreen.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: _kGreen, size: 36),
            const SizedBox(height: 8),
            const Text(
              'Tasacion completada',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: _kGreen, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Siguiente paso: Formalizacion Bancaria (FEIN).',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(
                  '/offers/${widget.offer.id}/fein',
                  extra: widget.offer,
                ),
                icon: const Icon(Icons.account_balance_outlined),
                label: const Text('Ir a Formalizacion Bancaria'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assessment_outlined, color: _kBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Confirmar visita del tasador',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSeller
                ? 'Una vez el tasador haya visitado la vivienda y '
                  'emitido el informe, confirma que la tasacion ha concluido.'
                : 'El vendedor confirmara cuando el tasador haya completado la visita '
                  'y el informe este en poder del banco.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
          if (isSeller) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => setState(() => _reportConfirmed = true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('El tasador ha visitado la vivienda'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(
                        color: color.withOpacity(0.85),
                        fontSize: 13,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
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
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E3A5F))),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ConfirmedCard extends StatelessWidget {
  const _ConfirmedCard({required this.date, required this.time});

  final DateTime date;
  final TimeOfDay time;

  @override
  Widget build(BuildContext context) {
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
          const Text('Cita confirmada',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: _kGreen)),
          const SizedBox(height: 8),
          Text(
            '${date.day}/${date.month}/${date.year} a las ${time.format(context)}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: _kGreen, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item,
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
