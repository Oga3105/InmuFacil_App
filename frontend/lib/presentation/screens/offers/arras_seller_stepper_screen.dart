import 'package:easy_localization/easy_localization.dart';
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
import '../../../core/config/env_config.dart';
import 'arras_shared_widgets.dart';
import '../../../../core/network/dio_factory.dart';

// Dark-mode-aware colors are resolved at build time via colorScheme / isDark.
const _kNavy = Color(0xFF135BEC);
const kArrasBlue = Color(0xFF135BEC);

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
    final dio = buildAuthDio();
    return dio;
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
          SnackBar(
            content: Text('arras_interview.interview_sent_seller'.tr()),
            backgroundColor: kArrasGreen,
          ),
        );
        context.pop();
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'arras_interview.error_save'.tr();
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
            confirmLabel: 'arras_interview.confirm_my_part'.tr(),
            loading: _loading,
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Estado de la Vivienda ────────────────────────────────────────

  Widget _buildStep1() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArrasPageHeader(
            icon: Icons.home_outlined,
            title: 'arras_interview.seller_step1_title'.tr(),
            subtitle: 'arras_interview.seller_step1_subtitle'.tr(),
            color: kArrasGreen,
          ),
          const SizedBox(height: 24),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArrasSwitchTile(
                  title: 'arras_interview.free_of_tenants_title'.tr(),
                  subtitle: 'arras_interview.free_of_tenants_sub'.tr(),
                  value: _propertyFreeOfTenants,
                  onChanged: (v) =>
                      setState(() => _propertyFreeOfTenants = v),
                  icon: Icons.no_accounts_outlined,
                ),
                const Divider(height: 24),
                ArrasSwitchTile(
                  title: 'arras_interview.utilities_active_title'.tr(),
                  subtitle: 'arras_interview.utilities_active_sub'.tr(),
                  value: _utilitiesActive,
                  onChanged: (v) => setState(() => _utilitiesActive = v),
                  icon: Icons.bolt_outlined,
                ),
                const Divider(height: 24),
                ArrasSwitchTile(
                  title: 'arras_interview.utilities_maintenance_title'.tr(),
                  subtitle: 'arras_interview.utilities_maintenance_sub'.tr(),
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
            text: 'arras_interview.utilities_info_box'.tr(),
            color: colorScheme.primary,
            background: colorScheme.primaryContainer,
          ),
          const SizedBox(height: 16),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'arras_interview.seller_address_label'.tr(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  'arras_interview.seller_address_needed_sub'.tr(),
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sellerAddressCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'arras_interview.seller_address_hint'.tr(),
                    prefixIcon: const Icon(Icons.home_outlined,
                        color: kArrasBlue, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colorScheme.outlineVariant)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colorScheme.outlineVariant)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2)),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArrasPageHeader(
            icon: Icons.apartment_outlined,
            title: 'arras_interview.seller_step2_title'.tr(),
            subtitle: 'arras_interview.seller_step2_subtitle'.tr(),
            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
          ),
          const SizedBox(height: 24),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArrasSwitchTile(
                  title: 'arras_interview.approved_levies_title'.tr(),
                  subtitle: 'arras_interview.approved_levies_sub'.tr(),
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
                      hintText: 'arras_interview.levy_details_hint_full'.tr(),
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
                  title: 'arras_interview.zero_debt_cert_title'.tr(),
                  subtitle: 'arras_interview.zero_debt_cert_sub'.tr(),
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
                  title: 'arras_interview.mortgage_cancel_title'.tr(),
                  subtitle: 'arras_interview.mortgage_cancel_sub'.tr(),
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
                      hintText: 'arras_interview.mortgage_amount_hint_eur'.tr(),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kGreen = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArrasPageHeader(
            icon: Icons.receipt_long_outlined,
            title: 'arras_interview.seller_step3_title'.tr(),
            subtitle: 'arras_interview.seller_step3_subtitle'.tr(),
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 24),
          ArrasInterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArrasSwitchTile(
                  title: 'arras_interview.plusvalia_title'.tr(),
                  subtitle: 'arras_interview.plusvalia_sub'.tr(),
                  value: _plusvaliaAssumed,
                  onChanged: (v) => setState(() => _plusvaliaAssumed = v),
                  icon: Icons.location_city_outlined,
                ),
                const Divider(height: 24),
                ArrasSwitchTile(
                  title: 'arras_interview.ibi_retention_seller_title'.tr(),
                  subtitle: 'arras_interview.ibi_retention_seller_sub'.tr(),
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
                    const Icon(Icons.lock_outline, size: 14, color: _kNavy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'arras_interview.iban_title'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _kNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 22),
                    Expanded(
                      child: Text(
                        'arras_interview.iban_encrypted'.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          color: _kNavy.withOpacity(0.7),
                        ),
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
                Text(
                  'arras_interview.bank_name_title'.tr(),
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _bankNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'arras_interview.bank_placeholder'.tr(),

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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kNavy.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined, size: 16, color: _kNavy),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'arras_interview.iban_security_disclaimer'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _kNavy.withOpacity(0.8),
                            height: 1.4,
                          ),
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
                Text(
                  'arras_interview.additional_clauses_title'.tr(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  'arras_interview.additional_clauses_desc'.tr(),
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _additionalClausesCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'arras_interview.furniture_placeholder'.tr(),

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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                  color: const Color(0xFF135BEC).withOpacity(0.25),
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
                  'common.home_btn'.tr(),
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
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 12),
                const UserAvatarMenu(),
                const SizedBox(width: 16),
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
