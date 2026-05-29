import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/formatters/currency_input_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/offers_provider.dart';
import '../../providers/solvency_provider.dart' as solvency_prov;
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../../../core/config/env_config.dart';
import '../../../core/network/dio_factory.dart';

final _arrasStatusProvider = FutureProvider.autoDispose
    .family<String, String>((ref, offerId) async {
  final token =
      await const FlutterSecureStorage().read(key: 'auth_token');
  if (token == null) return 'none';
  final dio = buildAuthDio();
  try {
    final resp = await dio.get(
      '${EnvConfig.apiBaseUrl}/arras/$offerId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (resp.data as Map<String, dynamic>)['arras_status'] as String? ??
        'none';
  } catch (_) {
    return 'none';
  }
});

final _tasacionStatusProvider = FutureProvider.autoDispose
    .family<String, String>((ref, offerId) async {
  final token =
      await const FlutterSecureStorage().read(key: 'auth_token');
  if (token == null) return 'pending';
  final dio = buildAuthDio();
  try {
    final resp = await dio.get(
      '${EnvConfig.apiBaseUrl}/tasacion/$offerId/status',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (resp.data as Map<String, dynamic>)['appointment_status']
            as String? ??
        'pending';
  } catch (_) {
    return 'pending';
  }
});

final _notariaStatusProvider = FutureProvider.autoDispose
    .family<String, String>((ref, offerId) async {
  final token = await const FlutterSecureStorage().read(key: 'auth_token');
  if (token == null) return 'pending';
  try {
    final resp = await buildAuthDio().get(
      '${EnvConfig.apiBaseUrl}/notaria-appt/$offerId/status',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (resp.data as Map<String, dynamic>)['appointment_status']
            as String? ??
        'pending';
  } catch (_) {
    return 'pending';
  }
});

final _postVentaAllDoneProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, offerId) async {
  final token = await const FlutterSecureStorage().read(key: 'auth_token');
  if (token == null) return false;
  try {
    final resp = await buildAuthDio().get(
      '${EnvConfig.apiBaseUrl}/post-sale/$offerId/status',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = resp.data as Map<String, dynamic>;
    const keys = ['electricity', 'water', 'gas', 'ibi', 'community'];
    return keys.every((k) {
      final v = data[k] as Map<String, dynamic>?;
      final st = v?['status'] as String?;
      return st != null && st != 'uploading';
    });
  } catch (_) {
    return false;
  }
});

/// Transaction timeline screen — shows the lifecycle of a purchase offer.
class TransactionTimelineScreen extends ConsumerWidget {
  const TransactionTimelineScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Leer la oferta en vivo desde los providers para que el timeline
    // se redibuje tras mutaciones (aceptar/rechazar solvencia, etc.).
    // Fallback al snapshot de GoRouter si los providers aun no cargaron.
    final receivedList = ref.watch(receivedOffersProvider).asData?.value;
    final sentList = ref.watch(sentOffersProvider).asData?.value;
    final liveOffer =
        receivedList?.firstWhereOrNull((o) => o.id == offer.id) ??
        sentList?.firstWhereOrNull((o) => o.id == offer.id) ??
        offer;

    final currentUser = ref.watch(authProvider).user;
    final isBuyer = currentUser?.id == liveOffer.buyerId;
    final s = liveOffer.status.toLowerCase();
    // Buyer can withdraw while arras not yet signed (not counter_offer — buyer has dedicated actions there)
    final canWithdraw = isBuyer &&
        (s == 'pending' || s == 'accepted' || s == 'signing_pending');
    // Multi-buyer: check if a second identity verification step is needed
    final passportAsync = isBuyer
        ? ref.watch(solvency_prov.mySolvencyProvider)
        : const AsyncData<solvency_prov.SolvencyPassport?>(null);
    final needsSecondIdentity = passportAsync.when(
      data: (p) => p?.needsSecondIdentityVerification ?? false,
      loading: () => false,
      error: (_, __) => false,
    );
    // Passport is considered complete when it exists and has not expired
    final hasPassport = passportAsync.when(
      data: (p) => p != null && p.isValid,
      loading: () => true, // avoid CTA flicker while loading
      error: (_, __) => false,
    );
    // Multi-buyer: buyer marked compra conjunta in their solvency wizard
    final isMultiBuyer = passportAsync.when(
      data: (p) => p?.isMultiBuyer ?? false,
      loading: () => false,
      error: (_, __) => false,
    );

    // Arras status (only relevant when stage == 2)
    final arrasStatus = s == 'signing_pending'
        ? ref.watch(_arrasStatusProvider(liveOffer.id)).asData?.value ?? 'none'
        : 'none';

    // Tasacion appointment status (only relevant when stage == 3)
    final tasacionApptStatus = s == 'signed'
        ? ref.watch(_tasacionStatusProvider(liveOffer.id)).asData?.value ??
            'pending'
        : 'pending';

    // FEIN buyer confirmation — shared live provider (authoritative, avoids stale cache)
    final feinBuyerConfirmed = s == 'signed'
        ? ref.watch(feinConfirmedProvider(liveOffer.id)).asData?.value ??
            liveOffer.feinBuyerConfirmed
        : (s == 'completed' ? true : false);

    // Notaria appointment status — live query when gate is open
    final notariaGateOpen = feinBuyerConfirmed || s == 'completed';
    final notariaApptStatus = notariaGateOpen
        ? ref.watch(_notariaStatusProvider(liveOffer.id)).asData?.value ??
            liveOffer.notariaApptStatus ??
            'pending'
        : liveOffer.notariaApptStatus ?? 'pending';

    // Post-venta completion — live query only when offer is fully completed
    final postVentaDone = s == 'completed'
        ? (ref.watch(_postVentaAllDoneProvider(liveOffer.id)).asData?.value ?? false)
        : false;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context, ref),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── Header cards ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _HeaderCards(offer: liveOffer),
                ),
                // ── Title ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
                  child: Text(
                    'transaction.timeline_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'transaction.timeline_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // ── Timeline (botones de acción embebidos en la tarjeta activa) ─
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                  child: _TimelineWidget(steps: _buildSteps(
                    context,
                    liveOffer,
                    isBuyer: isBuyer,
                    hasPassport: hasPassport,
                    needsSecondIdentity: needsSecondIdentity,
                    isMultiBuyer: isMultiBuyer,
                    confirmedVisitDate: liveOffer.confirmedVisitDate,
                    requestedVisitDate: liveOffer.requestedVisitDate,
                    visitStatus: liveOffer.visitStatus,
                    arrasStatus: arrasStatus,
                    tasacionApptStatus: tasacionApptStatus,
                    feinBuyerConfirmed: feinBuyerConfirmed,
                    notariaApptStatus: notariaApptStatus,
                    postVentaDone: postVentaDone,
                    buyerActions: isBuyer && s == 'counter_offer'
                        ? _BuyerCounterOfferActions(offer: liveOffer)
                        : null,
                    sellerActions: !isBuyer && s == 'pending'
                        ? _SellerPendingOfferActions(offer: liveOffer)
                        : null,
                    // Withdraw in step 0 only for pending/counter_offer
                    withdrawAction:
                        canWithdraw && (s == 'pending' || s == 'counter_offer')
                            ? _WithdrawOfferButton(offer: liveOffer)
                            : null,
                    // Solvency step: seller ve pasaporte+botones SOLO si aun no acepto.
                    // Tras aceptar solvencia, la seccion desaparece y el paso queda completado.
                    solvencyActionsWidget: s == 'accepted'
                        ? (!isBuyer && !liveOffer.sellerSolvencyAccepted
                            ? _SellerSolvencySection(offer: liveOffer)
                            : (isBuyer ? _WithdrawOfferButton(offer: liveOffer) : null))
                        : null,
                  )),
                ),
                // ── Congratulations banner (post-venta fully done) ──────────
                if (postVentaDone && s == 'completed')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _CongratsBanner(isBuyer: isBuyer),
                  ),
                // ── Help footer ─────────────────────────────────────────────
                const _HelpFooter(),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // ── Bottom brand bar ────────────────────────────────────────────
          const _BrandBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      automaticallyImplyLeading: false,
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
      title: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
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
                        style: TextStyle(color: Color(0xFF135BEC))),
                    TextSpan(
                        text: 'Fácil',
                        style: TextStyle(color: Color(0xFF16A34A))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
      ),
      actions: [
        Builder(builder: (context) {
          final isMobile = MediaQuery.of(context).size.width < 650;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile) ...[
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF135BEC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.home_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('common.home'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: UserAvatarMenu(),
              ),
            ],
          );
        }),
      ],
    );
  }

  List<_TimelineStep> _buildSteps(
    BuildContext context,
    OfferData offerData, {
    required bool isBuyer,
    bool hasPassport = false,
    bool needsSecondIdentity = false,
    bool isMultiBuyer = false,
    String? confirmedVisitDate,
    String? requestedVisitDate,
    String? visitStatus,
    String arrasStatus = 'none',
    String tasacionApptStatus = 'pending',
    bool feinBuyerConfirmed = false,
    String notariaApptStatus = 'pending',
    bool postVentaDone = false,
    Widget? buyerActions,
    Widget? sellerActions,
    Widget? withdrawAction,
    Widget? solvencyActionsWidget,
  }) {
    final s = offerData.status.toLowerCase();

    // Map offer status to pipeline stage index:
    // 0 = pending (offer not yet accepted)
    // 1 = accepted (offer accepted, solvency check in progress)
    // 2 = signing_pending (arras contract pending signatures)
    // 3 = signed (arras signed, mortgage management)
    // 4 = completed (notary signed, transaction finished)
    // -1 = rejected / cancelled
    final int stage;
    switch (s) {
      case 'pending':
      case 'counter_offer':
        stage = 0;
      case 'accepted':
        stage = 1;
      case 'signing_pending':
        stage = 2;
      case 'signed':
        stage = 3;
      case 'completed':
        stage = 4;
      default: // rejected, withdrawn, cancelled
        stage = -1;
    }

    _StepState stepState(int stepIndex) {
      if (stage < 0) return _StepState.locked;
      if (stepIndex < stage) return _StepState.done;
      if (stepIndex == stage) return _StepState.active;
      return _StepState.locked;
    }

    // Combina los botones de acción para el paso 0 si aplica
    Widget? step0Actions;
    if (buyerActions != null || sellerActions != null || withdrawAction != null) {
      step0Actions = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (buyerActions != null) buyerActions,
          if (sellerActions != null) sellerActions,
          if (withdrawAction != null) ...[const SizedBox(height: 8), withdrawAction],
        ],
      );
    }

    // FEIN only applies to purchases with bank financing.
    // If paymentMethod is null (solvency not yet submitted), default to showing it.
    const feinPaymentMethods = {
      'mortgage_pending',
      'mortgage_approved',
      'savings_plus_mortgage',
      'bridge_mortgage',
    };
    final requiresFein = offerData.paymentMethod == null ||
        feinPaymentMethods.contains(offerData.paymentMethod);

    final steps = <_TimelineStep>[
      _TimelineStep(
        title: stage == 0
            ? 'transaction.offer_sent'.tr()
            : stage > 0
                ? 'transaction.offer_accepted_step'.tr()
                : (s == 'withdrawn' ? 'transaction.offer_withdrawn_step'.tr() : 'transaction.offer_rejected_step'.tr()),
        subtitle: stage > 0
            ? 'transaction.seller_accepted_offer'.tr()
            : stage == 0
                ? (s == 'counter_offer'
                    ? 'transaction.seller_counter_offered'.tr(namedArgs: {
                        'amount': '${CurrencyInputFormatter.format(offerData.amount)} €',
                      })
                    : 'transaction.pending_seller_response'.tr())
                : (s == 'withdrawn' ? 'transaction.withdrawn_by_buyer'.tr() : 'transaction.rejected_by_seller'.tr()),
        state: stage < 0 ? _StepState.locked : stepState(0),
        actionsWidget: step0Actions,
      ),
      _TimelineStep(
        title: 'transaction.solvency_title'.tr(),
        subtitle: stage > 1 || offerData.sellerSolvencyAccepted
            ? 'transaction.solvency_validated'.tr()
            : stage == 1
                ? 'transaction.solvency_verifying'.tr()
                : 'transaction.solvency_pending_offer'.tr(),
        state: offerData.sellerSolvencyAccepted
            ? _StepState.done
            : stepState(1),
        ctaLabel: isBuyer && stage == 1 && !hasPassport
            ? 'transaction.complete_passport_btn'.tr()
            : null,
        ctaIcon: isBuyer && stage == 1 && !hasPassport
            ? Icons.verified_user_outlined
            : null,
        ctaCallback: isBuyer && stage == 1 && !hasPassport
            ? () => context.go('/solvency/wizard')
            : null,
        actionsWidget: solvencyActionsWidget,
      ),
      // Paso condicional: visible mientras el segundo comprador no haya verificado
      // su identidad. Desaparece automaticamente cuando second_buyer_pending = false.
      if (needsSecondIdentity || offerData.secondBuyerPending)
        _TimelineStep(
          title: 'transaction.second_buyer_title'.tr(),
          subtitle: offerData.secondBuyerPending
              ? (isBuyer
                  ? 'transaction.second_buyer_pending_buyer'.tr()
                  : 'transaction.second_buyer_pending_seller'.tr())
              : 'transaction.second_buyer_confirmed'.tr(),
          description: offerData.secondBuyerPending && isBuyer
              ? 'transaction.second_buyer_desc'.tr()
              : null,
          state: offerData.secondBuyerPending
              ? _StepState.active
              : _StepState.done,
          ctaLabel: isBuyer && offerData.secondBuyerPending
              ? 'transaction.add_second_buyer_btn'.tr()
              : null,
          ctaIcon: isBuyer && offerData.secondBuyerPending
              ? Icons.person_add_alt_1_outlined
              : null,
          ctaCallback: isBuyer && offerData.secondBuyerPending
              ? () => context.push('/solvency/second-buyer')
              : null,
        ),
      _TimelineStep(
        title: 'transaction.arras_title'.tr(),
        subtitle: stage > 2
            ? 'transaction.arras_signed_both'.tr()
            : stage == 2
                ? _arrasSubtitle(arrasStatus, isBuyer)
                : 'transaction.arras_pending_solvency'.tr(),
        description: stage == 2 &&
                arrasStatus != 'accepted'
            ? 'transaction.arras_description'.tr()
            : null,
        state: arrasStatus == 'accepted' ? _StepState.done : stepState(2),
        ctaLabel: stage == 2 ? _arrasCtaLabel(arrasStatus, isBuyer) : null,
        ctaIcon: stage == 2 ? _arrasCtaIcon(arrasStatus) : null,
        ctaCallback: stage == 2
            ? () => context.push('/offers/${offerData.id}/arras', extra: offerData)
            : null,
      ),
      _TimelineStep(
        title: 'transaction.appraisal_title'.tr(),
        subtitle: stage > 3
            ? 'transaction.appraisal_done'.tr()
            : stage == 3
                ? _tasacionSubtitle(tasacionApptStatus, isBuyer)
                : 'transaction.appraisal_pending_arras'.tr(),
        state: tasacionApptStatus == 'completed' && stage == 3
            ? _StepState.done
            : stepState(3),
        ctaLabel: stage == 3
            ? _tasacionCtaLabel(tasacionApptStatus, isBuyer)
            : null,
        ctaIcon: stage == 3
            ? _tasacionCtaIcon(tasacionApptStatus, isBuyer)
            : null,
        ctaCallback: stage == 3 &&
                _tasacionCtaLabel(tasacionApptStatus, isBuyer) != null
            ? () => context.push(
                '/offers/${offerData.id}/tasacion',
                extra: offerData,
              )
            : null,
      ),
      if (requiresFein)
        _TimelineStep(
          title: 'transaction.fein_title'.tr(),
          subtitle: stage > 3 || feinBuyerConfirmed
              ? 'transaction.fein_confirmed_sub'.tr()
              : stage == 3 && tasacionApptStatus == 'completed'
                  ? (isBuyer
                      ? 'transaction.fein_buyer_pending'.tr()
                      : 'transaction.fein_seller_pending'.tr())
                  : stage == 3
                      ? 'transaction.fein_pending_appraisal'.tr()
                      : 'transaction.fein_locked'.tr(),
          state: stage > 3 || feinBuyerConfirmed
              ? _StepState.done
              : (stage == 3 && tasacionApptStatus == 'completed'
                  ? _StepState.active
                  : _StepState.locked),
          ctaLabel: (isBuyer && stage == 3 && tasacionApptStatus == 'completed' && !feinBuyerConfirmed)
              ? 'transaction.fein_confirm_btn'.tr()
              : null,
          ctaIcon: (isBuyer && stage == 3 && tasacionApptStatus == 'completed' && !feinBuyerConfirmed)
              ? Icons.account_balance_outlined
              : null,
          ctaCallback: (isBuyer && stage == 3 && tasacionApptStatus == 'completed' && !feinBuyerConfirmed)
              ? () => context.push('/offers/${offerData.id}/fein', extra: offerData)
              : null,
        ),
      _TimelineStep(
        title: 'transaction.notary_title'.tr(),
        subtitle: stage >= 4
            ? 'transaction.notary_done'.tr()
            : feinBuyerConfirmed
                ? _notariaSubtitle(notariaApptStatus, isBuyer)
                : 'transaction.notary_pending_fein'.tr(),
        state: stage >= 4
            ? _StepState.done
            : feinBuyerConfirmed
                ? _StepState.active
                : _StepState.locked,
        ctaLabel: (feinBuyerConfirmed || stage >= 4)
            ? _notariaCtaLabel(notariaApptStatus, isBuyer, stage)
            : null,
        ctaIcon: (feinBuyerConfirmed || stage >= 4)
            ? _notariaCtaIcon(notariaApptStatus, isBuyer, stage)
            : null,
        ctaCallback: (feinBuyerConfirmed || stage >= 4)
            ? () => context.push('/offers/${offerData.id}/notaria', extra: offerData)
            : null,
      ),
      _TimelineStep(
        title: 'transaction.post_sale_title'.tr(),
        subtitle: stage >= 4
            ? 'transaction.post_sale_subtitle'.tr()
            : 'transaction.post_sale_locked'.tr(),
        state: stage >= 4 ? _StepState.active : _StepState.locked,
        completedBadge: postVentaDone,
        ctaLabel: stage >= 4 ? 'transaction.post_sale_btn'.tr() : null,
        ctaIcon: stage >= 4 ? Icons.receipt_long_outlined : null,
        ctaCallback: stage >= 4
            ? () => context.push('/offers/${offerData.id}/post-venta', extra: offerData)
            : null,
      ),
    ];

    // Insert visit step after "Oferta" when there is any visit activity
    final isVisitConfirmed =
        visitStatus == 'approved' || visitStatus == 'completed';
    final isVisitPending =
        visitStatus == 'requested';
    final hasVisit = (confirmedVisitDate != null && confirmedVisitDate.isNotEmpty) ||
        (requestedVisitDate != null && requestedVisitDate.isNotEmpty);

    if (hasVisit) {
      final visitDate = isVisitConfirmed
          ? confirmedVisitDate
          : requestedVisitDate ?? confirmedVisitDate;

      steps.insert(
        1,
        _TimelineStep(
          title: isVisitConfirmed ? 'transaction.visit_confirmed_step'.tr() : 'transaction.visit_requested_step'.tr(),
          subtitle: isVisitConfirmed
              ? 'transaction.visit_date_confirmed'.tr(namedArgs: {'date': visitDate ?? ''})
              : isVisitPending
                  ? 'transaction.visit_date_pending'.tr(namedArgs: {'date': visitDate ?? ''})
                  : 'transaction.visit_date_last'.tr(namedArgs: {'date': visitDate ?? ''}),
          state: isVisitConfirmed ? _StepState.done : _StepState.active,
          ctaLabel: 'transaction.visit_btn'.tr(),
          ctaIcon: Icons.calendar_month_outlined,
          ctaRoute: '/profile?tab=3',
        ),
      );
    }

    return steps;
  }

  // ── Arras step helpers ──────────────────────────────────────────────────

  String _arrasSubtitle(String arrasStatus, bool isBuyer) {
    switch (arrasStatus) {
      case 'accepted':
        return 'transaction.arras_signed_both'.tr();
      case 'contract_ready':
      case 'buyer_accepted':
      case 'seller_accepted':
        return 'transaction.arras_contract_ready'.tr();
      case 'generating':
        return 'transaction.arras_generating'.tr();
      case 'both_done':
        return 'transaction.arras_both_done'.tr();
      case 'buyer_done':
        return isBuyer
            ? 'transaction.arras_buyer_done_buyer'.tr()
            : 'transaction.arras_buyer_done_seller'.tr();
      case 'seller_done':
        return !isBuyer
            ? 'transaction.arras_seller_done_seller'.tr()
            : 'transaction.arras_seller_done_buyer'.tr();
      default:
        return 'transaction.arras_complete_yours'.tr();
    }
  }

  String? _arrasCtaLabel(String arrasStatus, bool isBuyer) {
    switch (arrasStatus) {
      case 'accepted':
        return null;
      case 'contract_ready':
      case 'buyer_accepted':
      case 'seller_accepted':
        return 'transaction.arras_review_btn'.tr();
      case 'generating':
      case 'both_done':
        return 'transaction.arras_view_status_btn'.tr();
      default:
        return isBuyer ? 'transaction.arras_start_btn'.tr() : 'transaction.arras_complete_btn'.tr();
    }
  }

  IconData? _arrasCtaIcon(String arrasStatus) {
    switch (arrasStatus) {
      case 'contract_ready':
      case 'buyer_accepted':
      case 'seller_accepted':
        return Icons.description_outlined;
      case 'generating':
      case 'both_done':
        return Icons.auto_awesome_outlined;
      default:
        return Icons.edit_outlined;
    }
  }

  // ── Tasacion step helpers ────────────────────────────────────────────────

  String _tasacionSubtitle(String apptStatus, bool isBuyer) {
    switch (apptStatus) {
      case 'completed':
        return 'transaction.appraisal_completed_sub'.tr();
      case 'accepted':
        return isBuyer
            ? 'transaction.appraisal_accepted_buyer'.tr()
            : 'transaction.appraisal_accepted_seller'.tr();
      case 'rejected':
        return isBuyer
            ? 'transaction.appraisal_rejected_buyer'.tr()
            : 'transaction.appraisal_rejected_seller'.tr();
      case 'proposed':
        return isBuyer
            ? 'transaction.appraisal_proposed_buyer'.tr()
            : 'transaction.appraisal_proposed_seller'.tr();
      default:
        return isBuyer
            ? 'transaction.appraisal_pending_buyer'.tr()
            : 'transaction.appraisal_pending_seller'.tr();
    }
  }

  String? _tasacionCtaLabel(String apptStatus, bool isBuyer) {
    switch (apptStatus) {
      case 'completed':
        return null;
      case 'accepted':
        return isBuyer ? 'transaction.appraisal_see_confirmed_btn'.tr() : 'transaction.appraisal_confirm_visit_btn'.tr();
      case 'rejected':
        return isBuyer
            ? 'transaction.appraisal_see_seller_btn'.tr()
            : 'transaction.appraisal_waiting_buyer_btn'.tr();
      case 'proposed':
        return isBuyer
            ? 'transaction.appraisal_see_proposal_btn'.tr()
            : 'transaction.appraisal_accept_reject_btn'.tr();
      default:
        return isBuyer ? 'transaction.appraisal_schedule_btn'.tr() : null;
    }
  }

  IconData? _tasacionCtaIcon(String apptStatus, bool isBuyer) {
    switch (apptStatus) {
      case 'accepted':
        return isBuyer
            ? Icons.event_available_outlined
            : Icons.check_circle_outline;
      case 'rejected':
        return isBuyer ? Icons.event_outlined : Icons.hourglass_empty_outlined;
      case 'proposed':
        return isBuyer
            ? Icons.pending_outlined
            : Icons.edit_calendar_outlined;
      default:
        return isBuyer ? Icons.home_work_outlined : null;
    }
  }

  // ── Notaria step helpers ─────────────────────────────────────────────────

  String _notariaSubtitle(String apptStatus, bool isBuyer) {
    switch (apptStatus) {
      case 'completed':
        return 'transaction.notary_signing_done'.tr();
      case 'scheduled':
        return 'transaction.notary_scheduled'.tr();
      default:
        return isBuyer
            ? 'transaction.notary_buyer_pending'.tr()
            : 'transaction.notary_seller_pending'.tr();
    }
  }

  String? _notariaCtaLabel(String apptStatus, bool isBuyer, int stage) {
    if (stage >= 4) return 'transaction.notary_view_status'.tr();
    switch (apptStatus) {
      case 'completed':
      case 'scheduled':
        return 'transaction.notary_confirm_signing_btn'.tr();
      default:
        return isBuyer ? 'transaction.notary_propose_btn'.tr() : 'transaction.notary_view_status_btn'.tr();
    }
  }

  IconData? _notariaCtaIcon(String apptStatus, bool isBuyer, int stage) {
    if (stage >= 4) return Icons.gavel_outlined;
    switch (apptStatus) {
      case 'completed':
      case 'scheduled':
        return Icons.key_outlined;
      default:
        return isBuyer ? Icons.calendar_today_outlined : Icons.hourglass_empty_outlined;
    }
  }
}

// ── Header cards (property + counterparty) ───────────────────────────────────

class _HeaderCards extends StatelessWidget {
  const _HeaderCards({required this.offer});

  final OfferData offer;

  @override
  Widget build(BuildContext context) {
    final title = offer.propertyTitle ?? 'transaction.property_fallback'.tr();
    final price = offer.propertyPrice;
    final counterparty = offer.buyerName ?? 'transaction.counterparty_fallback'.tr();
    final counterPhotoUrl = offer.buyerPhotoUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final propertyCard = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D2010) : const Color(0xFFEEF6EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.home_outlined,
                color: Color(0xFF16A34A), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (price != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(price),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF135BEC),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final buyerCard = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'transaction.buyer_header_label'.tr(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                counterparty,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFDBEAFE),
                backgroundImage: (counterPhotoUrl != null &&
                        counterPhotoUrl.isNotEmpty)
                    ? NetworkImage(counterPhotoUrl)
                    : null,
                child: (counterPhotoUrl == null || counterPhotoUrl.isEmpty)
                    ? Text(
                        counterparty.isNotEmpty
                            ? counterparty[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Color(0xFF135BEC),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              propertyCard,
              const SizedBox(height: 10),
              buyerCard,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: propertyCard),
            const SizedBox(width: 10),
            buyerCard,
          ],
        );
      },
    );
  }

  String _formatPrice(int value) =>
      '${CurrencyInputFormatter.format(value)}\u20AC';
}

// ── Timeline ─────────────────────────────────────────────────────────────────

enum _StepState { done, active, locked }

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.state,
    this.description,
    this.ctaLabel,
    this.ctaIcon,
    this.ctaRoute,
    this.ctaCallback,
    this.actionsWidget,
    this.completedBadge = false,
  });

  final String title;
  final String subtitle;
  final _StepState state;
  final String? description;
  /// Optional call-to-action shown in the active card. Null = no button.
  final String? ctaLabel;
  final IconData? ctaIcon;
  /// GoRouter path to navigate on CTA tap (uses context.go). Ignored if ctaCallback is set.
  final String? ctaRoute;
  /// Direct callback for navigation — use when extra data must be passed (context.push with extra:).
  final VoidCallback? ctaCallback;
  /// Optional widget (e.g. action buttons) rendered at the bottom of the active card.
  final Widget? actionsWidget;
  /// When true, the active card badge shows "FINALIZADO" (green) instead of "EN CURSO" (blue).
  final bool completedBadge;
}

class _TimelineWidget extends StatelessWidget {
  const _TimelineWidget({required this.steps});

  final List<_TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (i) {
        return _StepRow(
          step: steps[i],
          isLast: i == steps.length - 1,
        );
      }),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    switch (step.state) {
      case _StepState.done:
        return _DoneRow(step: step, isLast: isLast);
      case _StepState.active:
        return _ActiveRow(step: step, isLast: isLast);
      case _StepState.locked:
        return _LockedRow(step: step, isLast: isLast);
    }
  }
}

// Done step: green checkmark + title + subtitle
class _DoneRow extends StatelessWidget {
  const _DoneRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DotColumn(
          isLast: isLast,
          dot: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 18, color: Colors.white),
          ),
          lineColor: const Color(0xFF16A34A),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                if (step.ctaLabel != null &&
                    (step.ctaCallback != null || step.ctaRoute != null)) ...[
                  const SizedBox(height: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                    onTap: step.ctaCallback ?? () => context.go(step.ctaRoute!),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(step.ctaIcon ?? Icons.arrow_forward,
                            size: 14, color: const Color(0xFF135BEC)),
                        const SizedBox(width: 4),
                        Text(
                          step.ctaLabel!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF135BEC),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Active step: dot + expanded card with CTA.
// When completedBadge=true the accent colour switches from blue to green.
class _ActiveRow extends StatelessWidget {
  const _ActiveRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  static const _blue = Color(0xFF135BEC);
  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final done = step.completedBadge;
    final accent = done ? _green : _blue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DotColumn(
            isLast: isLast,
            dot: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.edit_document,
                size: 18,
                color: Colors.white,
              ),
            ),
            lineColor: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Builder(builder: (context) {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: done
                                  ? (isDark ? const Color(0xFF0D2010) : const Color(0xFFDCFCE7))
                                  : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF)),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: done
                                    ? (isDark ? _green : const Color(0xFF86EFAC))
                                    : (isDark ? const Color(0xFF3B82F6) : const Color(0xFFBFDBFE)),
                              ),
                            ),
                            child: Text(
                              done
                                  ? 'transaction.status_done'.tr()
                                  : 'transaction.status_in_progress'.tr(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: done ? _green : _blue,
                                letterSpacing: 0.4,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    if (step.description != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        step.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFB0BEC5)
                              : const Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (step.ctaLabel != null) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: step.ctaCallback ??
                              (step.ctaRoute != null
                                  ? () => context.go(step.ctaRoute!)
                                  : null),
                          icon: Icon(step.ctaIcon ?? Icons.arrow_forward, size: 16),
                          label: Text(
                            step.ctaLabel!,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                    if (step.actionsWidget != null) ...[
                      const SizedBox(height: 16),
                      step.actionsWidget!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
  }
}

// Locked step: lock icon + gray text
class _LockedRow extends StatelessWidget {
  const _LockedRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DotColumn(
          isLast: isLast,
          dot: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
            ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 16, color: Color(0xFFCBD5E1)),
            ),
            lineColor: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
  }
}

// Shared dot+line column
class _DotColumn extends StatelessWidget {
  const _DotColumn({
    required this.dot,
    required this.isLast,
    required this.lineColor,
  });

  final Widget dot;
  final bool isLast;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          if (!isLast)
            Container(width: 2, height: 32, color: lineColor),
        ],
      ),
    );
  }
}

// ── Help footer ───────────────────────────────────────────────────────────────

class _HelpFooter extends StatelessWidget {
  const _HelpFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            'transaction.help_question'.tr(),
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 15, color: Color(0xFF135BEC)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'transaction.talk_to_advisor'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF135BEC),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF135BEC),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Withdraw offer button ─────────────────────────────────────────────────────

class _WithdrawOfferButton extends ConsumerStatefulWidget {
  const _WithdrawOfferButton({required this.offer});
  final OfferData offer;

  @override
  ConsumerState<_WithdrawOfferButton> createState() => _WithdrawOfferButtonState();
}

class _WithdrawOfferButtonState extends ConsumerState<_WithdrawOfferButton> {
  bool _loading = false;

  Future<void> _confirmAndWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('transaction.withdraw_dialog_title'.tr()),
        content: Text('transaction.withdraw_dialog_content'.tr()),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.withdraw'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await ref.read(sentOffersProvider.notifier).withdraw(widget.offer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('transaction.withdraw_ok'.tr())),
        );
        context.go('/profile?tab=2');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('transaction.withdraw_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _confirmAndWithdraw,
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
            )
          : const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
      label: Text(
        'transaction.withdraw_offer_btn'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Buyer counter-offer action panel ─────────────────────────────────────────

class _BuyerCounterOfferActions extends ConsumerStatefulWidget {
  const _BuyerCounterOfferActions({required this.offer});
  final OfferData offer;

  @override
  ConsumerState<_BuyerCounterOfferActions> createState() =>
      _BuyerCounterOfferActionsState();
}

class _BuyerCounterOfferActionsState
    extends ConsumerState<_BuyerCounterOfferActions> {
  bool _loading = false;

  Future<void> _accept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('transaction.accept_counter_title'.tr()),
        content: Text(
          'transaction.accept_counter_content'.tr(namedArgs: {'amount': CurrencyInputFormatter.format(widget.offer.amount)}),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF135BEC),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.accept'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref.read(sentOffersProvider.notifier).accept(widget.offer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('transaction.accept_counter_ok'.tr())),
        );
        context.go('/');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('transaction.accept_counter_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _counterBack() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'transaction.new_offer_title_part1'.tr(),
                style: const TextStyle(
                  color: Color(0xFF135BEC),
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'transaction.new_offer_title_part2'.tr(),
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            decoration: InputDecoration(
              labelText: 'transaction.new_offer_amount_label'.tr(),
              suffixText: ' €',
              border: const OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'transaction.new_offer_amount_required'.tr();
              final parsed = CurrencyInputFormatter.parse(v);
              if (parsed == null || parsed <= 0) return 'transaction.new_offer_amount_invalid'.tr();
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text('common.send'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final newAmount = CurrencyInputFormatter.parse(controller.text);
    if (newAmount == null) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(sentOffersProvider.notifier)
          .counterBack(widget.offer.id, newAmount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('transaction.new_offer_ok'.tr())),
        );
        context.go('/profile?tab=2');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('transaction.new_offer_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('transaction.reject_counter_title'.tr()),
        content: Text('transaction.reject_counter_content'.tr()),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.reject'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref.read(sentOffersProvider.notifier).reject(widget.offer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('transaction.reject_counter_ok'.tr())),
        );
        context.go('/profile?tab=2');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('transaction.reject_counter_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acceptBtn = FilledButton.icon(
      onPressed: _loading ? null : _accept,
      icon: const Icon(Icons.check_circle_outline, size: 14),
      label: Text(
        'common.accept'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF135BEC),
        minimumSize: const Size(double.infinity, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    final counterBtn = OutlinedButton.icon(
      onPressed: _loading ? null : _counterBack,
      icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFFEA580C)),
      label: Text(
        'transaction.new_offer_btn'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFFEA580C)),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFEA580C),
        side: const BorderSide(color: Color(0xFFEA580C)),
        minimumSize: const Size(double.infinity, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    final rejectBtn = OutlinedButton.icon(
      onPressed: _loading ? null : _reject,
      icon: const Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
      label: Text(
        'common.reject'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.red),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        minimumSize: const Size(double.infinity, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            acceptBtn,
            const SizedBox(height: 8),
            counterBtn,
            const SizedBox(height: 8),
            rejectBtn,
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: acceptBtn),
          const SizedBox(width: 6),
          Expanded(child: counterBtn),
          const SizedBox(width: 6),
          Expanded(child: rejectBtn),
        ],
      );
    });
  }
}

// ── Seller pending-offer actions (accept / counter / reject) ─────────────────

class _SellerPendingOfferActions extends ConsumerStatefulWidget {
  const _SellerPendingOfferActions({required this.offer});
  final OfferData offer;

  @override
  ConsumerState<_SellerPendingOfferActions> createState() =>
      _SellerPendingOfferActionsState();
}

class _SellerPendingOfferActionsState
    extends ConsumerState<_SellerPendingOfferActions> {
  bool _loading = false;

  Future<void> _accept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('offers.accept_title'.tr()),
        content: Text(
          'offers.accept_body'.tr(
            namedArgs: {
              'amount': CurrencyInputFormatter.format(widget.offer.amount),
            },
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF135BEC),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.accept'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(receivedOffersProvider.notifier)
          .accept(widget.offer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('offers.accept_ok'.tr())),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('offers.accept_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _counter() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'offers.counter_title_prefix'.tr(),
                style: const TextStyle(
                    color: Color(0xFF135BEC), fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text: 'offers.counter_title_suffix'.tr(),
                style: const TextStyle(
                    color: Color(0xFF16A34A), fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              labelText: 'offers.counter_amount_label'.tr(),
              suffixText: ' €',
              border: const OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'chat.error_amount_required'.tr();
              }
              final parsed = CurrencyInputFormatter.parse(v);
              if (parsed == null || parsed <= 0) {
                return 'chat.error_amount_invalid'.tr();
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text('offers.counter_send_btn'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final amount = CurrencyInputFormatter.parse(controller.text);
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(receivedOffersProvider.notifier)
          .counter(widget.offer.id, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('offers.counter_ok'.tr())),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('offers.counter_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('offers.reject_title'.tr()),
        content: Text('offers.reject_body'.tr()),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.reject'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(receivedOffersProvider.notifier)
          .reject(widget.offer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('offers.reject_ok'.tr())),
        );
        context.go('/profile?tab=2');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('offers.reject_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info pill showing the offer amount
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF135BEC).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFF135BEC).withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              const Icon(Icons.payments_outlined,
                  size: 16, color: Color(0xFF135BEC)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'transaction.offer_amount_label'.tr(namedArgs: {
                    'amount':
                        CurrencyInputFormatter.format(widget.offer.amount),
                  }),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF135BEC),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Action buttons: adapt layout to screen size
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : _accept,
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: Text(
                  'offers.accept_btn'.tr(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _counter,
                      icon: const Icon(Icons.edit_outlined,
                          size: 15, color: Color(0xFFEA580C)),
                      label: Text(
                        'offers.counter_btn'.tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFFEA580C)),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEA580C),
                        side: const BorderSide(color: Color(0xFFEA580C)),
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _reject,
                      icon: const Icon(Icons.cancel_outlined,
                          size: 15, color: Colors.red),
                      label: Text(
                        'offers.reject_btn'.tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _accept,
                  icon: const Icon(Icons.check_circle_outline, size: 15),
                  label: Text(
                    'offers.accept_btn'.tr(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _counter,
                  icon: const Icon(Icons.edit_outlined,
                      size: 15, color: Color(0xFFEA580C)),
                  label: Text(
                    'offers.counter_btn'.tr(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFFEA580C)),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEA580C),
                    side: const BorderSide(color: Color(0xFFEA580C)),
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _reject,
                  icon: const Icon(Icons.cancel_outlined,
                      size: 15, color: Colors.red),
                  label: Text(
                    'offers.reject_btn'.tr(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ── Seller solvency section (embedded in solvency timeline step) ──────────────

class _SellerSolvencySection extends ConsumerStatefulWidget {
  const _SellerSolvencySection({required this.offer});
  final OfferData offer;

  @override
  ConsumerState<_SellerSolvencySection> createState() =>
      _SellerSolvencySectionState();
}

class _SellerSolvencySectionState
    extends ConsumerState<_SellerSolvencySection> {
  bool _loading = false;
  bool _accepting = false;

  Future<void> _acceptSolvency(BuildContext context) async {
    setState(() => _accepting = true);
    try {
      await ref
          .read(receivedOffersProvider.notifier)
          .acceptSolvency(widget.offer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('transaction.accept_solvency_ok'.tr())),
        );
        ref.invalidate(receivedOffersProvider);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('transaction.accept_solvency_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _confirmReject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('transaction.reject_offer_dialog_title'.tr()),
        content: Text('transaction.reject_offer_dialog_content'.tr()),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('common.reject'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(receivedOffersProvider.notifier)
          .reject(widget.offer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('transaction.reject_offer_ok'.tr())),
        );
        context.go('/profile');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('transaction.reject_offer_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passportAsync =
        ref.watch(solvency_prov.buyerPassportProvider(widget.offer.id));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0A1A0D) : const Color(0xFFF0FDF4);
    final cardBorder = isDark ? const Color(0xFF1A4A20) : const Color(0xFF86EFAC);
    final titleColor = isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 8),
              Text(
                'transaction.buyer_solvency_title'.tr(),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: titleColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          passportAsync.when(
            loading: () => const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => Text(
              'transaction.buyer_no_passport'.tr(),
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            data: (passport) {
              if (passport == null) {
                return Text(
                  'transaction.buyer_passport_incomplete'.tr(),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                );
              }
              final level = passport.solvencyLevel ?? 'bronze';
              final (levelLabel, levelColor, levelBg, levelIcon) =
                  switch (level) {
                'gold' => (
                  'transaction.solvency_level_gold'.tr(),
                  const Color(0xFFB8860B),
                  isDark ? const Color(0xFF1A1400) : const Color(0xFFFFFBEB),
                  Icons.emoji_events_outlined
                ),
                'silver' => (
                  'transaction.solvency_level_silver'.tr(),
                  const Color(0xFF94A3B8),
                  isDark ? const Color(0xFF12181F) : const Color(0xFFF8FAFC),
                  Icons.verified_outlined
                ),
                _ => (
                  'transaction.solvency_level_bronze'.tr(),
                  const Color(0xFFD97706),
                  isDark ? const Color(0xFF1A0F00) : const Color(0xFFFFF7ED),
                  Icons.shield_outlined
                ),
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: levelBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: levelColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(levelIcon, color: levelColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          levelLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: levelColor,
                          ),
                        ),
                        if (passport.isMultiBuyer) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF135BEC),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'transaction.solvency_joint_purchase'.tr(),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _SolvencyRowCompact('transaction.solvency_knows_extra_costs'.tr(),
                      passport.knowsExtraCosts ? 'common.yes'.tr() : 'common.no'.tr()),
                  _SolvencyRowCompact('transaction.solvency_initial_savings'.tr(),
                      passport.hasInitialSavings ? 'common.yes'.tr() : 'common.no'.tr()),
                  _SolvencyRowCompact('transaction.solvency_pre_approval'.tr(),
                      passport.hasPreApproval ? 'common.yes'.tr() : 'common.no'.tr()),
                  _SolvencyRowCompact(
                      'transaction.solvency_financing'.tr(),
                      passport.paymentMethodLabel ??
                          passport.paymentMethod ??
                          '-'),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final acceptBtn = FilledButton.icon(
                onPressed: (_accepting || _loading)
                    ? null
                    : () => _acceptSolvency(context),
                icon: _accepting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified_user_outlined, size: 16),
                label: Text('transaction.accept_solvency_btn'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  minimumSize: const Size(double.infinity, 44),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
              final rejectBtn = FilledButton.icon(
                onPressed: (_loading || _accepting)
                    ? null
                    : () => _confirmReject(context),
                icon: _loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cancel_outlined, size: 16),
                label: Text('common.reject'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 44),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [acceptBtn, const SizedBox(height: 8), rejectBtn],
                );
              }
              return Row(
                children: [
                  Expanded(child: acceptBtn),
                  const SizedBox(width: 8),
                  Expanded(child: rejectBtn),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SolvencyRowCompact extends StatelessWidget {
  const _SolvencyRowCompact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Congratulations banner ────────────────────────────────────────────────────

class _CongratsBanner extends StatelessWidget {
  const _CongratsBanner({required this.isBuyer});

  final bool isBuyer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const kGreen = Color(0xFF16A34A);
    final bgColor = isDark ? const Color(0xFF0D2010) : const Color(0xFFF0FDF4);
    final borderColor = isDark ? const Color(0xFF1A4A20) : const Color(0xFF86EFAC);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: isDark ? 0.15 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home_rounded, size: 44, color: kGreen),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEA580C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.celebration, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            (isBuyer
                ? 'transaction.congrats_buyer_title'
                : 'transaction.congrats_seller_title')
                .tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'transaction.congrats_desc'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Brand bar ─────────────────────────────────────────────────────────────────

class _BrandBar extends StatelessWidget {
  const _BrandBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    final brandText = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user_outlined, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'transaction.brand_text'.tr(),
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            softWrap: true,
          ),
        ),
      ],
    );

    final links = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FooterLink('transaction.footer_help'.tr()),
        const SizedBox(width: 10),
        _FooterLink('transaction.footer_legal'.tr()),
        const SizedBox(width: 10),
        _FooterLink('transaction.footer_security'.tr()),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                brandText,
                const SizedBox(height: 8),
                links,
              ],
            )
          : Row(
              children: [
                Expanded(child: brandText),
                const SizedBox(width: 12),
                links,
              ],
            ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
