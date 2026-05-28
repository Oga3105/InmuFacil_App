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

const _kBlue  = Color(0xFF135BEC);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);
const _kNavy  = Color(0xFF001F3F);
const _storage = FlutterSecureStorage();

/// Pagina de Formalizacion Bancaria (FEIN / FIPER).
/// El comprador confirma que el banco ha emitido la FEIN.
/// Gate: solo accesible si la tasacion esta COMPLETADA.
class FeinScreen extends ConsumerStatefulWidget {
  const FeinScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<FeinScreen> createState() => _FeinScreenState();
}

class _FeinScreenState extends ConsumerState<FeinScreen> {
  bool _feinReceived    = false;
  bool _conditionsRead  = false;
  bool _isLoading       = false;
  bool _isInitializing  = true;
  bool _submitted       = false;
  String? _errorMessage;

  bool get _isBuyer =>
      ref.read(authProvider).user?.id.toString() == widget.offer.buyerId;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;
      final resp = await buildAuthDio().get(
        '${EnvConfig.apiBaseUrl}/fein/${widget.offer.id}/status',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      final buyerConfirmed = data['buyer_confirmed'] as bool? ?? false;
      if (buyerConfirmed) {
        setState(() => _submitted = true);
      }
    } catch (_) {
      // non-blocking
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _confirm() async {
    if (!_feinReceived || !_conditionsRead) return;
    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      final dio   = buildAuthDio();
      await dio.post(
        '${EnvConfig.apiBaseUrl}/fein/${widget.offer.id}/confirm',
        data: {
          'role': _isBuyer ? 'BUYER' : 'SELLER',
          'notes': 'transaction.fein_notes_confirm'.tr(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!mounted) return;
      setState(() => _submitted = true);
      ref.invalidate(sentOffersProvider);
      ref.invalidate(receivedOffersProvider);
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = (e.response?.data as Map?)?['detail'] as String?;
      setState(() {
        _errorMessage = detail ?? 'transaction.fein_error_confirm'.tr();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _submitted
          ? _buildSuccessView()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildInfoBanner(),
                const SizedBox(height: 20),
                _buildWhatIsFein(),
                const SizedBox(height: 20),
                _buildTimeline(),
                const SizedBox(height: 20),
                if (_isBuyer) _buildBuyerConfirmationForm() else _buildSellerWaitView(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildErrorBanner(),
                ],
                const SizedBox(height: 24),
                if (_isBuyer) _buildSubmitButton(),
              ],
            ),
    );
  }

  Widget _buildInfoBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blue = isDark ? Color.lerp(_kBlue, Colors.white, 0.45)! : _kBlue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kBlue.withValues(alpha: isDark ? 0.22 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBlue.withValues(alpha: isDark ? 0.55 : 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_balance_outlined, color: blue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('transaction.fein_title'.tr(),
                    style: TextStyle(
                        color: blue, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  _isBuyer
                      ? 'transaction.fein_buyer_banner'.tr()
                      : 'transaction.fein_seller_banner'.tr(),
                  style: TextStyle(
                      color: blue.withValues(alpha: 0.85), fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatIsFein() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final blue = isDark ? Color.lerp(_kBlue, Colors.white, 0.4)! : _kBlue;
    final items = [
      ('transaction.fein_faq1_title'.tr(), 'transaction.fein_faq1_body'.tr()),
      ('transaction.fein_faq2_title'.tr(), 'transaction.fein_faq2_body'.tr()),
      ('transaction.fein_faq3_title'.tr(), 'transaction.fein_faq3_body'.tr()),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('transaction.fein_what_is'.tr(),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kBlue.withValues(alpha: isDark ? 0.25 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(item.$1,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: blue)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.$2,
                          style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final blue = isDark ? Color.lerp(_kBlue, Colors.white, 0.4)! : _kBlue;
    final steps = [
      ('transaction.fein_step1_title'.tr(), 'transaction.fein_step1_body'.tr(), true),
      ('transaction.fein_step2_title'.tr(), 'transaction.fein_step2_body'.tr(), true),
      ('transaction.fein_step3_title'.tr(), 'transaction.fein_step3_body'.tr(), false),
      ('transaction.fein_step4_title'.tr(), 'transaction.fein_step4_body'.tr(), false),
      ('transaction.fein_step5_title'.tr(), 'transaction.fein_step5_body'.tr(), false),
    ];

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
          Text('transaction.fein_process_title'.tr(),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) {
            final index = e.key;
            final step  = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: step.$3 ? _kGreen : _kBlue.withValues(alpha: isDark ? 0.30 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: step.$3
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : Text('${index + 1}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: blue.withValues(alpha: isDark ? 1.0 : 0.7))),
                        ),
                      ),
                      if (index < steps.length - 1)
                        Container(
                          width: 2,
                          height: 20,
                          color: cs.outlineVariant,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.$1,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: step.$3 ? _kGreen : cs.onSurface)),
                        Text(step.$2,
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBuyerConfirmationForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('transaction.fein_form_title'.tr(),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 16),
          _CheckItem(
            value: _feinReceived,
            label: 'transaction.fein_check1'.tr(),
            onChanged: (v) => setState(() => _feinReceived = v ?? false),
          ),
          const SizedBox(height: 8),
          _CheckItem(
            value: _conditionsRead,
            label: 'transaction.fein_check2'.tr(),
            onChanged: (v) => setState(() => _conditionsRead = v ?? false),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: isDark ? 0.5 : 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: isDark ? Colors.amber.shade300 : Colors.amber.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'transaction.fein_form_warn'.tr(),
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerWaitView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor     = isDark ? Colors.orange.shade900.withValues(alpha: 0.25) : Colors.orange.shade50;
    final borderColor = isDark ? Colors.orange.shade600 : Colors.orange.shade200;
    final iconColor   = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    final titleColor  = isDark ? Colors.orange.shade200 : Colors.orange.shade800;
    final bodyColor   = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, color: iconColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('transaction.fein_seller_wait_title'.tr(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'transaction.fein_seller_wait_body'.tr(),
                  style: TextStyle(color: bodyColor, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: isDark ? 0.18 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: isDark ? 0.5 : 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: isDark ? Colors.red.shade300 : Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage!,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.red.shade300 : Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _feinReceived && _conditionsRead;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: canSubmit && !_isLoading ? _confirm : null,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.verified_outlined),
        label: Text('transaction.fein_form_title'.tr()),
        style: FilledButton.styleFrom(
          backgroundColor: _kBlue,
          disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade300,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final blue = isDark ? Color.lerp(_kBlue, Colors.white, 0.4)! : _kBlue;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: isDark ? 0.25 : 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: _kGreen, size: 44),
            ),
            const SizedBox(height: 24),
            Text('transaction.fein_success_title'.tr(),
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              _isBuyer
                  ? 'transaction.fein_success_buyer'.tr()
                  : 'transaction.fein_success_seller'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: cs.onSurfaceVariant, height: 1.6),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: isDark ? 0.5 : 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: isDark ? Colors.amber.shade300 : Colors.amber.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'transaction.fein_success_warn'.tr(),
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(
                  '/offers/${widget.offer.id}/notaria',
                  extra: widget.offer,
                ),
                icon: const Icon(Icons.gavel_outlined),
                label: Text('transaction.fein_goto_notary'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: _kBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('transaction.fein_back_timeline'.tr(),
                  style: TextStyle(color: blue)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: _kBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
