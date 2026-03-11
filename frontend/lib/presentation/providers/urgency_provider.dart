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
    final action = buyerBlockingAction(offer, currentUser.id);
    if (action != null) actions.add(action);
  }

  // Seller perspective — offers received on the user's properties
  for (final offer in receivedOffers) {
    final action = sellerBlockingAction(offer);
    if (action != null) actions.add(action);
  }

  actions.sort((a, b) => a.sortPriority.compareTo(b.sortPriority));
  return actions;
});

// ─── Blocking action helpers (package-visible for testing) ───────────────────

/// Returns the single most urgent blocking action for the BUYER on this offer,
/// or null when no action is required.
UrgentAction? buyerBlockingAction(OfferData offer, String currentUserId) {
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
    const _feinMethods = {
      'mortgage_pending',
      'mortgage_approved',
      'savings_plus_mortgage',
      'bridge_mortgage',
    };
    if (_feinMethods.contains(offer.paymentMethod)) {
      return UrgentAction(
        offerId: offer.id,
        propertyTitle: title,
        type: UrgentActionType.confirmFein,
        label: 'Confirmar FEIN del banco',
        route: '/offers/${offer.id}/fein',
        routeExtra: offer,
        offer: offer,
      );
    }
    // Non-mortgage buyers go straight to tasacion
    return UrgentAction(
      offerId: offer.id,
      propertyTitle: title,
      type: UrgentActionType.confirmTasacion,
      label: 'Gestionar cita de tasacion',
      route: '/offers/${offer.id}/tasacion',
      routeExtra: offer,
      offer: offer,
    );
  }

  return null;
}

/// Returns the single most urgent blocking action for the SELLER on this offer,
/// or null when no action is required.
UrgentAction? sellerBlockingAction(OfferData offer) {
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

  // Post-arras: tasacion coordination
  if (s == 'signed') {
    return UrgentAction(
      offerId: offer.id,
      propertyTitle: title,
      type: UrgentActionType.confirmTasacion,
      label: 'Coordinar visita del tasador',
      route: '/offers/${offer.id}/tasacion',
      routeExtra: offer,
      offer: offer,
    );
  }

  return null;
}
