import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/visits_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';

class ScheduleVisitScreen extends ConsumerStatefulWidget {
  const ScheduleVisitScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<ScheduleVisitScreen> createState() =>
      _ScheduleVisitScreenState();
}

class _ScheduleVisitScreenState
    extends ConsumerState<ScheduleVisitScreen> {
  DateTime? _selectedDay;
  VisitSlot? _selectedSlot;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Map<DateTime, List<VisitSlot>> _groupSlotsByDay(
      List<VisitSlot> slots) {
    final map = <DateTime, List<VisitSlot>>{};
    for (final slot in slots) {
      final day = DateTime(
        slot.startTime.year,
        slot.startTime.month,
        slot.startTime.day,
      );
      map.putIfAbsent(day, () => []).add(slot);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync =
        ref.watch(slotsProvider(widget.propertyId));
    final bookingState = ref.watch(bookVisitProvider);

    // Listen for booking success
    ref.listen<BookingState>(bookVisitProvider, (prev, next) {
      if (next.status == BookingStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visita solicitada correctamente'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        ref.read(bookVisitProvider.notifier).reset();
        context.pop();
      } else if (next.status == BookingStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Error al reservar'),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(bookVisitProvider.notifier).reset();
      }
    });

    // Get property info
    final properties =
        ref.watch(searchProvider).filteredProperties;
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
          'Solicitar Visita',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: slotsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Color(0xFF64748B)),
              const SizedBox(height: 12),
              const Text('No hay horarios disponibles'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref
                    .invalidate(slotsProvider(widget.propertyId)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (slots) {
          final groupedSlots = _groupSlotsByDay(slots);
          final availableDays = groupedSlots.keys
              .where((day) =>
                  groupedSlots[day]!
                      .any((s) => s.isAvailable) &&
                  day.isAfter(
                      DateTime.now().subtract(const Duration(days: 1))))
              .toSet();

          final selectedDaySlots = _selectedDay != null
              ? (groupedSlots[_selectedDay] ?? [])
              : <VisitSlot>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Property card
                if (property != null)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8),
                            child: property.images.isNotEmpty
                                ? Image.network(
                                    property.images.first,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _placeholderImage(),
                                  )
                                : _placeholderImage(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF1E293B),
                                  ),
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  property.formattedPrice,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xFF2563EB),
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

                // Calendar section
                const Text(
                  'Selecciona un dia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                _CalendarWidget(
                  availableDays: availableDays,
                  selectedDay: _selectedDay,
                  onDaySelected: (day) {
                    setState(() {
                      _selectedDay = day;
                      _selectedSlot = null;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Time slots
                if (_selectedDay != null) ...[
                  const Text(
                    'Elige un horario',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedDaySlots.isEmpty)
                    Text(
                      'No hay horarios disponibles para este dia',
                      style: TextStyle(
                          color: Colors.grey.shade500),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedDaySlots.map((slot) {
                        final label =
                            '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}';
                        final isSelected =
                            _selectedSlot?.windowId ==
                                slot.windowId;
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: slot.isAvailable
                              ? (selected) {
                                  setState(() {
                                    _selectedSlot =
                                        selected ? slot : null;
                                  });
                                }
                              : null,
                          selectedColor:
                              const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : slot.isAvailable
                                    ? const Color(0xFF1E293B)
                                    : Colors.grey.shade400,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          backgroundColor: slot.isAvailable
                              ? Colors.white
                              : Colors.grey.shade100,
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : Colors.grey.shade300,
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),
                ],

                // Notes
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText:
                        'Nota para el vendedor (opcional)',
                    labelStyle: const TextStyle(
                        color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(bookingState),
    );
  }

  Widget _buildBottomBar(BookingState bookingState) {
    return Container(
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
          if (_selectedDay != null && _selectedSlot != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Visita: ${_formatDate(_selectedDay!)} a las ${_formatTime(_selectedSlot!.startTime)}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          FilledButton(
            onPressed: (_selectedSlot != null &&
                    bookingState.status !=
                        BookingStatus.loading)
                ? () {
                    ref
                        .read(bookVisitProvider.notifier)
                        .bookSlot(
                          windowId: _selectedSlot!.windowId,
                          startTime: _selectedSlot!.startTime,
                          notes: _notesController.text.trim(),
                        );
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: bookingState.status == BookingStatus.loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Confirmar Solicitud',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade200,
      child: const Icon(Icons.home_outlined,
          color: Color(0xFF64748B)),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// --- Simple Calendar Widget ---

class _CalendarWidget extends StatefulWidget {
  const _CalendarWidget({
    required this.availableDays,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final Set<DateTime> availableDays;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<_CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<_CalendarWidget> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final firstDay =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0)
            .day;
    final startWeekday = firstDay.weekday % 7;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month - 1);
                  }),
                  icon: const Icon(Icons.chevron_left),
                  color: const Color(0xFF64748B),
                ),
                Text(
                  _monthName(_focusedMonth.month) +
                      ' ${_focusedMonth.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month + 1);
                  }),
                  icon: const Icon(Icons.chevron_right),
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
            // Day headers
            Row(
              children: ['D', 'L', 'M', 'X', 'J', 'V', 'S']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            // Days grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: startWeekday + daysInMonth,
              itemBuilder: (context, index) {
                if (index < startWeekday) return const SizedBox();
                final day = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  index - startWeekday + 1,
                );
                final isAvailable = widget.availableDays
                    .any((d) => _sameDay(d, day));
                final isSelected = widget.selectedDay != null &&
                    _sameDay(widget.selectedDay!, day);
                final isPast = day.isBefore(
                    DateTime.now().subtract(const Duration(days: 1)));

                return GestureDetector(
                  onTap: isAvailable && !isPast
                      ? () => widget.onDaySelected(day)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : isAvailable && !isPast
                              ? Colors.white
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isAvailable && !isPast && !isSelected
                          ? Border.all(
                              color: const Color(0xFF2563EB),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : isPast || !isAvailable
                                  ? Colors.grey.shade300
                                  : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthName(int month) {
    const names = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo',
      'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre',
      'Noviembre', 'Diciembre'
    ];
    return names[month];
  }
}
