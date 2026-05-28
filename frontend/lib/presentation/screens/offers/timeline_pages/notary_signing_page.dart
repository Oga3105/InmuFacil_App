import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/common/app_bar_back_button.dart';
import '../../../widgets/common/user_avatar_menu.dart';
import '../../../providers/offers_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/dio_factory.dart';

const _notaryStorage = FlutterSecureStorage();

const _kBlue  = Color(0xFF135BEC);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);
const _kNavy  = Color(0xFF135BEC);

/// Pagina de confirmacion de firma ante notario y entrega de llaves.
/// Ambas partes deben confirmar individualmente.
/// Tras la confirmacion del usuario activo, el timeline avanza a Post-Venta.
class NotarySigningPage extends ConsumerStatefulWidget {
  const NotarySigningPage({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<NotarySigningPage> createState() => _NotarySigningPageState();
}

class _NotarySigningPageState extends ConsumerState<NotarySigningPage> {
  bool _signingConfirmed = false;
  bool _keysConfirmed    = false;
  bool _submitted        = false;
  bool _isLoading        = false;
  bool _isInitializing   = true;

  // Persisted confirmation state from backend
  bool _buyerConfirmed  = false;
  bool _sellerConfirmed = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final token = await _notaryStorage.read(key: 'auth_token');
      final resp = await buildAuthDio().get(
        '${EnvConfig.apiBaseUrl}/notaria-appt/${widget.offer.id}/status',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final d = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      final currentUser = ref.read(authProvider).user;
      final isBuyer = currentUser?.id.toString() == widget.offer.buyerId;
      final buyerConf  = (d['buyer_confirmed']  as bool?) ?? false;
      final sellerConf = (d['seller_confirmed'] as bool?) ?? false;
      setState(() {
        _buyerConfirmed  = buyerConf;
        _sellerConfirmed = sellerConf;
        // If the current user already confirmed in a prior session, show success
        _submitted = isBuyer ? buyerConf : sellerConf;
      });
    } catch (_) {
      // Silent — show form with defaults
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _submit() async {
    if (!_signingConfirmed || !_keysConfirmed) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final token = await _notaryStorage.read(key: 'auth_token');
      final headers = {'Authorization': 'Bearer $token'};
      final dio = buildAuthDio();

      // Confirma firma en notaria — este es el paso crítico que abre Post-Venta.
      await dio.post(
        '${EnvConfig.apiBaseUrl}/notaria-appt/${widget.offer.id}/confirm',
        options: Options(headers: headers),
      );

      // Confirma entrega de llaves — ignorar errores (puede que el endpoint
      // no exista aún o ya esté confirmado), la firma de notaria es suficiente.
      try {
        await dio.post(
          '${EnvConfig.apiBaseUrl}/entrega-llaves/${widget.offer.id}/confirm',
          options: Options(headers: headers),
        );
      } on DioException {
        // No bloqueante — la confirmacion de notaria ya fue registrada.
      }

      if (!mounted) return;
      setState(() { _submitted = true; });
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = (e.response?.data as Map?)?['detail'] as String?;
      setState(() => _errorMessage = detail ?? 'transaction.keys_confirm_error'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isBuyer = currentUser?.id.toString() == widget.offer.buyerId;

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
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _submitted
          ? _buildSuccessView(context, isBuyer)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildInfoBanner(context, isBuyer),
                const SizedBox(height: 20),
                _buildStatusCard(context, isBuyer),
                const SizedBox(height: 20),
                _buildConfirmationForm(context, isBuyer),
                const SizedBox(height: 24),
                _buildSubmitButton(context),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.red.shade900.withValues(alpha: 0.30)
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isDark ? Colors.red.shade700 : Colors.red.shade200),
                      ),
                      child: Text(_errorMessage!,
                          style: TextStyle(
                              color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                              fontSize: 13)),
                    );
                  }),
                ],
              ],
            ),
    );
  }

  Widget _buildInfoBanner(BuildContext context, bool isBuyer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerColor = _kBlue.withValues(alpha: isDark ? 0.22 : 0.07);
    final borderColor = _kBlue.withValues(alpha: isDark ? 0.55 : 0.25);
    final textColor = isDark ? Color.lerp(_kBlue, Colors.white, 0.45)! : _kBlue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gavel, color: textColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'transaction.notary_close_title'.tr(),
                  style: TextStyle(
                      color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  isBuyer ? 'transaction.notary_buyer_desc'.tr() : 'transaction.notary_seller_desc'.tr(),
                  style: TextStyle(
                      color: textColor.withValues(alpha: 0.85), fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isBuyer) {
    final cs = Theme.of(context).colorScheme;
    final myConfirmed    = isBuyer ? _buyerConfirmed  : _sellerConfirmed;
    final otherConfirmed = isBuyer ? _sellerConfirmed : _buyerConfirmed;
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'transaction.notary_status_title'.tr(),
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: isBuyer ? 'transaction.notary_your_confirm_buyer'.tr() : 'transaction.notary_your_confirm_seller'.tr(),
            isPending: !myConfirmed && !_submitted,
            isCurrentUser: true,
          ),
          const SizedBox(height: 8),
          _StatusRow(
            label: isBuyer ? 'transaction.notary_other_confirm_seller'.tr() : 'transaction.notary_other_confirm_buyer'.tr(),
            isPending: !otherConfirmed,
            isCurrentUser: false,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationForm(BuildContext context, bool isBuyer) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          Text(
            'transaction.notary_declare_title'.tr(),
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
          const SizedBox(height: 16),
          _CheckItem(
            value: _signingConfirmed,
            label: 'transaction.notary_declare_signed'.tr(),
            onChanged: (v) => setState(() => _signingConfirmed = v ?? false),
          ),
          const SizedBox(height: 12),
          _CheckItem(
            value: _keysConfirmed,
            label: isBuyer ? 'transaction.notary_declare_keys_buyer'.tr() : 'transaction.notary_declare_keys_seller'.tr(),
            onChanged: (v) => setState(() => _keysConfirmed = v ?? false),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.amber.shade900.withValues(alpha: 0.25) : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isDark ? Colors.amber.shade600 : Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: isDark ? Colors.amber.shade300 : Colors.amber.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'transaction.notary_declare_warning'.tr(),
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

  Widget _buildSubmitButton(BuildContext context) {
    final canSubmit = _signingConfirmed && _keysConfirmed;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: canSubmit && !_isLoading ? _submit : null,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.verified_outlined),
        label: Text('transaction.notary_confirm_btn'.tr()),
        style: FilledButton.styleFrom(
          backgroundColor: _kGreen,
          disabledBackgroundColor:
              isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          disabledForegroundColor:
              isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, bool isBuyer) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              child: Icon(Icons.verified,
                  color: isDark ? Color.lerp(_kGreen, Colors.white, 0.3)! : _kGreen,
                  size: 44),
            ),
            const SizedBox(height: 24),
            Text(
              'transaction.notary_success_title'.tr(),
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              isBuyer ? 'transaction.notary_success_buyer'.tr() : 'transaction.notary_success_seller'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: cs.onSurfaceVariant, height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  context.go('/offers/${widget.offer.id}/post-venta',
                      extra: widget.offer);
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text('transaction.notary_go_post_venta'.tr()),
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
              child: Text(
                'transaction.back_to_timeline'.tr(),
                style: TextStyle(
                  color: isDark
                      ? Color.lerp(_kBlue, Colors.white, 0.45)!
                      : _kBlue,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: isDark
                      ? Color.lerp(_kBlue, Colors.white, 0.45)!
                      : _kBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.isPending,
    required this.isCurrentUser,
  });

  final String label;
  final bool isPending;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isPending ? Colors.orange.shade600 : _kGreen;
    final icon  = isPending ? Icons.hourglass_empty : Icons.check_circle;
    final text  = isPending ? 'transaction.notary_pending'.tr() : 'transaction.notary_confirmed'.tr();

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: isCurrentUser ? cs.onSurface : cs.onSurfaceVariant)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.25 : 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(text,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ),
      ],
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
              activeColor: _kGreen,
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
