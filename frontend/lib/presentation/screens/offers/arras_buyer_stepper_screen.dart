import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/formatters/currency_input_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/offers_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../../../core/config/env_config.dart';
import 'arras_shared_widgets.dart';
import '../../../../core/network/dio_factory.dart';

// Dark-mode-aware colors are resolved at build time via colorScheme / isDark.

class ArrasBuyerStepperScreen extends ConsumerStatefulWidget {
  const ArrasBuyerStepperScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<ArrasBuyerStepperScreen> createState() =>
      _ArrasBuyerStepperScreenState();
}

class _ArrasBuyerStepperScreenState
    extends ConsumerState<ArrasBuyerStepperScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  bool _loading = false;

  // ── Step 1: Logistica y Notaria ─────────────────────────────
  int _depositPct = 10;
  int _deadlineDays = 60;
  final _notaryPrefCtrl = TextEditingController();
  DateTime? _maxSigningDate;
  final _buyerAddressCtrl = TextEditingController();
  final _propertyAddressCtrl = TextEditingController();
  final _cadastralRefCtrl = TextEditingController();
  final _registryDataCtrl = TextEditingController();

  // ── Step 2: Seguridad y Flexibilidad ────────────────────────
  bool _subjectToMortgage = false;
  bool _extensionAllowed = false;
  final _extensionReasons = <String>{};
  bool _hiddenDefectsAccepted = false;
  bool _communityDebtRetention = true;

  // ── Step 3: Impuestos y Cargas ───────────────────────────────
  bool _ibiProrrationByDays = true;
  bool _retainPendingIbi = false;
  String? _paymentMethod;
  final _additionalClausesCtrl = TextEditingController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    _notaryPrefCtrl.dispose();
    _additionalClausesCtrl.dispose();
    _buyerAddressCtrl.dispose();
    _propertyAddressCtrl.dispose();
    _cadastralRefCtrl.dispose();
    _registryDataCtrl.dispose();
    super.dispose();
  }

  Future<Dio?> _buildDio() async {
    final token = await const FlutterSecureStorage().read(key: 'auth_token');
    if (token == null) return null;
    final dio = buildAuthDio();
    return dio;
  }

  void _nextPage() {
    _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevPage() {
    _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'deposit_percentage': _depositPct,
      'deadline_days': _deadlineDays,
      'notary_preference': _notaryPrefCtrl.text.isEmpty
          ? null
          : _notaryPrefCtrl.text.trim(),
      'max_signing_date': _maxSigningDate?.toIso8601String().split('T').first,
      'subject_to_mortgage': _subjectToMortgage,
      'extension_allowed': _extensionAllowed,
      'extension_reasons':
          _extensionAllowed ? _extensionReasons.toList() : null,
      'hidden_defects_accepted': _hiddenDefectsAccepted,
      'community_debt_retention': _communityDebtRetention,
      'ibi_proration_by_days': _ibiProrrationByDays,
      'retain_pending_ibi': _retainPendingIbi,
      'payment_method': _paymentMethod,
      'additional_clauses': _additionalClausesCtrl.text.isEmpty
          ? null
          : _additionalClausesCtrl.text.trim(),
      'buyer_address': _buyerAddressCtrl.text.trim().isEmpty
          ? null
          : _buyerAddressCtrl.text.trim(),
      'property_address_full': _propertyAddressCtrl.text.trim().isEmpty
          ? null
          : _propertyAddressCtrl.text.trim(),
      'cadastral_reference': _cadastralRefCtrl.text.trim().isEmpty
          ? null
          : _cadastralRefCtrl.text.trim(),
      'registry_data': _registryDataCtrl.text.trim().isEmpty
          ? null
          : _registryDataCtrl.text.trim(),
    };
  }

  Future<void> _saveAndConfirm() async {
    if (_paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('arras_interview.payment_required'.tr())),
      );
      return;
    }
    setState(() => _loading = true);
    final dio = await _buildDio();
    if (dio == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final offerId = widget.offer.id;
      await dio.post('/arras/$offerId/buyer', data: _buildPayload());
      await dio.post('/arras/$offerId/buyer/confirm');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('arras_interview.interview_sent_buyer'.tr()),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF4ADE80)
                : const Color(0xFF16A34A),
          ),
        );
        context.pop();
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Error al guardar';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: _buildAppBar(context, ref),
      body: Column(
        children: [
          ArrasStepIndicator(current: _page, total: 3),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) => setState(() => _page = p),
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),
          ArrasBottomBar(
            page: _page,
            onPrev: _prevPage,
            onNext: _nextPage,
            onConfirm: _loading ? null : _saveAndConfirm,
            confirmLabel: 'Confirmar mi parte',
            loading: _loading,
          ),
        ],
      ),
    );
  }

  // ─── Step 1 ───────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kGreen = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArrasPageHeader(
            icon: Icons.location_city_outlined,
            title: 'Logistica y Notaria',
            subtitle: 'Paso 1 de 3 — Plazos y preferencias de firma',
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_depositPct%',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${CurrencyInputFormatter.format(widget.offer.amount * _depositPct ~/ 100)} EUR',
                        style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Porcentaje de arras (sobre ${CurrencyInputFormatter.format(widget.offer.amount)} EUR)',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                Slider(
                  value: _depositPct.toDouble(),
                  min: 5,
                  max: 20,
                  divisions: 15,
                  activeColor: colorScheme.primary,
                  inactiveColor: colorScheme.outlineVariant,
                  onChanged: (v) => setState(() => _depositPct = v.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('5%',
                        style: TextStyle(
                            fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    Text('20%',
                        style: TextStyle(
                            fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'arras_interview.days_label'.tr(namedArgs: {'n': _deadlineDays.toString()}),
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'arras_interview.months_approx'.tr(namedArgs: {'n': (_deadlineDays / 30).toStringAsFixed(1)}),
                        style: TextStyle(
                            color: kGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
                Text(
                  'arras_interview.deadline_title'.tr(),
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                Slider(
                  value: _deadlineDays.toDouble(),
                  min: 15,
                  max: 180,
                  divisions: 11,
                  activeColor: colorScheme.primary,
                  inactiveColor: colorScheme.outlineVariant,
                  onChanged: (v) => setState(() => _deadlineDays = v.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('arras_interview.days_min'.tr(),
                        style: TextStyle(
                            fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    Text('arras_interview.days_max'.tr(),
                        style: TextStyle(
                            fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notaria preferida (opcional)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notaryPrefCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ej: Notaria de Madrid — Lopez y Asociados',
                    prefixIcon:
                        Icon(Icons.gavel_outlined, color: colorScheme.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Fecha maxima de firma (opcional)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now()
                          .add(Duration(days: _deadlineDays)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _maxSigningDate = picked);
                    }
                  },
                  icon: Icon(Icons.calendar_today_outlined,
                      color: colorScheme.primary),
                  label: Text(
                    _maxSigningDate == null
                        ? 'Seleccionar fecha'
                        : '${_maxSigningDate!.day}/${_maxSigningDate!.month}/${_maxSigningDate!.year}',
                    style: TextStyle(
                        color: _maxSigningDate == null
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datos identificativos del inmueble',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  'Necesarios para la validez legal del contrato',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Tu domicilio (comprador)',
                  controller: _buyerAddressCtrl,
                  hint: 'Calle, numero, piso, localidad, CP',
                  icon: Icons.home_outlined,
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Direccion completa de la vivienda',
                  controller: _propertyAddressCtrl,
                  hint: 'Calle, numero, piso, localidad, CP',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Referencia catastral',
                  controller: _cadastralRefCtrl,
                  hint: 'Ej: 9872023 VH5797S 0001 WX',
                  icon: Icons.grid_view_outlined,
                  caps: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Datos registrales',
                  controller: _registryDataCtrl,
                  hint: 'Registro, tomo, folio, finca, inscripcion',
                  icon: Icons.article_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2 ───────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    final colorScheme = Theme.of(context).colorScheme;
    const reasons = [
      ('work', 'Motivos laborales'),
      ('mortgage_delay', 'Retraso en hipoteca'),
      ('family', 'Motivos familiares'),
      ('legal', 'Procedimiento legal'),
      ('other', 'Otras causas'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArrasPageHeader(
            icon: Icons.shield_outlined,
            title: 'Seguridad y Flexibilidad',
            subtitle: 'Paso 2 de 3 — Condiciones y contingencias',
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 24),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArrasSwitchTile(
                  title: 'Sujeto a concesion de hipoteca',
                  subtitle:
                      'El contrato queda condicionado a la aprobacion del prestamo',
                  value: _subjectToMortgage,
                  onChanged: (v) => setState(() => _subjectToMortgage = v),
                  icon: Icons.account_balance_outlined,
                ),
                const Divider(height: 24),
                ArrasSwitchTile(
                  title: 'Permite prorroga del plazo',
                  subtitle:
                      'Se puede ampliar el plazo por causas justificadas',
                  value: _extensionAllowed,
                  onChanged: (v) => setState(() {
                    _extensionAllowed = v;
                    if (!v) _extensionReasons.clear();
                  }),
                  icon: Icons.more_time_outlined,
                ),
                if (_extensionAllowed) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Causas admitidas:',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 8),
                  ...reasons.map((r) => CheckboxListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text(r.$2,
                            style: const TextStyle(fontSize: 13)),
                        value: _extensionReasons.contains(r.$1),
                        activeColor: colorScheme.primary,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _extensionReasons.add(r.$1);
                          } else {
                            _extensionReasons.remove(r.$1);
                          }
                        }),
                      )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArrasSwitchTile(
                  title: 'Acepta clausula de vicios ocultos',
                  subtitle:
                      'Art. 1484 CC — El vendedor responde por defectos ocultos',
                  value: _hiddenDefectsAccepted,
                  onChanged: (v) => setState(() => _hiddenDefectsAccepted = v),
                  icon: Icons.find_in_page_outlined,
                ),
                const Divider(height: 24),
                ArrasSwitchTile(
                  title: 'Retencion por deudas de comunidad',
                  subtitle:
                      'Se retiene parte del precio si el vendedor tiene deudas pendientes',
                  value: _communityDebtRetention,
                  onChanged: (v) =>
                      setState(() => _communityDebtRetention = v),
                  icon: Icons.apartment_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 3 ───────────────────────────────────────────────────────────────

  Widget _buildStep3() {
    final colorScheme = Theme.of(context).colorScheme;
    const methods = [
      ('cash', 'Pago al contado', Icons.payments_outlined),
      ('mortgage_approved', 'Hipoteca aprobada', Icons.check_circle_outline),
      ('mortgage_pending', 'Hipoteca en tramitacion',
          Icons.hourglass_empty_outlined),
      ('savings_plus_mortgage', 'Ahorros + hipoteca',
          Icons.savings_outlined),
      ('house_to_sell', 'Venta de vivienda actual', Icons.home_outlined),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArrasPageHeader(
            icon: Icons.receipt_long_outlined,
            title: 'Impuestos y Cargas',
            subtitle: 'Paso 3 de 3 — Fiscalidad y financiacion',
            color: const Color(0xFF0891B2),
          ),
          const SizedBox(height: 24),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArrasSwitchTile(
                  title: 'Prorrateo de IBI por dias',
                  subtitle:
                      'El IBI del año se reparte proporcionalmente entre comprador y vendedor',
                  value: _ibiProrrationByDays,
                  onChanged: (v) => setState(() => _ibiProrrationByDays = v),
                  icon: Icons.balance_outlined,
                ),
                const Divider(height: 24),
                ArrasSwitchTile(
                  title: 'Retencion de IBI no emitido',
                  subtitle:
                      'Se retiene el importe del IBI pendiente de emision',
                  value: _retainPendingIbi,
                  onChanged: (v) => setState(() => _retainPendingIbi = v),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metodo de financiacion',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selecciona como tienes previsto pagar',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                ...methods.map((m) => ArrasMethodTile(
                      value: m.$1,
                      label: m.$2,
                      icon: m.$3,
                      selected: _paymentMethod == m.$1,
                      onTap: () => setState(() => _paymentMethod = m.$1),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clausulas adicionales (opcional)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cualquier condicion especial que quieras incluir en el contrato',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _additionalClausesCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Ej: La vivienda debe entregarse vacia...',
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
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child:
            AppBarBackButton(onPressed: () => context.pop()),
      ),
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_inmufacil.png', height: 32),
            const SizedBox(width: 8),
            Text.rich(
              TextSpan(
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                      text: 'Inmu',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  TextSpan(
                      text: 'Fácil',
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF16A34A))),
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
        Consumer(
          builder: (context, ref, _) {
            final isAuthenticated = ref.watch(authProvider).isAuthenticated;
            if (!isAuthenticated) return const SizedBox.shrink();
            return const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserAvatarMenu(),
                SizedBox(width: 16),
              ],
            );
          },
        ),
      ],
    );
  }
}


// ── Shared helper widget ──────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.caps = TextCapitalization.sentences,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextCapitalization caps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          textCapitalization: caps,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: colorScheme.primary, size: 18),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colorScheme.outlineVariant)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colorScheme.outlineVariant)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colorScheme.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}
