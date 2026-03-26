import 'package:collection/collection.dart';
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

final _arrasStatusProvider = FutureProvider.autoDispose
    .family<String, String>((ref, offerId) async {
  final token =
      await const FlutterSecureStorage().read(key: 'auth_token');
  if (token == null) return 'none';
  final dio = Dio();
  try {
    final resp = await dio.get(
      '$EnvConfig.apiBaseUrl/arras/$offerId',
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
  final dio = Dio();
  try {
    final resp = await dio.get(
      '$EnvConfig.apiBaseUrl/tasacion/$offerId/status',
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
    final resp = await Dio().get(
      '$EnvConfig.apiBaseUrl/notaria-appt/$offerId/status',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (resp.data as Map<String, dynamic>)['appointment_status']
            as String? ??
        'pending';
  } catch (_) {
    return 'pending';
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
                    'Estado de la Transaccion',
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
                    'Sigue el progreso de tu venta en tiempo real',
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
                    buyerActions: isBuyer && s == 'counter_offer'
                        ? _BuyerCounterOfferActions(offer: liveOffer)
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
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Inicio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
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
    Widget? buyerActions,
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
    if (buyerActions != null || withdrawAction != null) {
      step0Actions = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (buyerActions != null) buyerActions,
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
            ? 'Oferta Enviada'
            : stage > 0
                ? 'Oferta Aceptada'
                : (s == 'withdrawn' ? 'Oferta Retirada' : 'Oferta Rechazada'),
        subtitle: stage > 0
            ? 'Vendedor acepto la oferta'
            : stage == 0
                ? (s == 'counter_offer'
                    ? 'El vendedor ha realizado una contraoferta'
                    : 'Pendiente de respuesta del vendedor')
                : (s == 'withdrawn' ? 'Oferta retirada por el comprador' : 'Oferta rechazada por el vendedor'),
        state: stage < 0 ? _StepState.locked : stepState(0),
        actionsWidget: step0Actions,
      ),
      _TimelineStep(
        title: 'Verificacion de Solvencia',
        subtitle: stage > 1 || offerData.sellerSolvencyAccepted
            ? 'Validado por InmuFacil Secure-Tech'
            : stage == 1
                ? 'Verificando solvencia del comprador'
                : 'Pendiente de aceptacion de oferta',
        state: offerData.sellerSolvencyAccepted
            ? _StepState.done
            : stepState(1),
        ctaLabel: isBuyer && stage == 1 && !hasPassport
            ? 'Completar pasaporte'
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
          title: 'Verificacion de Identidad — 2° Titular',
          subtitle: offerData.secondBuyerPending
              ? (isBuyer
                  ? 'Tu segundo comprador debe completar su verificacion'
                  : 'Pendiente: el segundo comprador debe verificar su identidad')
              : 'Identidad del segundo titular confirmada',
          description: offerData.secondBuyerPending && isBuyer
              ? 'Para avanzar al contrato de Arras, el segundo comprador debe enviar sus datos de identidad. Usa el boton de abajo para añadirlos.'
              : null,
          state: offerData.secondBuyerPending
              ? _StepState.active
              : _StepState.done,
          ctaLabel: isBuyer && offerData.secondBuyerPending
              ? 'Añadir datos del 2° comprador'
              : null,
          ctaIcon: isBuyer && offerData.secondBuyerPending
              ? Icons.person_add_alt_1_outlined
              : null,
          ctaCallback: isBuyer && offerData.secondBuyerPending
              ? () => context.push('/solvency/second-buyer')
              : null,
        ),
      _TimelineStep(
        title: 'Contrato de Arras',
        subtitle: stage > 2
            ? 'Firmado por ambas partes'
            : stage == 2
                ? _arrasSubtitle(arrasStatus, isBuyer)
                : 'Pendiente de verificacion de solvencia',
        description: stage == 2 &&
                arrasStatus != 'accepted'
            ? 'Ambas partes deben completar su entrevista. La IA generara el '
              'contrato cuando ambos confirmen sus respuestas.'
            : null,
        state: arrasStatus == 'accepted' ? _StepState.done : stepState(2),
        ctaLabel: stage == 2 ? _arrasCtaLabel(arrasStatus, isBuyer) : null,
        ctaIcon: stage == 2 ? _arrasCtaIcon(arrasStatus) : null,
        ctaCallback: stage == 2
            ? () => context.push('/offers/${offerData.id}/arras', extra: offerData)
            : null,
      ),
      _TimelineStep(
        title: 'Tasacion de la Vivienda',
        subtitle: stage > 3
            ? 'Informe del tasador completado'
            : stage == 3
                ? _tasacionSubtitle(tasacionApptStatus, isBuyer)
                : 'Pendiente de firma de arras',
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
          title: 'Formalizacion Bancaria (FEIN)',
          subtitle: stage > 3 || feinBuyerConfirmed
              ? 'FEIN confirmada — banco ha aprobado la hipoteca'
              : stage == 3 && tasacionApptStatus == 'completed'
                  ? (isBuyer
                      ? 'Tu banco debe emitirte la FEIN — confirma cuando la recibas'
                      : 'El banco del comprador esta tramitando la FEIN')
                  : stage == 3
                      ? 'Pendiente tras tasacion — banco emite la FEIN'
                      : 'Pendiente de firma de arras',
          state: stage > 3 || feinBuyerConfirmed
              ? _StepState.done
              : (stage == 3 && tasacionApptStatus == 'completed'
                  ? _StepState.active
                  : _StepState.locked),
          // CTA solo para el comprador, y solo si aun no ha confirmado
          ctaLabel: (isBuyer && stage == 3 && tasacionApptStatus == 'completed' && !feinBuyerConfirmed)
              ? 'Confirmar FEIN del banco'
              : null,
          ctaIcon: (isBuyer && stage == 3 && tasacionApptStatus == 'completed' && !feinBuyerConfirmed)
              ? Icons.account_balance_outlined
              : null,
          ctaCallback: (isBuyer && stage == 3 && tasacionApptStatus == 'completed' && !feinBuyerConfirmed)
              ? () => context.push('/offers/${offerData.id}/fein', extra: offerData)
              : null,
        ),
      _TimelineStep(
        title: 'Firma en Notaria y Entrega de Llaves',
        subtitle: stage >= 4
            ? 'Escrituras firmadas y llaves entregadas'
            : feinBuyerConfirmed
                ? _notariaSubtitle(notariaApptStatus, isBuyer)
                : 'Pendiente de formalizacion bancaria (FEIN)',
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
        title: 'Post-Venta y Suministros',
        subtitle: stage >= 4
            ? 'Gestiona el cambio de titularidad de los suministros'
            : 'Accesible tras la firma en notaria',
        state: stage >= 4 ? _StepState.active : _StepState.locked,
        ctaLabel: stage >= 4 ? 'Gestionar suministros' : null,
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
          title: isVisitConfirmed ? 'Visita Confirmada' : 'Visita Solicitada',
          subtitle: isVisitConfirmed
              ? 'Cita acordada: $visitDate'
              : isVisitPending
                  ? 'Propuesta: $visitDate — pendiente de confirmacion'
                  : 'Ultima actividad: $visitDate',
          state: isVisitConfirmed ? _StepState.done : _StepState.active,
          ctaLabel: 'Ver agenda de visitas',
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
        return 'Firmado por ambas partes';
      case 'contract_ready':
      case 'buyer_accepted':
      case 'seller_accepted':
        return 'Contrato listo — pendiente de firma';
      case 'generating':
        return 'Generando contrato con IA...';
      case 'both_done':
        return 'Ambas entrevistas completadas — generando contrato';
      case 'buyer_done':
        return isBuyer
            ? 'Tu entrevista completada — esperando al vendedor'
            : 'Comprador listo — completa tu entrevista';
      case 'seller_done':
        return !isBuyer
            ? 'Tu entrevista completada — esperando al comprador'
            : 'Vendedor listo — completa tu entrevista';
      default:
        return 'Completa tu entrevista para continuar';
    }
  }

  String? _arrasCtaLabel(String arrasStatus, bool isBuyer) {
    switch (arrasStatus) {
      case 'accepted':
        return null;
      case 'contract_ready':
      case 'buyer_accepted':
      case 'seller_accepted':
        return 'Revisar contrato';
      case 'generating':
      case 'both_done':
        return 'Ver estado';
      default:
        return isBuyer ? 'Comenzar entrevista' : 'Completar entrevista';
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
        return 'Tasacion completada — informe emitido';
      case 'accepted':
        return isBuyer
            ? 'Cita acordada — pendiente de visita del tasador'
            : 'Cita acordada — confirma cuando el tasador visite la vivienda';
      case 'rejected':
        return isBuyer
            ? 'Vendedor propuso fecha alternativa — pendiente de tu respuesta'
            : 'Fecha rechazada — pendiente de nueva propuesta del comprador';
      case 'proposed':
        return isBuyer
            ? 'Fecha propuesta — pendiente de confirmacion del vendedor'
            : 'Comprador propuso una fecha — pendiente de tu respuesta';
      default: // pending
        return isBuyer
            ? 'Agenda la visita del tasador para continuar'
            : 'Pendiente de que el comprador proponga una fecha';
    }
  }

  String? _tasacionCtaLabel(String apptStatus, bool isBuyer) {
    switch (apptStatus) {
      case 'completed':
        return null;
      case 'accepted':
        return isBuyer ? 'Ver cita confirmada' : 'Confirmar visita del tasador';
      case 'rejected':
        return isBuyer
            ? 'Ver propuesta del vendedor'
            : 'Ver estado — esperando comprador';
      case 'proposed':
        return isBuyer
            ? 'Ver propuesta enviada'
            : 'Aceptar o rechazar propuesta';
      default: // pending
        return isBuyer ? 'Agendar visita del tasador' : null;
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
        return 'Firma realizada — pendiente de entrega de llaves';
      case 'scheduled':
        return 'Cita acordada — pendiente de firma en notaria';
      default: // pending
        return isBuyer
            ? 'A la espera de cita en notaria — propone fecha y lugar'
            : 'A la espera de cita en notaria — el comprador eligira fecha';
    }
  }

  String? _notariaCtaLabel(String apptStatus, bool isBuyer, int stage) {
    if (stage >= 4) return 'Ver estado de la firma';
    switch (apptStatus) {
      case 'completed':
      case 'scheduled':
        return 'Confirmar firma y entrega de llaves';
      default: // pending
        return isBuyer ? 'Proponer cita en notaria' : 'Ver estado';
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
    final title = offer.propertyTitle ?? 'Propiedad';
    final price = offer.propertyPrice;
    final counterparty = offer.sellerName ?? offer.buyerName ?? 'Contraparte';
    final counterPhotoUrl = offer.buyerPhotoUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Property card
        Expanded(
          flex: 3,
          child: Container(
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
                    color: const Color(0xFFEEF6EE),
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
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Counterparty card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'COMPRADOR',
                style: TextStyle(
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
                              color: Color(0xFF2563EB),
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
        ),
      ],
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
                            size: 14, color: const Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(
                          step.ctaLabel!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
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

// Active step: blue dot + expanded card with CTA
class _ActiveRow extends StatelessWidget {
  const _ActiveRow({required this.step, required this.isLast});

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
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_document,
                  size: 18, color: Colors.white),
            ),
            lineColor: const Color(0xFFE2E8F0),
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
                  border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Text(
                            'EN CURSO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    if (step.description != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        step.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
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
                            backgroundColor: const Color(0xFF2563EB),
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
            lineColor: const Color(0xFFE2E8F0),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFCBD5E1),
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
            '¿Necesitas ayuda con este paso?',
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
                  size: 15, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Hablar con un asesor legal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF2563EB),
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
        title: const Text('Retirar oferta'),
        content: const Text(
          '¿Seguro que quieres retirar tu oferta? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirar'),
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
          const SnackBar(content: Text('Oferta retirada correctamente')),
        );
        context.go('/profile?tab=2');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al retirar la oferta. Inténtalo de nuevo.')),
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
      label: const Text(
        'Retirar Oferta',
        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
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
        title: const Text('Aceptar contraoferta'),
        content: Text(
          '\u00BFAceptas la contraoferta de ${CurrencyInputFormatter.format(widget.offer.amount)} \u20AC?',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aceptar'),
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
          const SnackBar(content: Text('Oferta aceptada')),
        );
        context.go('/');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al aceptar la oferta. Intentalo de nuevo.')),
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
        title: const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Hacer ',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'nueva oferta',
                style: TextStyle(
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
            decoration: const InputDecoration(
              labelText: 'Nuevo importe',
              suffixText: ' €',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Introduce un importe';
              final parsed = CurrencyInputFormatter.parse(v);
              if (parsed == null || parsed <= 0) return 'Importe no valido';
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
            child: const Text('Cancelar'),
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
            child: const Text('Enviar'),
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
          const SnackBar(content: Text('Tu nueva oferta ha sido enviada')),
        );
        context.go('/profile?tab=2');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar la oferta. Intentalo de nuevo.')),
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
        title: const Text('Rechazar contraoferta'),
        content: const Text(
          '\u00BFRechazas la contraoferta? Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rechazar'),
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
          const SnackBar(content: Text('Contraoferta rechazada')),
        );
        context.go('/profile?tab=2');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al rechazar la oferta. Intentalo de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _loading ? null : _accept,
            icon: const Icon(Icons.check_circle_outline, size: 14),
            label: const Text(
              'Aceptar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _counterBack,
            icon: const Icon(Icons.edit_outlined,
                size: 14, color: Color(0xFFEA580C)),
            label: const Text(
              'Nueva Oferta',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFFEA580C)),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEA580C),
              side: const BorderSide(color: Color(0xFFEA580C)),
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _reject,
            icon: const Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
            label: const Text(
              'Rechazar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
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
          const SnackBar(content: Text('Solvencia aceptada')),
        );
        ref.invalidate(receivedOffersProvider);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al aceptar la solvencia')),
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
        title: const Text('Rechazar oferta'),
        content: const Text(
            'El comprador sera notificado de que su oferta ha sido rechazada.'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rechazar'),
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
          const SnackBar(content: Text('Oferta rechazada')),
        );
        context.go('/profile');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al rechazar la oferta')),
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

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  color: Color(0xFF16A34A), size: 18),
              SizedBox(width: 8),
              Text(
                'Solvencia del comprador',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF166534)),
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
              'El comprador aun no tiene pasaporte de solvencia.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            data: (passport) {
              if (passport == null) {
                return Text(
                  'El comprador aun no ha completado el pasaporte de solvencia.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                );
              }
              final level = passport.solvencyLevel ?? 'bronze';
              final (levelLabel, levelColor, levelBg, levelIcon) =
                  switch (level) {
                'gold' => (
                  'Oro',
                  const Color(0xFFB8860B),
                  const Color(0xFFFFFBEB),
                  Icons.emoji_events_outlined
                ),
                'silver' => (
                  'Plata',
                  const Color(0xFF64748B),
                  const Color(0xFFF8FAFC),
                  Icons.verified_outlined
                ),
                _ => (
                  'Bronce',
                  const Color(0xFFD97706),
                  const Color(0xFFFFF7ED),
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
                          'Nivel $levelLabel',
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
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Compra conjunta',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _SolvencyRowCompact('Conoce gastos adicionales',
                      passport.knowsExtraCosts ? 'Si' : 'No'),
                  _SolvencyRowCompact('Ahorros iniciales',
                      passport.hasInitialSavings ? 'Si' : 'No'),
                  _SolvencyRowCompact('Preaprobacion hipotecaria',
                      passport.hasPreApproval ? 'Si' : 'No'),
                  _SolvencyRowCompact(
                      'Financiacion',
                      passport.paymentMethodLabel ??
                          passport.paymentMethod ??
                          '-'),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
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
                  label: const Text('Aceptar Solvencia',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
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
                label: const Text('Rechazar',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 210,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF166534)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined,
              size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'InmuFacil Secure-Tech \u00B7 \u00A9 2023 InmuFacil S.L. Sistema de transacciones seguras bajo protocolo AES-256',
              style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              _FooterLink('Ayuda'),
              const SizedBox(width: 10),
              _FooterLink('Legal'),
              const SizedBox(width: 10),
              _FooterLink('Seguridad'),
            ],
          ),
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
