import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'offers_provider.dart';

// ─── Urgency colours (shared with UI) ────────────────────────────────────────

const kUrgencyGreen = 0xFF16A34A;
const kUrgencyBlue = 0xFF2563EB;

// ─── Model ────────────────────────────────────────────────────────────────────

enum UrgentActionType {
  verifyIdentity,
  completeSolvency,
  reviewSolvency,
  signArras,
  confirmFein,
  confirmTasacion,
  notaryAppointment,
  postVenta,
}

class UrgentAction {
  const UrgentAction({
    required this.offerId,
    required this.propertyTitle,
    required this.type,
    required this.label,
    required this.route,
    this.routeExtra,
    required this.offer,
  });

  final String offerId;
  final String propertyTitle;
  final UrgentActionType type;
  final String label;
  final String route;

  /// Extra object forwarded to GoRouter push (usually the OfferData itself).
  final Object? routeExtra;

  /// The full offer, kept for re-use in navigation callbacks.
  final OfferData offer;

  /// Lower value = higher urgency (for sort order).
  int get sortPriority {
    switch (type) {
      case UrgentActionType.signArras:
        return 0;
      case UrgentActionType.confirmFein:
        return 1;
      case UrgentActionType.completeSolvency:
        return 2;
      case UrgentActionType.reviewSolvency:
        return 3;
      case UrgentActionType.verifyIdentity:
        return 4;
      case UrgentActionType.confirmTasacion:
        return 5;
      case UrgentActionType.notaryAppointment:
        return 6;
      case UrgentActionType.postVenta:
        return 7;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Returns all blocking actions the current user must take across all their
/// active offers, sorted from most to least urgent.
final urgencyProvider = Provider<List<UrgentAction>>((ref) {
  final currentUser = ref.watch(authProvider).user;
  if (currentUser == null) return const [];

  final sentOffers =
      ref.watch(sentOffersProvider).asData?.value ?? const [];
  final receivedOffers =
      ref.watch(receivedOffersProvider).asData?.value ?? const [];

  final List<UrgentAction> actions = [];

  // Buyer perspective — offers the user sent
  for (final offer in sentOffers) {
    String? liveNotaria;
    bool? liveFein;
    if (offer.status == 'signed') {
      liveFein =
          ref.watch(feinConfirmedProvider(offer.id)).asData?.value;
      final feinOk = liveFein ?? offer.feinBuyerConfirmed;
      if (feinOk) {
        liveNotaria =
            ref.watch(notariaApptStatusProvider(offer.id)).asData?.value;
      }
    }
    final action = buyerBlockingAction(offer, currentUser.id,
        liveFeinConfirmed: liveFein, liveNotariaStatus: liveNotaria);
    if (action != null) actions.add(action);
  }

  // Seller perspective — offers received on the user's properties
  for (final offer in receivedOffers) {
    String? liveNotaria;
    bool? liveFein;
    if (offer.status == 'signed') {
      liveFein =
          ref.watch(feinConfirmedProvider(offer.id)).asData?.value;
      final feinOk = liveFein ?? offer.feinBuyerConfirmed;
      if (feinOk) {
        liveNotaria =
            ref.watch(notariaApptStatusProvider(offer.id)).asData?.value;
      }
    }
    final action = sellerBlockingAction(offer,
        liveFeinConfirmed: liveFein, liveNotariaStatus: liveNotaria);
    if (action != null) actions.add(action);
  }

  actions.sort((a, b) => a.sortPriority.compareTo(b.sortPriority));
  return actions;
});

// ─── Blocking action helpers (package-visible for testing) ───────────────────

/// Returns the single most urgent blocking action for the BUYER on this offer,
/// or null when no action is required.
/// [liveFeinConfirmed] — if provided, overrides [offer.feinBuyerConfirmed]
/// so the urgency provider can use a fresh API result instead of stale cache.
UrgentAction? buyerBlockingAction(
  OfferData offer,
  String currentUserId, {
  bool? liveFeinConfirmed,
  String? liveNotariaStatus,
}) {
  if (offer.buyerId != currentUserId) return null;

  final s = offer.status;
  final title = offer.propertyTitle ?? 'Propiedad sin titulo';

  // Terminal or pre-acceptance states require no action
  if (s == 'rejected' || s == 'withdrawn' || s == 'completed' ||
      s == 'pending' || s == 'counter_offer') {
    return null;
  }

  // Identity verification gates everything else
  if (!offer.buyerIsVerified) {
    return UrgentAction(
      offerId: offer.id,
      propertyTitle: title,
      type: UrgentActionType.verifyIdentity,
      label: 'Completar verificacion de identidad',
      route: '/verify-identity',
      offer: offer,
    );
  }

  // Solvency passport not yet submitted
  if (s == 'accepted' && !offer.buyerSolvencySubmitted) {
    return UrgentAction(
      offerId: offer.id,
      propertyTitle: title,
      type: UrgentActionType.completeSolvency,
      label: 'Completar Pasaporte de Solvencia',
      route: '/solvency/second-buyer',
      offer: offer,
    );
  }

  // Arras contract needs buyer signature
  if (s == 'signing_pending') {
    return UrgentAction(
      offerId: offer.id,
      propertyTitle: title,
      type: UrgentActionType.signArras,
      label: 'Firmar Contrato de Arras',
      route: '/offers/${offer.id}/arras',
      routeExtra: offer,
      offer: offer,
    );
  }

  if (s == 'signed') {
    final ts = offer.tasacionStatus;
    // Use live value when available, fall back to cached OfferData field
    final feinBuyerConfirmed =
        liveFeinConfirmed ?? offer.feinBuyerConfirmed;

    // FEIN confirmed — buyer must now coordinate notaria appointment
    if (feinBuyerConfirmed) {
      // Use live status when available, fall back to cached field
      final ns = liveNotariaStatus ??
          offer.notariaApptStatus ??
          'pending';
      if (ns == 'completed') {
        return UrgentAction(
          offerId: offer.id,
          propertyTitle: title,
          type: UrgentActionType.postVenta,
          label: 'Revisar documentos de post-venta',
          route: '/offers/${offer.id}/post-venta',
          routeExtra: offer,
          offer: offer,
        );
      }
      return UrgentAction(
        offerId: offer.id,
        propertyTitle: title,
        type: UrgentActionType.notaryAppointment,
        label: ns == 'scheduled'
            ? 'Confirmar firma y entrega de llaves'
            : 'Coordinar cita en notaria',
        route: '/offers/${offer.id}/notaria',
        routeExtra: offer,
        offer: offer,
      );
    }

    // Tasacion completada -> llevar directamente a FEIN
    if (ts == 'completed') {
      return UrgentAction(
        offerId: offer.id,
        propertyTitle: title,
        type: UrgentActionType.confirmFein,
        label: 'Ir a Formalizacion Bancaria (FEIN)',
        route: '/offers/${offer.id}/fein',
        routeExtra: offer,
        offer: offer,
      );
    }
    // Cita acordada, esperando visita fisica
    if (ts == 'accepted') {
      return UrgentAction(
        offerId: offer.id,
        propertyTitle: title,
        type: UrgentActionType.confirmTasacion,
        label: 'Cita del tasador confirmada',
        route: '/offers/${offer.id}/tasacion',
        routeExtra: offer,
        offer: offer,
      );
    }
    // Propuesta enviada, esperando respuesta del vendedor
    if (ts == 'proposed') {
      return UrgentAction(
        offerId: offer.id,
        propertyTitle: title,
        type: UrgentActionType.confirmTasacion,
        label: 'Esperando confirmacion del vendedor',
        route: '/offers/${offer.id}/tasacion',
        routeExtra: offer,
        offer: offer,
      );
    }
    // pending o rejected: el comprador debe agendar o re-agendar
    return UrgentAction(
      offerId: offer.id,
      propertyTitle: title,
      type: UrgentActionType.confirmTasacion,
      label: ts == 'rejected'
          ? 'Responder contraoferta del tasador'
          : 'Agendar visita del tasador',
      route: '/offers/${offer.id}/tasacion',
      routeExtra: offer,
      offer: offer,
    );
  }

  return null;
}

/// Returns the single most urgent blocking action for the SELLER on this offer,
/// or null when no action is required.
/// [liveFeinConfirmed] — if provided, overrides [offer.feinBuyerConfirmed].
UrgentAction? sellerBlockingAction(
  OfferData offer, {
  bool? liveFeinConfirmed,
  String? liveNotariaStatus,
}) {
  final s = offer.status;
  final title = offer.propertyTitle ?? 'Propiedad sin titulo';

  // Solvency submitted by buyer but not yet reviewed by seller
  if (s == 'accepted' &&
      offer.buyerSolvencySubmitted &&
      !offer.sellerSolvencyAccepted) {
    return UrgentAction(
      offerId: offer.id,
      propertyTitle: title,
      type: UrgentActionType.reviewSolvency,
      label: 'Revisar solvencia del comprador',
      route: '/offers/${offer.id}/timeline',
      routeExtra: offer,
      offer: offer,
    );
  }

  // Arras contract needs seller signature
  if (s == 'signing_pending') {
    return UrgentAction(
      offerId: offer.id,
      propertyTitle: title,
      type: UrgentActionType.signArras,
      label: 'Firmar Contrato de Arras',
      route: '/offers/${offer.id}/arras',
      routeExtra: offer,
      offer: offer,
    );
  }

  // Post-arras: tasacion + FEIN coordination (seller perspective)
  if (s == 'signed') {
    final ts = offer.tasacionStatus;
    final feinBuyerConfirmed =
        liveFeinConfirmed ?? offer.feinBuyerConfirmed;
    // Buyer's proposal waiting for seller response
    if (ts == 'proposed') {
      return UrgentAction(
        offerId: offer.id,
        propertyTitle: title,
        type: UrgentActionType.confirmTasacion,
        label: 'Confirmar cita del tasador',
        route: '/offers/${offer.id}/tasacion',
        routeExtra: offer,
        offer: offer,
      );
    }
    // Seller must confirm the physical visit happened
    if (ts == 'accepted') {
      return UrgentAction(
        offerId: offer.id,
        propertyTitle: title,
        type: UrgentActionType.confirmTasacion,
        label: 'Confirmar visita del tasador',
        route: '/offers/${offer.id}/tasacion',
        routeExtra: offer,
        offer: offer,
      );
    }
    // Tasacion completed — check if FEIN confirmed and notaria needs coordination
    if (ts == 'completed') {
      if (feinBuyerConfirmed) {
        final ns = liveNotariaStatus ??
            offer.notariaApptStatus ??
            'pending';
        if (ns == 'completed') {
          return UrgentAction(
            offerId: offer.id,
            propertyTitle: title,
            type: UrgentActionType.postVenta,
            label: 'Gestionar documentos de post-venta',
            route: '/offers/${offer.id}/post-venta',
            routeExtra: offer,
            offer: offer,
          );
        }
        return UrgentAction(
          offerId: offer.id,
          propertyTitle: title,
          type: UrgentActionType.notaryAppointment,
          label: ns == 'scheduled'
              ? 'Confirmar firma y entrega de llaves'
              : 'A la espera de cita en notaria',
          route: '/offers/${offer.id}/notaria',
          routeExtra: offer,
          offer: offer,
        );
      }
      return null;
    }
    // pending / rejected: seller waits for buyer proposal or counter-accepted
    return null;
  }

  return null;
}
