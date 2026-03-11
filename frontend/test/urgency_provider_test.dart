// @Jules — TDD: Urgency Engine
//
// Tests for buyerBlockingAction() and sellerBlockingAction() helpers.
// These are pure functions with no Flutter or Riverpod dependencies,
// so they run as standard Dart unit tests.
//
// Run: flutter test test/urgency_provider_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:inmufacil_frontend/presentation/providers/offers_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/urgency_provider.dart';

// ─── Fixture helpers ──────────────────────────────────────────────────────────

OfferData _offer({
  required String status,
  String id = '1',
  String buyerId = 'buyer-1',
  String propertyTitle = 'Calle Mayor 1',
  bool buyerIsVerified = true,
  bool buyerSolvencySubmitted = false,
  bool sellerSolvencyAccepted = false,
  String? paymentMethod,
}) =>
    OfferData(
      id: id,
      propertyId: 'prop-1',
      buyerId: buyerId,
      amount: 200000,
      status: status,
      propertyTitle: propertyTitle,
      buyerIsVerified: buyerIsVerified,
      buyerSolvencySubmitted: buyerSolvencySubmitted,
      sellerSolvencyAccepted: sellerSolvencyAccepted,
      paymentMethod: paymentMethod,
    );

// ─── Buyer tests ──────────────────────────────────────────────────────────────

void main() {
  group('buyerBlockingAction', () {
    test('returns null for terminal statuses (rejected, withdrawn, completed)',
        () {
      for (final s in ['rejected', 'withdrawn', 'completed']) {
        expect(
          buyerBlockingAction(_offer(status: s), 'buyer-1'),
          isNull,
          reason: 'status=$s should not block',
        );
      }
    });

    test('returns null for pre-acceptance statuses (pending, counter_offer)',
        () {
      for (final s in ['pending', 'counter_offer']) {
        expect(buyerBlockingAction(_offer(status: s), 'buyer-1'), isNull);
      }
    });

    test('returns null when current user is NOT the buyer', () {
      final offer = _offer(status: 'signing_pending', buyerId: 'buyer-1');
      expect(buyerBlockingAction(offer, 'other-user'), isNull);
    });

    test('verify_identity is top priority when buyer not verified', () {
      final offer = _offer(
        status: 'signing_pending',
        buyerIsVerified: false,
        buyerSolvencySubmitted: true,
      );
      final action = buyerBlockingAction(offer, 'buyer-1');
      expect(action, isNotNull);
      expect(action!.type, UrgentActionType.verifyIdentity);
      expect(action.route, '/verify-identity');
    });

    test('complete_solvency when accepted and solvency not submitted', () {
      final offer = _offer(
        status: 'accepted',
        buyerSolvencySubmitted: false,
      );
      final action = buyerBlockingAction(offer, 'buyer-1');
      expect(action, isNotNull);
      expect(action!.type, UrgentActionType.completeSolvency);
      expect(action.route, '/solvency/wizard');
    });

    test('no buyer action when accepted + solvency submitted + not yet accepted by seller',
        () {
      // Buyer is waiting — seller must review
      final offer = _offer(
        status: 'accepted',
        buyerSolvencySubmitted: true,
        sellerSolvencyAccepted: false,
      );
      expect(buyerBlockingAction(offer, 'buyer-1'), isNull);
    });

    test('sign_arras when status is signing_pending', () {
      final offer = _offer(status: 'signing_pending');
      final action = buyerBlockingAction(offer, 'buyer-1');
      expect(action, isNotNull);
      expect(action!.type, UrgentActionType.signArras);
      expect(action.route, '/offers/1/arras');
      expect(action.routeExtra, offer);
    });

    test('confirm_fein when signed + mortgage payment method', () {
      for (final pm in [
        'mortgage_pending',
        'mortgage_approved',
        'savings_plus_mortgage',
        'bridge_mortgage',
      ]) {
        final offer = _offer(status: 'signed', paymentMethod: pm);
        final action = buyerBlockingAction(offer, 'buyer-1');
        expect(action, isNotNull, reason: 'paymentMethod=$pm should need FEIN');
        expect(action!.type, UrgentActionType.confirmFein);
        expect(action.route, '/offers/1/fein');
      }
    });

    test('confirm_tasacion when signed + non-mortgage payment method', () {
      for (final pm in ['cash', 'house_to_sell', null]) {
        final offer = _offer(status: 'signed', paymentMethod: pm);
        final action = buyerBlockingAction(offer, 'buyer-1');
        expect(action, isNotNull);
        expect(action!.type, UrgentActionType.confirmTasacion);
        expect(action.route, '/offers/1/tasacion');
      }
    });
  });

  // ─── Seller tests ───────────────────────────────────────────────────────────

  group('sellerBlockingAction', () {
    test('returns null when no blocking condition applies (e.g. pending)', () {
      // Pending = waiting on seller to accept/reject — not a "blocker" in our model
      expect(sellerBlockingAction(_offer(status: 'pending')), isNull);
    });

    test('review_solvency when accepted + submitted + not yet accepted', () {
      final offer = _offer(
        status: 'accepted',
        buyerSolvencySubmitted: true,
        sellerSolvencyAccepted: false,
      );
      final action = sellerBlockingAction(offer);
      expect(action, isNotNull);
      expect(action!.type, UrgentActionType.reviewSolvency);
      expect(action.route, '/offers/1/timeline');
    });

    test('no seller action when accepted but buyer has not submitted solvency yet',
        () {
      final offer = _offer(
        status: 'accepted',
        buyerSolvencySubmitted: false,
      );
      expect(sellerBlockingAction(offer), isNull);
    });

    test('no seller action when solvency already accepted', () {
      final offer = _offer(
        status: 'accepted',
        buyerSolvencySubmitted: true,
        sellerSolvencyAccepted: true,
      );
      expect(sellerBlockingAction(offer), isNull);
    });

    test('sign_arras for seller when signing_pending', () {
      final offer = _offer(status: 'signing_pending');
      final action = sellerBlockingAction(offer);
      expect(action, isNotNull);
      expect(action!.type, UrgentActionType.signArras);
      expect(action.route, '/offers/1/arras');
    });

    test('confirm_tasacion for seller when signed', () {
      final offer = _offer(status: 'signed');
      final action = sellerBlockingAction(offer);
      expect(action, isNotNull);
      expect(action!.type, UrgentActionType.confirmTasacion);
      expect(action.route, '/offers/1/tasacion');
    });

    test('returns null for terminal statuses', () {
      for (final s in ['completed', 'rejected', 'withdrawn']) {
        expect(sellerBlockingAction(_offer(status: s)), isNull,
            reason: 'status=$s should not block seller');
      }
    });
  });

  // ─── Sort priority tests ────────────────────────────────────────────────────

  group('UrgentAction.sortPriority', () {
    test('sign_arras has higher priority (lower number) than confirm_fein', () {
      final arras = _dummyAction(UrgentActionType.signArras);
      final fein = _dummyAction(UrgentActionType.confirmFein);
      expect(arras.sortPriority, lessThan(fein.sortPriority));
    });

    test('confirm_fein has higher priority than completeSolvency', () {
      final fein = _dummyAction(UrgentActionType.confirmFein);
      final solvency = _dummyAction(UrgentActionType.completeSolvency);
      expect(fein.sortPriority, lessThan(solvency.sortPriority));
    });
  });
}

UrgentAction _dummyAction(UrgentActionType type) => UrgentAction(
      offerId: '1',
      propertyTitle: 'Test',
      type: type,
      label: 'Test label',
      route: '/test',
      offer: _offer(status: 'signed'),
    );
