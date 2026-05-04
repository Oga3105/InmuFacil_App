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

const _kBlue    = Color(0xFF135BEC);
const _kGreen   = Color(0xFF16A34A);
const _kOrange  = Color(0xFFEA580C);
const _kBg      = Color(0xFFF8FAFC);
const _storage  = FlutterSecureStorage();

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

  // Backend state
  String _apptStatus    = 'pending'; // pending | scheduled | completed
  bool _isLoading       = false;
  bool _isInitializing  = true;
  String? _errorMessage;

  // Datos guardados (vienen del backend)
  String? _savedCity;
  String? _savedDate;
  String? _savedTime;
  bool _buyerConfirmed  = false;
  bool _sellerConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final resp = await buildAuthDio().get(
        '$EnvConfig.apiBaseUrl/notaria-appt/${widget.offer.id}/status',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final d = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _apptStatus      = (d['appointment_status'] as String?) ?? 'pending';
        _savedCity       = d['city'] as String?;
        _savedDate       = d['appointment_date'] as String?;
        _savedTime       = d['appointment_time'] as String?;
        _buyerConfirmed  = (d['buyer_confirmed'] as bool?) ?? false;
        _sellerConfirmed = (d['seller_confirmed'] as bool?) ?? false;
        // Pre-fill form if already scheduled
        if (_savedCity != null) _cityCtrl.text = _savedCity!;
        if (_savedDate != null) {
          final p = _savedDate!.split('-');
          _selectedDate = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        }
        if (_savedTime != null) {
          final p = _savedTime!.split(':');
          _selectedTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        }
      });
    } catch (_) {
      // Silencioso: muestra estado local
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  Future<void> _scheduleNotaria() async {
    if (_cityCtrl.text.isEmpty || _selectedDate == null || _selectedTime == null) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final token = await _storage.read(key: 'auth_token');
      final d = _selectedDate!;
      final t = _selectedTime!;
      await buildAuthDio().post(
        '$EnvConfig.apiBaseUrl/notaria-appt/${widget.offer.id}/schedule',
        data: {
          'city': _cityCtrl.text.trim(),
          'appointment_date':
              '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
          'appointment_time':
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!mounted) return;
      setState(() {
        _apptStatus = 'scheduled';
        _savedCity  = _cityCtrl.text.trim();
        _savedDate  = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        _savedTime  = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('transaction.notaria_snack_proposed'.tr()),
          backgroundColor: _kGreen,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = (e.response?.data as Map?)?['detail'] as String?;
      setState(() => _errorMessage = detail ?? 'transaction.notaria_error_save'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isBuyer = currentUser?.id == widget.offer.buyerId;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: GestureDetector(
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
                      style: TextStyle(color: Color(0xFF135BEC)),
                    ),
                    TextSpan(
                      text: 'Fácil',
                      style: TextStyle(color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                color: const Color(0xFF135BEC),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF135BEC).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'common.home'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final isAuthenticated = ref.watch(authProvider).isAuthenticated;
              if (!isAuthenticated) return const SizedBox.shrink();
              return const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 12),
                  UserAvatarMenu(),
                  SizedBox(width: 16),
                ],
              );
            },
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Top banner: waiting message replaces info banner when confirmed
                if (_apptStatus != 'pending' &&
                    (isBuyer ? _buyerConfirmed : _sellerConfirmed))
                  _buildWaitingBanner(isBuyer)
                else
                  _buildInfoBanner(),
                const SizedBox(height: 20),
                if (isBuyer && _apptStatus == 'pending')
                  _buildBuyerForm()
                else if (isBuyer && _apptStatus != 'pending')
                  _buildConfirmedBanner()
                else if (_apptStatus == 'pending')
                  _buildSellerView()
                else
                  _buildSellerScheduledView(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(_errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 24),
                _buildDocumentChecklist(),
                // Signing CTA only when appointment is set and not yet confirmed
                if (_apptStatus != 'pending' &&
                    !(isBuyer ? _buyerConfirmed : _sellerConfirmed)) ...[
                  const SizedBox(height: 24),
                  _buildSigningCta(context),
                ],
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
                Text('transaction.notaria_info_title'.tr(),
                    style: const TextStyle(
                        color: _kBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'transaction.notaria_info_body'.tr(),
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
          Text('transaction.notaria_form_title'.tr(),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF135BEC))),
          const SizedBox(height: 16),
          // City field
          TextField(
            controller: _cityCtrl,
            decoration: InputDecoration(
              labelText: 'transaction.notaria_city_label'.tr(),
              hintText: 'transaction.notaria_city_hint'.tr(),
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
            label: 'transaction.notaria_date_label'.tr(),
            value: _selectedDate != null
                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                : 'transaction.notaria_select_date'.tr(),
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          _DatePickerRow(
            label: 'transaction.notaria_time_label'.tr(),
            value: _selectedTime != null
                ? _selectedTime!.format(context)
                : 'transaction.notaria_select_time'.tr(),
            icon: Icons.access_time_outlined,
            onTap: _pickTime,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (!_isLoading &&
                      _cityCtrl.text.isNotEmpty &&
                      _selectedDate != null &&
                      _selectedTime != null)
                  ? _scheduleNotaria
                  : null,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_outlined),
              label: Text('transaction.notaria_send_proposal'.tr()),
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
    final isCompleted = _apptStatus == 'completed';
    final accentColor = isCompleted ? _kGreen : _kBlue;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            isCompleted ? Icons.verified_outlined : Icons.event_available_outlined,
            color: accentColor,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            isCompleted ? 'transaction.notaria_confirmed_both'.tr() : 'transaction.notaria_scheduled'.tr(),
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: accentColor),
          ),
          const SizedBox(height: 6),
          if (_savedCity != null || _savedDate != null)
            Text(
              '${_savedCity ?? ''}\n${_savedDate ?? ''}'
              '${_savedTime != null ? ' a las $_savedTime' : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          if (_apptStatus == 'scheduled') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 16,
                    color: _buyerConfirmed ? _kGreen : Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('transaction.notaria_buyer_label'.tr(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(width: 16),
                Icon(Icons.check_circle, size: 16,
                    color: _sellerConfirmed ? _kGreen : Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('transaction.notaria_seller_label'.tr(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
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
                Text('transaction.notaria_waiting_title'.tr(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'transaction.notaria_waiting_body'.tr(),
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerScheduledView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.event_outlined, color: _kBlue, size: 20),
            const SizedBox(width: 8),
            Text('transaction.notaria_seller_view_title'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF135BEC))),
          ]),
          const SizedBox(height: 12),
          if (_savedCity != null)
            _DetailRow(icon: Icons.location_on_outlined, label: 'transaction.notaria_detail_notary'.tr(), value: _savedCity!),
          if (_savedDate != null)
            _DetailRow(icon: Icons.calendar_today_outlined, label: 'transaction.notaria_date_label'.tr(), value: _savedDate!),
          if (_savedTime != null)
            _DetailRow(icon: Icons.access_time_outlined, label: 'transaction.notaria_time_label'.tr(), value: _savedTime!),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, size: 16,
                  color: _buyerConfirmed ? _kGreen : Colors.grey.shade400),
              const SizedBox(width: 4),
              Text('transaction.notaria_buyer_label'.tr(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(width: 16),
              Icon(Icons.check_circle, size: 16,
                  color: _sellerConfirmed ? _kGreen : Colors.grey.shade400),
              const SizedBox(width: 4),
              Text('transaction.notaria_seller_label'.tr(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingBanner(bool isBuyer) {
    final otherParty = isBuyer ? 'transaction.notaria_other_seller'.tr() : 'transaction.notaria_other_buyer'.tr();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_outlined, color: _kGreen, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'transaction.notaria_your_confirmation_title'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14532D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'transaction.notaria_your_confirmation_body'.tr(namedArgs: {'party': otherParty}),
                  style: TextStyle(
                    fontSize: 13,
                    color: _kGreen.withOpacity(0.85),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSigningCta(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: _kGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'transaction.notaria_signing_title'.tr(),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14532D)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'transaction.notaria_signing_body'.tr(),
            style: TextStyle(
                fontSize: 13, color: _kGreen.withOpacity(0.85), height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push(
                '/offers/${widget.offer.id}/notaria-firma',
                extra: widget.offer,
              ),
              icon: const Icon(Icons.key_outlined),
              label: Text('transaction.notaria_signing_btn'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: _kGreen,
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

  Widget _buildDocumentChecklist() {
    final buyerDocs = [
      'transaction.notaria_doc_buyer_1'.tr(),
      'transaction.notaria_doc_buyer_2'.tr(),
      'transaction.notaria_doc_buyer_3'.tr(),
      'transaction.notaria_doc_buyer_4'.tr(),
    ];
    final sellerDocs = [
      'transaction.notaria_doc_seller_1'.tr(),
      'transaction.notaria_doc_seller_2'.tr(),
      'transaction.notaria_doc_seller_3'.tr(),
      'transaction.notaria_doc_seller_4'.tr(),
      'transaction.notaria_doc_seller_5'.tr(),
      'transaction.notaria_doc_seller_6'.tr(),
      'transaction.notaria_doc_seller_7'.tr(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'transaction.notaria_docs_title'.tr(),
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF135BEC)),
        ),
        const SizedBox(height: 16),
        _DocsSection(title: 'transaction.notaria_buyer_label'.tr(), icon: Icons.person_outline, docs: buyerDocs),
        const SizedBox(height: 12),
        _DocsSection(title: 'transaction.notaria_seller_label'.tr(), icon: Icons.home_outlined, docs: sellerDocs),
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
                      fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF135BEC))),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: _kBlue, size: 16),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Expanded(child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF135BEC)))),
        ],
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
                      fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF135BEC))),
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
