import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/visits_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

class ManageVisitsScreen extends ConsumerStatefulWidget {
  const ManageVisitsScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<ManageVisitsScreen> createState() => _ManageVisitsScreenState();
}

class _ManageVisitsScreenState extends ConsumerState<ManageVisitsScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 14, minute: 0);
  int _slotDuration = 20;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final windowsAsync = ref.watch(sellerWindowsProvider(widget.propertyId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        title: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_inmufacil.png', height: 32),
                const SizedBox(width: 8),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(
                          text: 'Inmu',
                          style: TextStyle(color: Color(0xFF135BEC))),
                      TextSpan(
                          text: 'Facil',
                          style: TextStyle(color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
        actions: [
          Builder(builder: (context) {
            final isMobile = MediaQuery.of(context).size.width < 650;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMobile) ...[
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.go('/'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF135BEC),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF135BEC).withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home_rounded, size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text('common.home'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                const UserAvatarMenu(),
                const SizedBox(width: 16),
              ],
            );
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Create new window ────────────────────────────────────
            _buildCreateCard(context),
            const SizedBox(height: 24),

            // ── Existing windows ─────────────────────────────────────
            const Text(
              'VENTANAS CONFIGURADAS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            windowsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => _buildInfoCard(
                icon: Icons.error_outline,
                color: Colors.red,
                text: 'Error al cargar las ventanas de visita',
              ),
              data: (windows) {
                if (windows.isEmpty) {
                  return _buildInfoCard(
                    icon: Icons.event_busy_outlined,
                    color: const Color(0xFFF97316),
                    text: 'No tienes ventanas de visita configuradas.\n'
                        'Los compradores no podran reservar citas hasta que crees al menos una.',
                  );
                }
                return Column(
                  children: windows.map((w) => _buildWindowCard(w)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_circle_outline,
                    size: 18, color: Color(0xFF135BEC)),
              ),
              const SizedBox(width: 10),
              const Text(
                'Crear nueva ventana de disponibilidad',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Define un bloque de horas en el que los compradores podran reservar visitas de ${_slotDuration} minutos.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 20),

          // Date picker
          _buildPickerRow(
            icon: Icons.calendar_today_outlined,
            label: 'Fecha',
            value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          const SizedBox(height: 12),

          // Start time
          Row(
            children: [
              Expanded(
                child: _buildPickerRow(
                  icon: Icons.access_time,
                  label: 'Hora inicio',
                  value: _formatTime(_startTime),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (picked != null) setState(() => _startTime = picked);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPickerRow(
                  icon: Icons.access_time,
                  label: 'Hora fin',
                  value: _formatTime(_endTime),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (picked != null) setState(() => _endTime = picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slot duration
          _buildPickerRow(
            icon: Icons.timelapse_outlined,
            label: 'Duracion por cita',
            value: '$_slotDuration min',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => SimpleDialog(
                  title: Text('property.visit_duration_label'.tr()),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  children: [15, 20, 30, 45, 60].map((min) {
                    return SimpleDialogOption(
                      onPressed: () {
                        setState(() => _slotDuration = min);
                        Navigator.pop(context);
                      },
                      child: Text('visits.minutes_label'.tr(namedArgs: {'min': min.toString()}),
                          style: TextStyle(
                            fontWeight: _slotDuration == min ? FontWeight.w700 : FontWeight.normal,
                            color: _slotDuration == min ? const Color(0xFF135BEC) : null,
                          )),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Preview
          _buildPreview(),
          const SizedBox(height: 16),

          // Create button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isCreating ? null : _onCreate,
              icon: _isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _isCreating ? 'Creando...' : 'Crear ventana de disponibilidad',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    final totalMinutes = end.difference(start).inMinutes;
    final slotCount = totalMinutes > 0 ? totalMinutes ~/ _slotDuration : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF16A34A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              slotCount > 0
                  ? 'Se crearan $slotCount citas de $_slotDuration min '
                    '(${_formatTime(_startTime)} - ${_formatTime(_endTime)})'
                  : 'La hora de fin debe ser posterior a la de inicio',
              style: TextStyle(
                fontSize: 13,
                color: slotCount > 0 ? const Color(0xFF166534) : Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onCreate() async {
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('property.visit_window_end_error'.tr()),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isCreating = true);
    final ok = await createVisitWindow(
      propertyId: int.tryParse(widget.propertyId) ?? 0,
      startTime: start,
      endTime: end,
      slotDurationMinutes: _slotDuration,
    );
    setState(() => _isCreating = false);

    if (ok) {
      ref.invalidate(sellerWindowsProvider(widget.propertyId));
      ref.invalidate(slotsProvider(widget.propertyId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('property.visit_window_created'.tr()),
          backgroundColor: Color(0xFF16A34A),
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('property.visit_window_error'.tr()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Widget _buildPickerRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowCard(VisitWindow w) {
    final dayNames = ['', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final monthNames = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    final day = dayNames[w.startTime.weekday];
    final month = monthNames[w.startTime.month];
    final startH = '${w.startTime.hour.toString().padLeft(2, '0')}:${w.startTime.minute.toString().padLeft(2, '0')}';
    final endH = '${w.endTime.hour.toString().padLeft(2, '0')}:${w.endTime.minute.toString().padLeft(2, '0')}';
    final isPast = w.endTime.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isPast ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPast ? Colors.grey.shade200 : Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPast ? Colors.grey.shade100 : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${w.startTime.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isPast ? Colors.grey : const Color(0xFF135BEC),
                  ),
                ),
                Text(
                  '$day $month',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isPast ? Colors.grey : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$startH - $endH',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isPast ? Colors.grey : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Citas de ${w.slotDurationMinutes} min',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (isPast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('property.visit_past'.tr(),
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('property.visit_active'.tr(),
                  style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
