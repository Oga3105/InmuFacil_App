import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/visits_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

class ScheduleVisitScreen extends ConsumerStatefulWidget {
  const ScheduleVisitScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<ScheduleVisitScreen> createState() =>
      _ScheduleVisitScreenState();
}

class _ScheduleVisitScreenState extends ConsumerState<ScheduleVisitScreen> {
  DateTime? _selectedDay;
  VisitSlot? _selectedSlot;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Map<DateTime, List<VisitSlot>> _groupSlotsByDay(List<VisitSlot> slots) {
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
    final slotsAsync = ref.watch(slotsProvider(widget.propertyId));
    final bookingState = ref.watch(bookVisitProvider);
    final activeVisitAsync = ref.watch(activeVisitForPropertyProvider(widget.propertyId));
    final property = ref
        .watch(searchProvider)
        .filteredProperties
        .where((p) => p.id == widget.propertyId)
        .firstOrNull;

    ref.listen<BookingState>(bookVisitProvider, (_, next) {
      if (next.status == BookingStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Visita solicitada correctamente'),
          backgroundColor: Color(0xFF16A34A),
        ));
        ref.read(bookVisitProvider.notifier).reset();
        ref.invalidate(activeVisitForPropertyProvider(widget.propertyId));
        context.pop();
      } else if (next.status == BookingStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage ?? 'Error al reservar'),
          backgroundColor: Colors.red,
        ));
        ref.read(bookVisitProvider.notifier).reset();
      }
    });

    // Guard: if buyer already has an active visit for this property
    final activeVisit = activeVisitAsync.value;
    if (activeVisit != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildAppBar(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.event_available, size: 32, color: Color(0xFF135BEC)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ya tienes una visita agendada para esta propiedad',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estado: ${activeVisit.status == "requested" ? "Pendiente de confirmacion" : "Confirmada"}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  '${activeVisit.startTime.day}/${activeVisit.startTime.month}/${activeVisit.startTime.year} a las ${activeVisit.startTime.hour.toString().padLeft(2, '0')}:${activeVisit.startTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF135BEC)),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/profile?tab=3'),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Ver mis visitas'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: slotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildEmptyState(),
        data: (slots) {
          // If no slots at all, show email request fallback
          if (slots.isEmpty) {
            return _NoSlotsEmailRequest(
              property: property,
              propertyId: widget.propertyId,
            );
          }

          final grouped = _groupSlotsByDay(slots);
          final availableDays = grouped.keys
              .where((d) =>
                  grouped[d]!.any((s) => s.isAvailable) &&
                  d.isAfter(DateTime.now().subtract(const Duration(days: 1))))
              .toSet();
          final daySlots = _selectedDay != null
              ? (grouped[_selectedDay] ?? <VisitSlot>[])
              : <VisitSlot>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Property card ──────────────────────────────────────
                _PropertyCard(property: property),
                const SizedBox(height: 16),

                // ── Calendar + time slots ──────────────────────────────
                _DateTimeCard(
                  availableDays: availableDays,
                  selectedDay: _selectedDay,
                  daySlots: daySlots,
                  selectedSlot: _selectedSlot,
                  onDaySelected: (day) => setState(() {
                    _selectedDay = day;
                    _selectedSlot = null;
                  }),
                  onSlotSelected: (slot) =>
                      setState(() => _selectedSlot = slot),
                ),
                const SizedBox(height: 16),

                // ── Notes ──────────────────────────────────────────────
                _NotesField(controller: _notesController),
                const SizedBox(height: 16),

                // ── Trust banner ───────────────────────────────────────
                const _TrustBanner(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _BottomBar(
        selectedDay: _selectedDay,
        selectedSlot: _selectedSlot,
        bookingState: bookingState,
        onConfirm: () => ref.read(bookVisitProvider.notifier).bookSlot(
              windowId: _selectedSlot!.windowId,
              startTime: _selectedSlot!.startTime,
              notes: _notesController.text.trim(),
            ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBarBackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
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
                    TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF135BEC))),
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
                color: const Color(0xFF135BEC),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF135BEC).withOpacity(0.25),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No hay horarios disponibles',
              style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                ref.invalidate(slotsProvider(widget.propertyId)),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Property summary card
// ─────────────────────────────────────────────────────────────────────────────

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final dynamic property; // Property entity, nullable

  @override
  Widget build(BuildContext context) {
    if (property == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: property.images.isNotEmpty
                ? Image.network(
                    property.images.first,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 14),
          // Info
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
                const SizedBox(height: 4),
                Text(
                  property.formattedPrice,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Color(0xFF135BEC),
                  ),
                ),
                if (property.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property.address,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Verified badge
          if (property.isVerified == true)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified,
                      size: 13, color: Color(0xFF16A34A)),
                  SizedBox(width: 3),
                  Text(
                    'Verificado',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.home_outlined,
            size: 32, color: Colors.grey.shade400),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Date + time card (calendar left, slots right)
// ─────────────────────────────────────────────────────────────────────────────

class _DateTimeCard extends StatelessWidget {
  const _DateTimeCard({
    required this.availableDays,
    required this.selectedDay,
    required this.daySlots,
    required this.selectedSlot,
    required this.onDaySelected,
    required this.onSlotSelected,
  });

  final Set<DateTime> availableDays;
  final DateTime? selectedDay;
  final List<VisitSlot> daySlots;
  final VisitSlot? selectedSlot;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<VisitSlot> onSlotSelected;

  @override
  Widget build(BuildContext context) {
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
          // Section title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_month_outlined,
                    size: 18, color: Color(0xFF135BEC)),
              ),
              const SizedBox(width: 10),
              const Text(
                'Selecciona Fecha y Hora',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Calendar + slots side by side on wide screens
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 480;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendar
                  Expanded(
                    flex: 5,
                    child: _CalendarWidget(
                      availableDays: availableDays,
                      selectedDay: selectedDay,
                      onDaySelected: onDaySelected,
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 260,
                    color: Colors.grey.shade200,
                  ),
                  // Time slots
                  Expanded(
                    flex: 4,
                    child: _SlotsPanel(
                      slots: daySlots,
                      selectedSlot: selectedSlot,
                      onSlotSelected: onSlotSelected,
                    ),
                  ),
                ],
              );
            }
            // Narrow: stacked
            return Column(
              children: [
                _CalendarWidget(
                  availableDays: availableDays,
                  selectedDay: selectedDay,
                  onDaySelected: onDaySelected,
                ),
                if (selectedDay != null) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _SlotsPanel(
                    slots: daySlots,
                    selectedSlot: selectedSlot,
                    onSlotSelected: onSlotSelected,
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Time slots panel
// ─────────────────────────────────────────────────────────────────────────────

class _SlotsPanel extends StatelessWidget {
  const _SlotsPanel({
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  final List<VisitSlot> slots;
  final VisitSlot? selectedSlot;
  final ValueChanged<VisitSlot> onSlotSelected;

  String _label(VisitSlot s) =>
      '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}';

  bool _isSameSlot(VisitSlot a, VisitSlot b) =>
      a.windowId == b.windowId &&
      a.startTime.isAtSameMomentAs(b.startTime);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            const Text(
              'HORAS DISPONIBLES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF64748B),
              ),
            ),
            if (slots.isNotEmpty) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${slots.where((s) => s.isAvailable).length} libres',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (slots.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Icon(Icons.touch_app_outlined, size: 32, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  'Selecciona un dia con disponibilidad\npara ver los horarios',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((slot) {
              final isSelected = selectedSlot != null && _isSameSlot(selectedSlot!, slot);
              final isAvailable = slot.isAvailable;
              return GestureDetector(
                onTap: isAvailable ? () => onSlotSelected(slot) : null,
                child: MouseRegion(
                  cursor: isAvailable ? SystemMouseCursors.click : SystemMouseCursors.basic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF135BEC)
                          : isAvailable
                              ? const Color(0xFFF8FAFC)
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF135BEC)
                            : isAvailable
                                ? const Color(0xFFCBD5E1)
                                : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF135BEC).withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.check_circle, size: 14, color: Colors.white),
                          ),
                        if (!isAvailable)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(Icons.block, size: 13, color: Colors.grey.shade400),
                          ),
                        Text(
                          _label(slot),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isAvailable
                                    ? const Color(0xFF1E293B)
                                    : Colors.grey.shade400,
                            decoration: isAvailable ? null : TextDecoration.lineThrough,
                            decorationColor: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notes field
// ─────────────────────────────────────────────────────────────────────────────

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notas para el vendedor (opcional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText:
                  'Ej., ¿Hay ascensor? ¿Se aceptan mascotas en el edificio?',
              hintStyle:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
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
                borderSide:
                    const BorderSide(color: Color(0xFF135BEC), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trust banner
// ─────────────────────────────────────────────────────────────────────────────

class _TrustBanner extends StatelessWidget {
  const _TrustBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              size: 22, color: Color(0xFF135BEC)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visita Protegida por InmuFácil',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'La identidad del vendedor ha sido verificada. Tus datos solo se compartirán para coordinar la visita.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.blue.shade700, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.selectedDay,
    required this.selectedSlot,
    required this.bookingState,
    required this.onConfirm,
  });

  final DateTime? selectedDay;
  final VisitSlot? selectedSlot;
  final BookingState bookingState;
  final VoidCallback onConfirm;

  String _shortMonth(int m) {
    const names = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return names[m];
  }

  String get _summaryText {
    if (selectedDay == null || selectedSlot == null) return '';
    final d = selectedDay!;
    final t = selectedSlot!.startTime;
    final hour = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    return 'Visita: ${d.day} ${_shortMonth(d.month)} a las $hour:$min';
  }

  bool get _isLoading => bookingState.status == BookingStatus.loading;

  @override
  Widget build(BuildContext context) {
    final canConfirm = selectedSlot != null && !_isLoading;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Summary (left)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RESUMEN DE VISITA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        selectedSlot != null
                            ? _summaryText
                            : 'Selecciona fecha y hora',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selectedSlot != null
                              ? const Color(0xFF1E293B)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Confirm button (right)
            FilledButton(
              onPressed: canConfirm ? onConfirm : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
                disabledBackgroundColor: Colors.grey.shade300,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirmar Solicitud',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calendar widget (Monday-first, LU/MA/MI/JU/VI/SA/DO)
// ─────────────────────────────────────────────────────────────────────────────

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

  // Returns Monday=0 ... Sunday=6 offset for the 1st of the month
  int _mondayFirstOffset(DateTime firstDay) {
    // weekday: Mon=1 ... Sun=7
    return firstDay.weekday - 1;
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final offset = _mondayFirstOffset(firstDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month navigation row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            Row(
              children: [
                _NavButton(
                  icon: Icons.chevron_left,
                  onTap: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month - 1);
                  }),
                ),
                const SizedBox(width: 4),
                _NavButton(
                  icon: Icons.chevron_right,
                  onTap: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month + 1);
                  }),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Day-of-week headers — Monday first
        Row(
          children: const ['LU', 'MA', 'MI', 'JU', 'VI', 'SA', 'DO']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1.3,
          ),
          itemCount: offset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox();
            final day = DateTime(
              _focusedMonth.year,
              _focusedMonth.month,
              index - offset + 1,
            );
            final isAvailable =
                widget.availableDays.any((d) => _sameDay(d, day));
            final isSelected =
                widget.selectedDay != null &&
                    _sameDay(widget.selectedDay!, day);
            final isPast = day.isBefore(
                DateTime.now().subtract(const Duration(days: 1)));
            final isToday = _sameDay(day, DateTime.now());

            Color bg = Colors.transparent;
            Color textColor = const Color(0xFFCBD5E1); // muted for unavailable
            FontWeight weight = FontWeight.normal;

            if (isSelected) {
              bg = const Color(0xFF135BEC);
              textColor = Colors.white;
              weight = FontWeight.w700;
            } else if (isAvailable && !isPast) {
              bg = const Color(0xFFEFF6FF);
              textColor = const Color(0xFF135BEC);
              weight = FontWeight.w700;
            } else if (!isPast) {
              textColor = const Color(0xFF94A3B8);
              weight = FontWeight.w500;
            }

            return GestureDetector(
              onTap: isAvailable && !isPast
                  ? () => widget.onDaySelected(day)
                  : null,
              child: MouseRegion(
                cursor: isAvailable && !isPast
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFF135BEC), width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: weight,
                            color: textColor),
                      ),
                      // Green dot for available days (not selected)
                      if (isAvailable && !isPast && !isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 1),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthName(int month) {
    const names = [
      '',
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return names[month];
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No slots — email request fallback
// ─────────────────────────────────────────────────────────────────────────────

class _NoSlotsEmailRequest extends ConsumerStatefulWidget {
  const _NoSlotsEmailRequest({
    required this.property,
    required this.propertyId,
  });

  final dynamic property;
  final String propertyId;

  @override
  ConsumerState<_NoSlotsEmailRequest> createState() =>
      _NoSlotsEmailRequestState();
}

class _NoSlotsEmailRequestState extends ConsumerState<_NoSlotsEmailRequest> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailState = ref.watch(requestVisitByEmailProvider);

    ref.listen<EmailRequestState>(requestVisitByEmailProvider, (_, next) {
      if (next.status == EmailRequestStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Solicitud enviada al vendedor por email'),
          backgroundColor: Color(0xFF16A34A),
        ));
        ref.read(requestVisitByEmailProvider.notifier).reset();
      } else if (next.status == EmailRequestStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage ?? 'Error al enviar la solicitud'),
          backgroundColor: Colors.red,
        ));
        ref.read(requestVisitByEmailProvider.notifier).reset();
      }
    });

    final isLoading = emailState.status == EmailRequestStatus.loading;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Property card
          _PropertyCard(property: widget.property),
          const SizedBox(height: 24),

          // No availability message
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.event_busy_outlined,
                      size: 32, color: Color(0xFFF97316)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'El vendedor aun no ha configurado horarios de visita',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Puedes enviarle una solicitud por email para que abra '
                  'su disponibilidad y puedas reservar una cita.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Optional message
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  maxLength: 500,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Mensaje para el vendedor (opcional)',
                    hintStyle:
                        TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(12),
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
                      borderSide:
                          const BorderSide(color: Color(0xFF135BEC), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Send request button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => ref
                            .read(requestVisitByEmailProvider.notifier)
                            .request(
                              propertyId: widget.propertyId,
                              message: _messageController.text.trim(),
                            ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.email_outlined),
                    label: Text(
                      isLoading
                          ? 'Enviando...'
                          : 'Solicitar visita por email',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF135BEC),
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Trust banner
          const _TrustBanner(),
        ],
      ),
    );
  }
}
