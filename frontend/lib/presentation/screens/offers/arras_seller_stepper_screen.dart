import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../providers/auth_provider.dart';
import '../../providers/offers_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import 'arras_shared_widgets.dart';

const _kBg   = Color(0xFFF8FAFC);
const _kBase = 'http://localhost:8000/api/v1';

class ArrasSellerStepperScreen extends ConsumerStatefulWidget {
  const ArrasSellerStepperScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<ArrasSellerStepperScreen> createState() =>
      _ArrasSellerStepperScreenState();
}

class _ArrasSellerStepperScreenState
    extends ConsumerState<ArrasSellerStepperScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  bool _loading = false;

  // ── Step 1: Estado de la Vivienda ────────────────────────────
  bool _propertyFreeOfTenants = true;
  bool _utilitiesActive = true;
  bool _utilitiesMaintenanceCommitment = true;
  final _sellerAddressCtrl = TextEditingController();

  // ── Step 2: Comunidad y Cargas ───────────────────────────────
  bool _hasApprovedLevies = false;
  final _levyDetailsCtrl = TextEditingController();
  bool _zeroDebtCertificate = true;
  bool _hasMortgageToCancel = false;
  final _mortgageAmountCtrl = TextEditingController();

  // ── Step 3: Finanzas e Impuestos ─────────────────────────────
  bool _plusvaliaAssumed = true;
  bool _ibiRetentionAccepted = true;
  final _ibanCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _additionalClausesCtrl = TextEditingController();
  bool _ibanObscured = true;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _levyDetailsCtrl.dispose();
    _mortgageAmountCtrl.dispose();
    _ibanCtrl.dispose();
    _bankNameCtrl.dispose();
    _additionalClausesCtrl.dispose();
    _sellerAddressCtrl.dispose();
    super.dispose();
  }

  Future<Dio?> _buildDio() async {
    final token = await const FlutterSecureStorage().read(key: 'auth_token');
    if (token == null) return null;
    return Dio(BaseOptions(
      baseUrl: _kBase,
      headers: {'Authorization': 'Bearer $token'},
    ));
  }

  void _nextPage() => _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  void _prevPage() => _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  Map<String, dynamic> _buildPayload() {
    return {
      'property_free_of_tenants': _propertyFreeOfTenants,
      'utilities_active': _utilitiesActive,
      'utilities_maintenance_commitment': _utilitiesMaintenanceCommitment,
      'has_approved_levies': _hasApprovedLevies,
      'levy_details': _hasApprovedLevies && _levyDetailsCtrl.text.isNotEmpty
          ? _levyDetailsCtrl.text.trim()
          : null,
      'zero_debt_certificate': _zeroDebtCertificate,
      'has_mortgage_to_cancel': _hasMortgageToCancel,
      'mortgage_amount': _hasMortgageToCancel
          ? int.tryParse(_mortgageAmountCtrl.text.replaceAll('.', ''))
          : null,
      'plusvalia_assumed': _plusvaliaAssumed,
      'ibi_retention_accepted': _ibiRetentionAccepted,
      'iban': _ibanCtrl.text.trim().isEmpty ? null : _ibanCtrl.text.trim(),
      'bank_name': _bankNameCtrl.text.trim().isEmpty
          ? null
          : _bankNameCtrl.text.trim(),
      'additional_clauses': _additionalClausesCtrl.text.isEmpty
          ? null
          : _additionalClausesCtrl.text.trim(),
      'seller_address': _sellerAddressCtrl.text.trim().isEmpty
          ? null
          : _sellerAddressCtrl.text.trim(),
    };
  }

  Future<void> _saveAndConfirm() async {
    setState(() => _loading = true);
    final dio = await _buildDio();
    if (dio == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final offerId = widget.offer.id;
      await dio.post('/arras/$offerId/seller', data: _buildPayload());
      await dio.post('/arras/$offerId/seller/confirm');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrevista enviada. Esperando al comprador.'),
            backgroundColor: kArrasGreen,
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
    return Scaffold(
      backgroundColor: _kBg,
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

  // ─── Step 1: Estado de la Vivienda ────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArrasPageHeader(
            icon: Icons.home_outlined,
            title: 'Estado de la Vivienda',
            subtitle: 'Paso 1 de 3 — Ocupacion y suministros',
            color: kArrasGreen,
          ),
          const SizedBox(height: 24),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArrasSwitchTile(
                  title: 'Vivienda libre de arrendatarios',
                  subtitle:
                      'El inmueble estara desocupado en el momento de la entrega',
                  value: _propertyFreeOfTenants,
                  onChanged: (v) =>
                      setState(() => _propertyFreeOfTenants = v),
                  icon: Icons.no_accounts_outlined,
                ),
                const Divider(height: 24),
                ArrasSwitchTile(
                  title: 'Suministros activos',
                  subtitle:
                      'Luz, agua y gas estan activos y al corriente de pago',
                  value: _utilitiesActive,
                  onChanged: (v) => setState(() => _utilitiesActive = v),
                  icon: Icons.bolt_outlined,
                ),
                const Divider(height: 24),
                ArrasSwitchTile(
                  title: 'Me comprometo a mantener suministros',
                  subtitle:
                      'Mantendre los suministros activos hasta la firma en notaria',
                  value: _utilitiesMaintenanceCommitment,
                  onChanged: (v) =>
                      setState(() => _utilitiesMaintenanceCommitment = v),
                  icon: Icons.task_alt_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoBox(
            icon: Icons.info_outline,
            text:
                'Un suministro cortado o una vivienda ocupada en el momento de la entrega son causas '
                'de incumplimiento del contrato y pueden implicar devolver el doble de las arras.',
            color: Colors.blue.shade700,
            background: Colors.blue.shade50,
          ),
          const SizedBox(height: 16),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu domicilio (vendedor)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Necesario para identificarte en el contrato',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sellerAddressCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Calle, numero, piso, localidad, CP',
                    prefixIcon: const Icon(Icons.home_outlined,
                        color: kArrasBlue, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: kArrasBlue, width: 2)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Comunidad y Cargas ───────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArrasPageHeader(
            icon: Icons.apartment_outlined,
            title: 'Comunidad y Cargas',
            subtitle: 'Paso 2 de 3 — Deudas y derramas',
            color: const Color(0xFFD97706),
          ),
          const SizedBox(height: 24),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArrasSwitchTile(
                  title: 'Derramas aprobadas en comunidad',
                  subtitle:
                      'Existen derramas votadas o en curso en la comunidad de propietarios',
                  value: _hasApprovedLevies,
                  onChanged: (v) {
                    setState(() => _hasApprovedLevies = v);
                    if (!v) _levyDetailsCtrl.clear();
                  },
                  icon: Icons.construction_outlined,
                ),
                if (_hasApprovedLevies) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _levyDetailsCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe la derrama (obras, importe, plazo...)',
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
                            const BorderSide(color: kArrasBlue, width: 2),
                      ),
                    ),
                  ),
                ],
                const Divider(height: 24),
                ArrasSwitchTile(
                  title: 'Certificado de cero deudas de comunidad',
                  subtitle:
                      'Aportare certificado de estar al corriente con la comunidad',
                  value: _zeroDebtCertificate,
                  onChanged: (v) => setState(() => _zeroDebtCertificate = v),
                  icon: Icons.verified_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArrasSwitchTile(
                  title: 'Hipoteca pendiente a cancelar',
                  subtitle:
                      'La vivienda tiene hipoteca que se cancelara en el momento de la venta',
                  value: _hasMortgageToCancel,
                  onChanged: (v) {
                    setState(() => _hasMortgageToCancel = v);
                    if (!v) _mortgageAmountCtrl.clear();
                  },
                  icon: Icons.account_balance_outlined,
                ),
                if (_hasMortgageToCancel) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mortgageAmountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: InputDecoration(
                      hintText: 'Importe pendiente en EUR',
                      suffixText: 'EUR',
                      prefixIcon: const Icon(Icons.euro_outlined,
                          color: kArrasBlue),
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
                            const BorderSide(color: kArrasBlue, width: 2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Finanzas e Impuestos ─────────────────────────────────────────

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArrasPageHeader(
            icon: Icons.receipt_long_outlined,
            title: 'Finanzas e Impuestos',
            subtitle: 'Paso 3 de 3 — Fiscalidad y datos bancarios',
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 24),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArrasSwitchTile(
                  title: 'Asumo la plusvalia municipal',
                  subtitle:
                      'Impuesto sobre el Incremento de Valor de Terrenos de Naturaleza Urbana',
                  value: _plusvaliaAssumed,
                  onChanged: (v) => setState(() => _plusvaliaAssumed = v),
                  icon: Icons.location_city_outlined,
                ),
                const Divider(height: 24),
                ArrasSwitchTile(
                  title: 'Acepto retencion del IBI',
                  subtitle:
                      'Acepto que se retenga la parte proporcional del IBI del año en curso',
                  value: _ibiRetentionAccepted,
                  onChanged: (v) =>
                      setState(() => _ibiRetentionAccepted = v),
                  icon: Icons.balance_outlined,
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kArrasBlue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.credit_card_outlined,
                          color: kArrasBlue, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IBAN para recibir las arras',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF1E3A5F)),
                          ),
                          Text(
                            'Cifrado de extremo a extremo — nunca visible al comprador',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ibanCtrl,
                  obscureText: _ibanObscured,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Z0-9 ]')),
                    LengthLimitingTextInputFormatter(29),
                  ],
                  decoration: InputDecoration(
                    hintText: 'ES00 0000 0000 0000 0000 0000',
                    prefixIcon:
                        const Icon(Icons.lock_outlined, color: kArrasBlue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ibanObscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _ibanObscured = !_ibanObscured),
                    ),
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
                          const BorderSide(color: kArrasBlue, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Entidad bancaria',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _bankNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Ej: CaixaBank, Santander, BBVA...',
                    prefixIcon: const Icon(Icons.account_balance_outlined,
                        color: kArrasBlue, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: kArrasBlue, width: 2)),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security_outlined,
                          color: Colors.green.shade700, size: 14),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tu IBAN se almacena cifrado con AES-256. El numero completo y la '
                          'entidad bancaria apareceran en el contrato para el pago de las arras.',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF166534)),
                        ),
                      ),
                    ],
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
                const Text(
                  'Clausulas adicionales (opcional)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cualquier condicion especial que quieras incluir en el contrato',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _additionalClausesCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Ej: Se incluyen los electrodomesticos...',
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
                          const BorderSide(color: kArrasBlue, width: 2),
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
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBarBackButton(onPressed: () => context.pop()),
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
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                      text: 'Inmu',
                      style: TextStyle(color: Color(0xFF2563EB))),
                  TextSpan(
                      text: 'Fácil',
                      style: TextStyle(color: Color(0xFF16A34A))),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
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

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
