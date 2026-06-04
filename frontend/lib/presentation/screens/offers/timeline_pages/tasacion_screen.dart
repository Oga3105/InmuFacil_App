import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/common/app_bar_back_button.dart';
import '../../../providers/offers_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/user_avatar_menu.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/dio_factory.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBlue   = Color(0xFF135BEC);
const _kGreen  = Color(0xFF16A34A);
const _kOrange = Color(0xFFEA580C);
const _kBg     = Color(0xFFF8FAFC);
const _storage  = FlutterSecureStorage();

class TasacionScreen extends ConsumerStatefulWidget {
  const TasacionScreen({super.key, required this.offer});
  final OfferData offer;

  @override
  ConsumerState<TasacionScreen> createState() => _TasacionScreenState();
}

class _TasacionScreenState extends ConsumerState<TasacionScreen> {
  // ── Estado de la maquina ──────────────────────────────────────────────────
  // pending | proposed | rejected | accepted | completed
  String _apptStatus = 'pending';

  // Propuesta del comprador
  DateTime? _buyerDate;
  TimeOfDay? _buyerTime;
  final _notesCtrl = TextEditingController();

  // Contraoferta del vendedor (cuando rejected)
  DateTime? _sellerDate;
  TimeOfDay? _sellerTime;
  String _sellerRejectionNotes = '';

  // Form de rechazo (inline para el vendedor)
  DateTime? _rejectDate;
  TimeOfDay? _rejectTime;
  final _rejectNotesCtrl = TextEditingController();
  bool _showRejectForm = false;

  bool _isLoading      = false;
  bool _isInitializing = true;
  String? _errorMessage;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _rejectNotesCtrl.dispose();
    super.dispose();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _loadStatus() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final resp = await buildAuthDio().get(
        '${EnvConfig.apiBaseUrl}/tasacion/${widget.offer.id}/status',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final d = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _apptStatus = (d['appointment_status'] as String?) ?? 'pending';

        final dateStr = d['appointment_date'] as String?;
        final timeStr = d['appointment_time'] as String?;
        if (dateStr != null) {
          final p = dateStr.split('-');
          _buyerDate = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        }
        if (timeStr != null) {
          final p = timeStr.split(':');
          _buyerTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        }
        _notesCtrl.text = (d['notes'] as String?) ?? '';

        final sDateStr = d['seller_proposed_date'] as String?;
        final sTimeStr = d['seller_proposed_time'] as String?;
        if (sDateStr != null) {
          final p = sDateStr.split('-');
          _sellerDate = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        }
        if (sTimeStr != null) {
          final p = sTimeStr.split(':');
          _sellerTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        }
        _sellerRejectionNotes = (d['seller_rejection_notes'] as String?) ?? '';
      });
    } catch (_) {
      // Fallback silencioso — estado local
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _scheduleAppointment() async {
    if (_buyerDate == null || _buyerTime == null) return;
    _setLoading(true);
    try {
      final token = await _storage.read(key: 'auth_token');
      final dateStr = _isoDate(_buyerDate!);
      final timeStr = _isoTime(_buyerTime!);
      await buildAuthDio().post(
        '${EnvConfig.apiBaseUrl}/tasacion/${widget.offer.id}/schedule',
        data: {'appointment_date': dateStr, 'appointment_time': timeStr, 'notes': _notesCtrl.text.trim()},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!mounted) return;
      setState(() {
        _apptStatus = 'proposed';
        _sellerDate = null;
        _sellerTime = null;
        _sellerRejectionNotes = '';
        _showRejectForm = false;
      });
      _snack('transaction.tasacion_snack_proposed'.tr());
    } on DioException catch (e) {
      _setError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _acceptAppointment() async {
    _setLoading(true);
    try {
      final token = await _storage.read(key: 'auth_token');
      await buildAuthDio().post(
        '${EnvConfig.apiBaseUrl}/tasacion/${widget.offer.id}/accept',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!mounted) return;
      setState(() => _apptStatus = 'accepted');
      _snack('transaction.tasacion_snack_accepted'.tr());
    } on DioException catch (e) {
      _setError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _rejectAppointment() async {
    if (_rejectDate == null || _rejectTime == null) return;
    _setLoading(true);
    try {
      final token = await _storage.read(key: 'auth_token');
      await buildAuthDio().post(
        '${EnvConfig.apiBaseUrl}/tasacion/${widget.offer.id}/reject',
        data: {
          'proposed_date': _isoDate(_rejectDate!),
          'proposed_time': _isoTime(_rejectTime!),
          'notes': _rejectNotesCtrl.text.trim(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!mounted) return;
      setState(() {
        _apptStatus = 'rejected';
        _sellerDate = _rejectDate;
        _sellerTime = _rejectTime;
        _sellerRejectionNotes = _rejectNotesCtrl.text.trim();
        _showRejectForm = false;
        _rejectDate = null;
        _rejectTime = null;
        _rejectNotesCtrl.clear();
      });
      _snack('transaction.tasacion_snack_rejected'.tr());
    } on DioException catch (e) {
      _setError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _acceptSellerProposal() async {
    if (_sellerDate == null || _sellerTime == null) return;
    _setLoading(true);
    try {
      final token = await _storage.read(key: 'auth_token');
      await buildAuthDio().post(
        '${EnvConfig.apiBaseUrl}/tasacion/${widget.offer.id}/accept-counter',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!mounted) return;
      setState(() {
        _apptStatus = 'accepted';
        _buyerDate  = _sellerDate;
        _buyerTime  = _sellerTime;
        _sellerDate = null;
        _sellerTime = null;
        _sellerRejectionNotes = '';
      });
      _snack('transaction.tasacion_snack_counter_accepted'.tr());
    } on DioException catch (e) {
      _setError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _confirmVisitCompleted() async {
    _setLoading(true);
    try {
      final token = await _storage.read(key: 'auth_token');
      await buildAuthDio().post(
        '${EnvConfig.apiBaseUrl}/tasacion/${widget.offer.id}/confirm-visit',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!mounted) return;
      setState(() => _apptStatus = 'completed');
    } on DioException catch (e) {
      _setError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ── Date / time pickers ───────────────────────────────────────────────────

  Future<void> _pickBuyerDate() async {
    final p = await _datePicker();
    if (p != null) setState(() => _buyerDate = p);
  }

  Future<void> _pickBuyerTime() async {
    final p = await _timePicker();
    if (p != null) setState(() => _buyerTime = p);
  }

  Future<void> _pickRejectDate() async {
    final p = await _datePicker();
    if (p != null) setState(() => _rejectDate = p);
  }

  Future<void> _pickRejectTime() async {
    final p = await _timePicker();
    if (p != null) setState(() => _rejectTime = p);
  }

  Future<DateTime?> _datePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adaptiveBlue = Color.lerp(_kBlue, Colors.white, 0.4)!;
    return showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(primary: adaptiveBlue)
                : const ColorScheme.light(primary: _kBlue)),
        child: child!,
      ),
    );
  }

  Future<TimeOfDay?> _timePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adaptiveBlue = Color.lerp(_kBlue, Colors.white, 0.4)!;
    return showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(primary: adaptiveBlue)
                : const ColorScheme.light(primary: _kBlue)),
        child: child!,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _isoTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _formatTime(TimeOfDay t, BuildContext ctx) => t.format(ctx);

  void _setLoading(bool v) {
    if (mounted) setState(() { _isLoading = v; if (v) _errorMessage = null; });
  }

  void _setError(DioException e) {
    if (!mounted) return;
    final detail = (e.response?.data as Map?)?['detail'] as String?;
    setState(() => _errorMessage = detail ?? 'transaction.network_error_fallback'.tr());
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _kGreen),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isSeller = currentUser?.id != widget.offer.buyerId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _InfoCard(
                  icon: Icons.assessment_outlined,
                  color: _kBlue,
                  title: 'transaction.tasacion_info_title'.tr(),
                  body: 'transaction.tasacion_info_body'.tr(),
                ),
                const SizedBox(height: 20),
                _buildRoleView(context, isSeller),
                const SizedBox(height: 20),
                _ChecklistCard(
                  title: isSeller ? 'transaction.tasacion_checklist_seller'.tr() : 'transaction.tasacion_checklist_buyer'.tr(),
                  items: [
                    'transaction.tasacion_checklist_1'.tr(),
                    'transaction.tasacion_checklist_2'.tr(),
                    'transaction.tasacion_checklist_3'.tr(),
                    'transaction.tasacion_checklist_4'.tr(),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _InfoCard(icon: Icons.error_outline, color: Colors.red, title: 'common.error_title'.tr(), body: _errorMessage!),
                ],
              ],
            ),
    );
  }

  // ── Role / state router ───────────────────────────────────────────────────

  Widget _buildRoleView(BuildContext context, bool isSeller) {
    switch (_apptStatus) {
      case 'pending':
        return isSeller ? _buildSellerWaiting() : _buildBuyerScheduleForm(context);
      case 'proposed':
        return isSeller ? _buildSellerDecision(context) : _buildBuyerWaiting();
      case 'rejected':
        return isSeller ? _buildSellerWaitingNewProposal() : _buildBuyerCounterProposal(context);
      case 'accepted':
        return isSeller ? _buildSellerConfirmVisit() : _buildAccepted(context, isSeller: false);
      case 'completed':
        return _buildCompleted(context, isSeller);
      default:
        return isSeller ? _buildSellerWaiting() : _buildBuyerScheduleForm(context);
    }
  }

  // pending — comprador
  Widget _buildBuyerScheduleForm(BuildContext context) {
    return _TaskCard(
      title: 'transaction.tasacion_schedule_title'.tr(),
      subtitle: 'transaction.tasacion_schedule_subtitle'.tr(),
      child: Column(
        children: [
          _DateTimeRow(
            label: 'transaction.tasacion_date_label'.tr(),
            value: _buyerDate != null ? _formatDate(_buyerDate!) : 'transaction.tasacion_select'.tr(),
            icon: Icons.calendar_today_outlined,
            onTap: _pickBuyerDate,
          ),
          const SizedBox(height: 12),
          _DateTimeRow(
            label: 'transaction.tasacion_time_label'.tr(),
            value: _buyerTime != null ? _formatTime(_buyerTime!, context) : 'transaction.tasacion_select'.tr(),
            icon: Icons.access_time_outlined,
            onTap: _pickBuyerTime,
          ),
          const SizedBox(height: 16),
          Builder(builder: (context) {
            final cs = Theme.of(context).colorScheme;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return TextField(
              controller: _notesCtrl,
              style: TextStyle(color: cs.onSurface),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'transaction.tasacion_notes_label'.tr(),
                labelStyle: TextStyle(color: cs.onSurfaceVariant),
                hintStyle: TextStyle(color: cs.onSurfaceVariant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.outlineVariant)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBlue, width: 2)),
              ),
            );
          }),
          const SizedBox(height: 20),
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (!_isLoading && _buyerDate != null && _buyerTime != null)
                    ? _scheduleAppointment
                    : null,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined),
                label: Text('transaction.tasacion_send_proposal'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: _kBlue,
                  disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  disabledForegroundColor: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // pending — vendedor
  Widget _buildSellerWaiting() => _InfoCard(
        icon: Icons.hourglass_empty_outlined,
        color: _kOrange,
        title: 'transaction.tasacion_waiting_title'.tr(),
        body: 'transaction.tasacion_waiting_body'.tr(),
      );

  // proposed — comprador (esperando respuesta del vendedor)
  Widget _buildBuyerWaiting() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kOrange.withValues(alpha: isDark ? 0.18 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kOrange.withValues(alpha: isDark ? 0.5 : 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.schedule_outlined, color: _kOrange, size: 20),
            const SizedBox(width: 8),
            Text('transaction.tasacion_proposed_badge'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: _kOrange, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          if (_buyerDate != null && _buyerTime != null)
            _AppointmentBadge(
              date: _buyerDate!,
              time: _buyerTime!,
              label: 'transaction.tasacion_your_proposal'.tr(),
              color: _kOrange,
            ),
          const SizedBox(height: 10),
          Text('transaction.tasacion_proposed_hint'.tr(),
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  // proposed — vendedor (puede aceptar o rechazar)
  Widget _buildSellerDecision(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final blue = isDark ? Color.lerp(_kBlue, Colors.white, 0.4)! : _kBlue;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.calendar_month_outlined, color: blue, size: 20),
            const SizedBox(width: 8),
            Text('transaction.tasacion_buyer_proposes'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: blue)),
          ]),
          const SizedBox(height: 14),
          if (_buyerDate != null && _buyerTime != null)
            _AppointmentBadge(date: _buyerDate!, time: _buyerTime!, label: 'transaction.tasacion_proposed_date'.tr(), color: _kBlue),
          if (_notesCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_outlined, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_notesCtrl.text,
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Aceptar
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _acceptAppointment,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: Text('transaction.tasacion_accept_date'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: _kGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Rechazar — toggle del formulario de contraoferta
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => setState(() => _showRejectForm = !_showRejectForm),
              icon: Icon(_showRejectForm ? Icons.expand_less : Icons.event_busy_outlined, size: 18),
              label: Text(_showRejectForm ? 'transaction.tasacion_cancel_label'.tr() : 'transaction.tasacion_reject_propose'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kOrange,
                side: BorderSide(color: _kOrange.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_showRejectForm) ...[
            const SizedBox(height: 16),
            _buildRejectForm(context),
          ],
        ],
      ),
    );
  }

  // Formulario inline para que el vendedor proponga nueva fecha
  Widget _buildRejectForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kOrange.withValues(alpha: isDark ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kOrange.withValues(alpha: isDark ? 0.45 : 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('transaction.tasacion_alt_title'.tr(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kOrange)),
          const SizedBox(height: 12),
          _DateTimeRow(
            label: 'transaction.tasacion_alt_date'.tr(),
            value: _rejectDate != null ? _formatDate(_rejectDate!) : 'transaction.tasacion_select'.tr(),
            icon: Icons.calendar_today_outlined,
            onTap: _pickRejectDate,
          ),
          const SizedBox(height: 10),
          _DateTimeRow(
            label: 'transaction.tasacion_alt_time'.tr(),
            value: _rejectTime != null ? _formatTime(_rejectTime!, context) : 'transaction.tasacion_select'.tr(),
            icon: Icons.access_time_outlined,
            onTap: _pickRejectTime,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rejectNotesCtrl,
            style: TextStyle(color: cs.onSurface),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'transaction.tasacion_alt_notes'.tr(),
              labelStyle: TextStyle(color: cs.onSurfaceVariant),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _kOrange.withValues(alpha: 0.4))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _kOrange, width: 2)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (!_isLoading && _rejectDate != null && _rejectTime != null)
                  ? _rejectAppointment
                  : null,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_outlined),
              label: Text('transaction.tasacion_send_counter'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: _kOrange,
                disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                disabledForegroundColor: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // rejected — comprador (ve la contraoferta del vendedor)
  Widget _buildBuyerCounterProposal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final blue = isDark ? Color.lerp(_kBlue, Colors.white, 0.4)! : _kBlue;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.event_repeat_outlined, color: _kOrange, size: 20),
            const SizedBox(width: 8),
            Text('transaction.tasacion_seller_counter_title'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: blue)),
          ]),
          const SizedBox(height: 6),
          Text('transaction.tasacion_seller_counter_body'.tr(),
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          if (_sellerDate != null && _sellerTime != null)
            _AppointmentBadge(date: _sellerDate!, time: _sellerTime!, label: 'transaction.tasacion_seller_proposal'.tr(), color: _kOrange),
          if (_sellerRejectionNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_outlined, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_sellerRejectionNotes,
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _acceptSellerProposal,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: Text('transaction.tasacion_accept_date'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: _kGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => setState(() {
                        _apptStatus = 'pending';
                        _buyerDate = null;
                        _buyerTime = null;
                        _notesCtrl.clear();
                      }),
              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: Text('transaction.tasacion_propose_other'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: blue,
                side: BorderSide(color: blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // rejected — vendedor (esperando nueva propuesta del comprador)
  Widget _buildSellerWaitingNewProposal() => _InfoCard(
        icon: Icons.hourglass_empty_outlined,
        color: _kOrange,
        title: 'transaction.tasacion_waiting_new_title'.tr(),
        body: 'transaction.tasacion_waiting_new_body'.tr(),
      );

  // accepted — ambas partes acordaron la fecha
  Widget _buildAccepted(BuildContext context, {required bool isSeller}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: isDark ? 0.22 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withValues(alpha: isDark ? 0.55 : 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: _kGreen, size: 40),
          const SizedBox(height: 10),
          Text('transaction.tasacion_confirmed'.tr(),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _kGreen)),
          const SizedBox(height: 8),
          if (_buyerDate != null && _buyerTime != null)
            Text(
              'transaction.tasacion_confirmed_at'.tr(namedArgs: {'date': _formatDate(_buyerDate!), 'time': _formatTime(_buyerTime!, context)}),
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          const SizedBox(height: 6),
          Text(
            isSeller
                ? 'transaction.tasacion_seller_confirm_hint'.tr()
                : 'transaction.tasacion_buyer_confirm_hint'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // accepted — vendedor: ve la cita + boton confirmar visita
  Widget _buildSellerConfirmVisit() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blue = isDark ? Color.lerp(_kBlue, Colors.white, 0.4)! : _kBlue;
    return Column(
      children: [
        _buildAccepted(context, isSeller: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.home_work_outlined, color: blue, size: 20),
                const SizedBox(width: 8),
                Text('transaction.tasacion_confirm_visit_title'.tr(),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: blue)),
              ]),
              const SizedBox(height: 8),
              Text('transaction.tasacion_confirm_visit_body'.tr(),
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.4)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _confirmVisitCompleted,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text('transaction.tasacion_visit_done'.tr()),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // completed
  Widget _buildCompleted(BuildContext context, bool isSeller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: isDark ? 0.22 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withValues(alpha: isDark ? 0.55 : 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_outlined, color: _kGreen, size: 40),
          const SizedBox(height: 10),
          Text('transaction.tasacion_completed'.tr(),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _kGreen)),
          const SizedBox(height: 8),
          Text(
            isSeller
                ? 'transaction.tasacion_completed_seller'.tr()
                : 'transaction.tasacion_completed_buyer'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          if (!isSeller) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/offers/${widget.offer.id}/fein', extra: widget.offer),
                icon: const Icon(Icons.account_balance_outlined),
                label: Text('transaction.tasacion_goto_fein'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: _kBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBarBackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      title: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
        onTap: () => context.go('/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_inmufacil.png', height: 32),
            const SizedBox(width: 8),
            Text(
              'transaction.tasacion_app_bar_title'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      )),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
      ),
      actions: [
        if (MediaQuery.sizeOf(context).width >= 650)
        GestureDetector(
          onTap: () => context.go('/'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _kBlue,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: _kBlue.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.home_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text('common.home_btn'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
        Consumer(
          builder: (context, ref, _) {
            final isAuth = ref.watch(authProvider).isAuthenticated;
            if (!isAuth) return const SizedBox.shrink();
            return const Row(
              mainAxisSize: MainAxisSize.min,
              children: [SizedBox(width: 12), UserAvatarMenu(), SizedBox(width: 16)],
            );
          },
        ),
      ],
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

/// Badge que muestra fecha y hora de la cita de forma visual.
class _AppointmentBadge extends StatelessWidget {
  const _AppointmentBadge({
    required this.date,
    required this.time,
    required this.label,
    required this.color,
  });

  final DateTime date;
  final TimeOfDay time;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.5 : 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_outlined, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                'transaction.tasacion_appointment_format'.tr(namedArgs: {
                  'day': date.day.toString(),
                  'month': date.month.toString(),
                  'year': date.year.toString(),
                  'time': time.format(context)
                }),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.color, required this.title, required this.body});
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.50 : 0.25)),
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
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: color.withValues(alpha: 0.85), fontSize: 13, height: 1.5)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final blue = isDark ? Color.lerp(const Color(0xFF135BEC), Colors.white, 0.4)! : const Color(0xFF135BEC);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: blue)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({required this.label, required this.value, required this.icon, required this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final blue = isDark ? Color.lerp(const Color(0xFF135BEC), Colors.white, 0.4)! : const Color(0xFF135BEC);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: blue, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            const Spacer(),
            Text(value,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: blue)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final blue = isDark ? Color.lerp(const Color(0xFF135BEC), Colors.white, 0.4)! : const Color(0xFF135BEC);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: blue)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: _kGreen, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
