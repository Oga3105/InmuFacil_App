import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../providers/auth_provider.dart';
import '../../providers/offers_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../../../core/config/env_config.dart';
import '../../../core/formatters/currency_input_formatter.dart';
import '../../../core/network/dio_factory.dart';

const _kBlue  = Color(0xFF135BEC);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);

// ── Provider ──────────────────────────────────────────────────────────────────

final _arrasHubProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, offerId) async {
  final token =
      await const FlutterSecureStorage().read(key: 'auth_token');
  if (token == null) return null;
  final dio = buildAuthDio();
  try {
    final resp = await dio.get(
      '${EnvConfig.apiBaseUrl}/arras/$offerId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return resp.data as Map<String, dynamic>;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ArrasInterviewScreen extends ConsumerStatefulWidget {
  const ArrasInterviewScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<ArrasInterviewScreen> createState() =>
      _ArrasInterviewScreenState();
}

class _ArrasInterviewScreenState
    extends ConsumerState<ArrasInterviewScreen> {
  bool _consentLoading = false;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _triggerRegenerate(BuildContext context, WidgetRef ref) async {
    try {
      final dio = buildAuthDio();
      await dio.post(
          '${EnvConfig.apiBaseUrl}/arras/${widget.offer.id}/contract/regenerate');
      ref.invalidate(_arrasHubProvider(widget.offer.id));
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.response?.data?['detail'] ??
              'arras_interview.error_regenerate'.tr()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _maybeStartPolling(String? contractStatus) {
    if (contractStatus == 'generating') {
      _pollTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          ref.invalidate(_arrasHubProvider(widget.offer.id));
        }
      });
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<void> _showCashConsentModal(
      BuildContext context, WidgetRef ref) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CashConsentDialog(),
    );
    if (accepted == true && mounted) {
      setState(() => _consentLoading = true);
      try {
        final dio = buildAuthDio();
        await dio.post(
            '${EnvConfig.apiBaseUrl}/arras/${widget.offer.id}/buyer/cash-consent');
        ref.invalidate(_arrasHubProvider(widget.offer.id));
      } on DioException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                (e.response?.data?['detail'] as String?) ??
                    'arras_interview.error_save'.tr(),
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _consentLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final arrasAsync =
        ref.watch(_arrasHubProvider(widget.offer.id));
    final currentUser = ref.watch(authProvider).user;
    final isBuyer = currentUser?.id == widget.offer.buyerId;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context, ref),
      body: arrasAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (_, __) => _buildBody(context, isBuyer, null),
        data: (data) {
          _maybeStartPolling(data?['contract_status'] as String?);
          return _buildBody(context, isBuyer, data);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isBuyer,
      Map<String, dynamic>? data) {
    final arrasStatus = data?['arras_status'] as String? ?? 'none';
    final buyerDone = data?['buyer_interview_confirmed'] == true;
    final sellerDone = data?['seller_interview_confirmed'] == true;
    final contractStatus = data?['contract_status'] as String?;
    final hasContract = contractStatus != null;
    final isGenerating = contractStatus == 'generating';
    final fullyAccepted = contractStatus == 'fully_accepted';

    // Cash consent state
    final sellerPaymentType =
        data?['seller_payment_method_type'] as String?;
    final buyerCashConsentAt =
        data?['buyer_cash_consent_at'] as String?;
    final needsCashConsent = isBuyer &&
        sellerDone &&
        sellerPaymentType == 'cash' &&
        buyerCashConsentAt == null;
    final hasCashConsent = isBuyer &&
        sellerPaymentType == 'cash' &&
        buyerCashConsentAt != null;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Hero header ──────────────────────────────────────────
        _HeroCard(
          isBuyer: isBuyer,
          buyerDone: buyerDone,
          sellerDone: sellerDone,
          arrasStatus: arrasStatus,
          offerAmount: widget.offer.amount,
          depositPercentage: data?['deposit_percentage'] as int?,
          deadlineDays: data?['deadline_days'] as int?,
        ),
        const SizedBox(height: 24),

        // ── Cash consent banner (shown when required) ────────────
        if (needsCashConsent) ...[
          _CashConsentBanner(
            loading: _consentLoading,
            onTap: () => _showCashConsentModal(context, ref),
          ),
          const SizedBox(height: 16),
        ],

        // ── Cash consent accepted badge ──────────────────────────
        if (hasCashConsent) ...[
          _CashConsentAcceptedBadge(consentAt: buyerCashConsentAt!),
          const SizedBox(height: 16),
        ],

        // ── Role cards ───────────────────────────────────────────
        _RoleCard(
          title: 'arras_interview.hub_buyer_title'.tr(),
          icon: Icons.person_outlined,
          isMyRole: isBuyer,
          isDone: buyerDone,
          color: _kBlue,
          statusLabel: buyerDone
              ? 'arras_interview.hub_completed'.tr()
              : 'arras_interview.hub_pending'.tr(),
          ctaLabel: isBuyer
              ? (buyerDone
                  ? 'arras_interview.hub_view_edit'.tr()
                  : 'arras_interview.hub_start'.tr())
              : null,
          onCta: isBuyer
              ? () => context.push(
                  '/offers/${widget.offer.id}/arras/buyer',
                  extra: widget.offer)
              : null,
        ),
        const SizedBox(height: 16),

        _RoleCard(
          title: 'arras_interview.hub_seller_title'.tr(),
          icon: Icons.home_outlined,
          isMyRole: !isBuyer,
          isDone: sellerDone,
          color: _kGreen,
          statusLabel: sellerDone
              ? 'arras_interview.hub_completed'.tr()
              : 'arras_interview.hub_pending'.tr(),
          ctaLabel: !isBuyer
              ? (sellerDone
                  ? 'arras_interview.hub_view_edit'.tr()
                  : 'arras_interview.hub_start'.tr())
              : null,
          onCta: !isBuyer
              ? () => context.push(
                  '/offers/${widget.offer.id}/arras/seller',
                  extra: widget.offer)
              : null,
        ),

        // ── Contract section ─────────────────────────────────────
        if (buyerDone && sellerDone) ...[
          const SizedBox(height: 24),
          _ContractCard(
            isGenerating: isGenerating,
            hasContract: hasContract && contractStatus != 'error',
            fullyAccepted: fullyAccepted,
            contractStatus: contractStatus,
            onView: () => context.push(
                '/offers/${widget.offer.id}/arras/contract',
                extra: widget.offer),
            onRegenerate: (contractStatus == 'error' || contractStatus == 'generating')
                ? () => _triggerRegenerate(context, ref)
                : null,
          ),
        ],

        // ── Info box ─────────────────────────────────────────────
        const SizedBox(height: 24),
        _InfoBox(
          icon: Icons.info_outline,
          text: 'arras_interview.hub_info_box'.tr(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
            color: Theme.of(context).colorScheme.outlineVariant,
            height: 1),
      ),
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final isAuthenticated =
                ref.watch(authProvider).isAuthenticated;
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

// ── Cash consent banner ───────────────────────────────────────────────────────

class _CashConsentBanner extends StatelessWidget {
  const _CashConsentBanner({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF97316), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_outlined,
                  color: Color(0xFFEA580C), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'arras_interview.cash_consent_banner_title'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'arras_interview.cash_consent_banner_desc'.tr(),
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF9A3412), height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onTap,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.verified_user_outlined, size: 16),
              label: Text('arras_interview.cash_consent_banner_btn'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cash consent accepted badge ───────────────────────────────────────────────

class _CashConsentAcceptedBadge extends StatelessWidget {
  const _CashConsentAcceptedBadge({required this.consentAt});

  final String consentAt;

  @override
  Widget build(BuildContext context) {
    String dateStr = consentAt;
    try {
      final dt = DateTime.parse(consentAt).toLocal();
      dateStr =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'arras_interview.cash_consent_modal_accepted_badge'
                  .tr(namedArgs: {'date': dateStr}),
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF166534),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cash consent dialog ───────────────────────────────────────────────────────

class _CashConsentDialog extends StatefulWidget {
  const _CashConsentDialog();

  @override
  State<_CashConsentDialog> createState() => _CashConsentDialogState();
}

class _CashConsentDialogState extends State<_CashConsentDialog> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFB923C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gavel_outlined,
                          color: Color(0xFFEA580C), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'arras_interview.cash_consent_modal_title'.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'arras_interview.cash_consent_modal_warning'.tr(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Body text ───────────────────────────────────────
            Text(
              'arras_interview.cash_consent_modal_body'.tr(),
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF374151),
                  height: 1.6),
            ),
            const SizedBox(height: 20),

            // ── Checkbox ────────────────────────────────────────
            InkWell(
              onTap: () => setState(() => _checked = !_checked),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _checked,
                      activeColor: const Color(0xFFEA580C),
                      onChanged: (v) =>
                          setState(() => _checked = v ?? false),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'arras_interview.cash_consent_modal_checkbox'.tr(),
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Buttons ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                        'arras_interview.cash_consent_modal_cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _checked
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    icon: const Icon(Icons.verified_user_outlined,
                        size: 16),
                    label: Text(
                        'arras_interview.cash_consent_modal_accept'.tr()),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      disabledBackgroundColor:
                          const Color(0xFFEA580C).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.isBuyer,
    required this.buyerDone,
    required this.sellerDone,
    required this.arrasStatus,
    required this.offerAmount,
    this.depositPercentage,
    this.deadlineDays,
  });

  final bool isBuyer;
  final bool buyerDone;
  final bool sellerDone;
  final String arrasStatus;
  final int offerAmount;
  final int? depositPercentage;
  final int? deadlineDays;

  String get _statusLabel {
    switch (arrasStatus) {
      case 'accepted':
        return 'arras_interview.hub_status_accepted'.tr();
      case 'contract_ready':
      case 'buyer_accepted':
      case 'seller_accepted':
        return 'arras_interview.hub_status_ready'.tr();
      case 'generating':
        return 'arras_interview.hub_status_generating_ai'.tr();
      case 'both_done':
        return 'arras_interview.hub_status_generating_draft'.tr();
      case 'buyer_done':
        return isBuyer
            ? 'arras_interview.hub_status_buyer_done_buyer'.tr()
            : 'arras_interview.hub_status_buyer_done_seller'.tr();
      case 'seller_done':
        return !isBuyer
            ? 'arras_interview.hub_status_seller_done_seller'.tr()
            : 'arras_interview.hub_status_seller_done_buyer'.tr();
      default:
        return 'arras_interview.hub_status_default'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF135BEC), Color(0xFF135BEC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.handshake_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'arras_interview.hub_hero_title'.tr(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'arras_interview.hub_hero_subtitle'.tr(),
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _statusLabel,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label:
                    '${CurrencyInputFormatter.format(offerAmount)} EUR',
                icon: Icons.euro_outlined,
              ),
              if (depositPercentage != null)
                _Chip(
                  label: 'arras_interview.hub_hero_arras_pct'.tr(
                      namedArgs: {
                        'pct': depositPercentage.toString()
                      }),
                  icon: Icons.payments_outlined,
                ),
              if (deadlineDays != null)
                _Chip(
                  label: 'arras_interview.hub_hero_deadline'.tr(
                      namedArgs: {'days': deadlineDays.toString()}),
                  icon: Icons.schedule_outlined,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusDot(
                  label: 'arras_interview.hub_hero_buyer'.tr(),
                  active: buyerDone,
                  color: _kGreen),
              const SizedBox(width: 16),
              _StatusDot(
                  label: 'arras_interview.hub_hero_seller'.tr(),
                  active: sellerDone,
                  color: _kGreen),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot(
      {required this.label, required this.active, required this.color});

  final String label;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          active ? Icons.check_circle : Icons.radio_button_unchecked,
          color: active ? color : Colors.white38,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight:
                active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.icon,
    required this.isMyRole,
    required this.isDone,
    required this.color,
    required this.statusLabel,
    this.ctaLabel,
    this.onCta,
  });

  final String title;
  final IconData icon;
  final bool isMyRole;
  final bool isDone;
  final Color color;
  final String statusLabel;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? color.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: isDone ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDone
                  ? color.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isDone ? color : Colors.grey.shade400,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDone
                              ? const Color(0xFF135BEC)
                              : Colors.grey.shade600,
                        )),
                    if (isMyRole) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                            'arras_interview.hub_role_you'.tr(),
                            style: TextStyle(
                                color: _kBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isDone ? color : Colors.grey.shade400,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(statusLabel,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDone
                                ? color
                                : Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onCta,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDone ? Colors.grey.shade200 : color,
                foregroundColor: isDone ? color : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Text(isDone
                  ? 'arras_interview.hub_btn_view'.tr()
                  : 'arras_interview.hub_btn_start'.tr()),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({
    required this.isGenerating,
    required this.hasContract,
    required this.fullyAccepted,
    required this.contractStatus,
    required this.onView,
    this.onRegenerate,
  });

  final bool isGenerating;
  final bool hasContract;
  final bool fullyAccepted;
  final String? contractStatus;
  final VoidCallback onView;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    IconData cardIcon;
    String cardTitle;
    String cardSubtitle;

    if (fullyAccepted) {
      cardColor = _kGreen;
      cardIcon = Icons.verified_outlined;
      cardTitle = 'arras_interview.hub_contract_accepted_title'.tr();
      cardSubtitle =
          'arras_interview.hub_contract_accepted_desc'.tr();
    } else if (contractStatus == 'error') {
      cardColor = Colors.red.shade700;
      cardIcon = Icons.error_outline;
      cardTitle = 'arras_interview.hub_contract_error_title'.tr();
      cardSubtitle = 'arras_interview.hub_contract_error_desc'.tr();
    } else if (isGenerating) {
      cardColor = _kBlue;
      cardIcon = Icons.auto_awesome_outlined;
      cardTitle =
          'arras_interview.hub_contract_generating_title'.tr();
      cardSubtitle =
          'arras_interview.hub_contract_generating_desc'.tr();
    } else if (hasContract) {
      cardColor = const Color(0xFFD97706);
      cardIcon = Icons.description_outlined;
      cardTitle = 'arras_interview.hub_contract_ready_title'.tr();
      cardSubtitle =
          'arras_interview.hub_contract_ready_desc'.tr();
    } else {
      cardColor = _kBlue;
      cardIcon = Icons.hourglass_empty_outlined;
      cardTitle =
          'arras_interview.hub_contract_pending_title'.tr();
      cardSubtitle =
          'arras_interview.hub_contract_pending_desc'.tr();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isGenerating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: cardColor, strokeWidth: 2))
                : Icon(cardIcon, color: cardColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cardTitle,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: cardColor)),
                Text(cardSubtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (onRegenerate != null) ...[
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onRegenerate,
              icon: const Icon(Icons.refresh, size: 14),
              label: Text('arras_interview.hub_contract_retry_btn'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: contractStatus == 'error'
                    ? Colors.red.shade700
                    : _kBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ] else if (hasContract && !isGenerating) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onView,
              style: FilledButton.styleFrom(
                backgroundColor: cardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Text(
                  'arras_interview.hub_contract_view_btn'.tr()),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final bg = isDark ? const Color(0xFF0D1A3A) : Colors.blue.shade50;
    final iconColor = isDark ? colorScheme.primary : Colors.blue.shade700;
    final textColor = isDark ? colorScheme.primary : Colors.blue.shade800;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
