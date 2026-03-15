import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'chat_provider.dart';

const String _kOffersApiBaseUrl = 'http://localhost:8000/api/v1';

// --- Entity ---

class OfferData {
  const OfferData({
    required this.id,
    required this.propertyId,
    required this.buyerId,
    required this.amount,
    required this.status,
    this.conditions,
    this.paymentTerm,
    this.closingDate,
    this.createdAt,
    this.buyerName,
    this.buyerPhotoUrl,
    this.buyerIsVerified = false,
    this.sellerName,
    this.propertyTitle,
    this.propertyPrice,
    this.propertyImageUrl,
    this.isChatEnabled = false,
    this.confirmedVisitDate,
    this.requestedVisitDate,
    this.visitStatus,
    this.paymentMethod,
    this.buyerSolvencySubmitted = false,
    this.sellerSolvencyAccepted = false,
    this.secondBuyerPending = false,
    this.tasacionStatus,
    this.feinBuyerConfirmed = false,
    this.notariaApptStatus,
  });

  final String id;
  final String propertyId;
  final String buyerId;
  final int amount;
  final String status;
  final String? conditions;
  final String? paymentTerm;
  final DateTime? closingDate;
  final DateTime? createdAt;
  final String? buyerName;
  final String? buyerPhotoUrl;
  final bool buyerIsVerified;
  final String? sellerName;
  final String? propertyTitle;
  final int? propertyPrice;
  final String? propertyImageUrl;
  final bool isChatEnabled;

  /// Date string of the confirmed visit (from visit_accepted chat action), if any.
  final String? confirmedVisitDate;

  /// Date string of the requested visit (from visit_request chat action), if any.
  final String? requestedVisitDate;

  /// Status of the latest visit action (requested, approved, rejected, cancelled).
  final String? visitStatus;

  /// Buyer's declared payment method (e.g. cash, mortgage_pending, savings_plus_mortgage).
  /// Null when the buyer has not yet submitted their solvency passport.
  final String? paymentMethod;

  /// True when the buyer has submitted their solvency passport for this offer.
  final bool buyerSolvencySubmitted;

  /// True when the seller has explicitly validated the buyer's solvency passport.
  final bool sellerSolvencyAccepted;

  /// True when buyer declared joint purchase (is_multi_buyer) but the second
  /// buyer has not yet submitted and verified their identity data.
  final bool secondBuyerPending;

  /// Sub-status of the TASACION_APPOINTMENT step: pending|proposed|rejected|accepted|completed.
  /// Null when the step has not been created yet.
  final String? tasacionStatus;

  /// True when the buyer has confirmed receipt of the FEIN document from their bank.
  final bool feinBuyerConfirmed;

  /// Sub-status of the NOTARIA_APPOINTMENT step: pending|scheduled|completed.
  /// Null when the step has not been created yet.
  final String? notariaApptStatus;
}

// --- Sent Offers Provider ---

final sentOffersProvider =
    AsyncNotifierProvider<SentOffersNotifier, List<OfferData>>(
  SentOffersNotifier.new,
);

class SentOffersNotifier extends AsyncNotifier<List<OfferData>> {
  final _storage = const FlutterSecureStorage();
  late Dio _dio;

  @override
  Future<List<OfferData>> build() async {
    _dio = Dio(BaseOptions(baseUrl: _kOffersApiBaseUrl));
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return [];
    _dio.options.headers['Authorization'] = 'Bearer $token';
    return _fetch();
  }

  Future<List<OfferData>> _fetch() async {
    final resp = await _dio.get('/offers/me/sent');
    final List<dynamic> data = resp.data is List ? resp.data as List : [];
    return data.map(_mapOffer).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Buyer withdraws their offer.
  Future<void> withdraw(String offerId) async {
    await _dio.post('/offers/$offerId/withdraw');
    await refresh();
  }

  /// Buyer accepts the seller's counter-offer.
  Future<void> accept(String offerId) async {
    await _dio.post('/offers/$offerId/accept');
    await refresh();
  }

  /// Buyer sends a counter back to the seller (resets to PENDING with new amount).
  Future<void> counterBack(String offerId, int newAmount) async {
    await _dio.post('/offers/$offerId/counter', data: {'amount': newAmount});
    await refresh();
  }

  /// Buyer rejects the seller's counter-offer (terminates negotiation).
  Future<void> reject(String offerId) async {
    await _dio.post('/offers/$offerId/reject');
    await refresh();
  }

  /// Enable chat for an offer (both buyer and seller can call this).
  Future<void> enableChat(String offerId) async {
    await _dio.post('/offers/$offerId/chat/enable');
    // Refresh chat list so the conversation appears in the inbox
    ref.invalidate(chatListProvider);
  }
}

// --- Received Offers Provider ---

final receivedOffersProvider =
    AsyncNotifierProvider<ReceivedOffersNotifier, List<OfferData>>(
  ReceivedOffersNotifier.new,
);

class ReceivedOffersNotifier extends AsyncNotifier<List<OfferData>> {
  final _storage = const FlutterSecureStorage();
  late Dio _dio;

  @override
  Future<List<OfferData>> build() async {
    _dio = Dio(BaseOptions(baseUrl: _kOffersApiBaseUrl));
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return [];
    _dio.options.headers['Authorization'] = 'Bearer $token';
    return _fetch();
  }

  Future<List<OfferData>> _fetch() async {
    final resp = await _dio.get('/offers/me/received');
    final List<dynamic> data = resp.data is List ? resp.data as List : [];
    return data.map(_mapOffer).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> accept(String offerId) async {
    await _dio.post('/offers/$offerId/accept');
    await refresh();
  }

  Future<void> counter(String offerId, int newAmount) async {
    await _dio.post('/offers/$offerId/counter', data: {'amount': newAmount});
    await refresh();
  }

  Future<void> reject(String offerId) async {
    await _dio.post('/offers/$offerId/reject');
    await refresh();
  }

  /// Enable chat for an offer.
  Future<void> enableChat(String offerId) async {
    await _dio.post('/offers/$offerId/chat/enable');
    // Refresh chat list so the conversation appears in the inbox
    ref.invalidate(chatListProvider);
  }

  /// Seller accepts the buyer's solvency passport to unlock the timeline.
  Future<void> acceptSolvency(String offerId) async {
    // Use full URL — solvency router has a different prefix than offers router
    await _dio.post('${_kOffersApiBaseUrl}/solvency/offer/$offerId/accept');
    await refresh();
  }
}

// --- Make Offer Notifier (Notifier — Riverpod 3 compatible) ---

enum OfferSubmitStatus { idle, loading, success, error }

class OfferFormState {
  const OfferFormState({
    this.status = OfferSubmitStatus.idle,
    this.errorMessage,
  });
  final OfferSubmitStatus status;
  final String? errorMessage;
}

final makeOfferProvider =
    NotifierProvider<MakeOfferNotifier, OfferFormState>(MakeOfferNotifier.new);

class MakeOfferNotifier extends Notifier<OfferFormState> {
  @override
  OfferFormState build() => const OfferFormState();

  Future<void> submit({
    required String propertyId,
    required int amount,
    String? conditions,
    String? paymentTerm,
    DateTime? closingDate,
  }) async {
    state = const OfferFormState(status: OfferSubmitStatus.loading);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final dio = Dio(BaseOptions(baseUrl: _kOffersApiBaseUrl));
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      final body = <String, dynamic>{
        'property_id': propertyId,
        'amount': amount,
        if (conditions != null && conditions.isNotEmpty)
          'conditions': conditions,
        if (paymentTerm != null) 'payment_term': paymentTerm,
        if (closingDate != null)
          'closing_date': closingDate.toIso8601String().substring(0, 10),
      };
      await dio.post('/offers/', data: body);
      state = const OfferFormState(status: OfferSubmitStatus.success);
    } catch (e) {
      state = const OfferFormState(
        status: OfferSubmitStatus.error,
        errorMessage: 'No se pudo enviar la oferta. Intenta de nuevo.',
      );
    }
  }

  void reset() => state = const OfferFormState();
}

// --- Shared mapper ---

OfferData _mapOffer(dynamic item) {
  final map = item as Map<String, dynamic>;
  final property = map['property'] as Map<String, dynamic>? ?? {};
  final buyer = map['buyer'] as Map<String, dynamic>? ?? {};
  final mediaList = property['media'] as List<dynamic>? ?? [];
  final imageUrl = mediaList.isNotEmpty
      ? (mediaList.first as Map<String, dynamic>)['file_path'] as String?
      : null;
  final buyerFullName = buyer['full_name'] as String?;
  final sellerName = property['seller_name'] as String?;
  final buyerPhotoUrl = buyer['photo_url'] as String?;
  final buyerIsVerified = buyer['is_verified'] as bool? ?? false;
  final offer = OfferData(
    id: (map['id'] ?? '').toString(),
    propertyId: (property['id'] ?? map['property_id'] ?? '').toString(),
    buyerId: (buyer['id'] ?? map['buyer_id'] ?? '').toString(),
    amount: ((map['amount'] ?? 0) as num).round(),
    status: map['status'] as String? ?? 'pending',
    conditions: map['conditions'] as String?,
    paymentTerm: map['payment_term'] as String?,
    closingDate: DateTime.tryParse(map['closing_date'] as String? ?? ''),
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
    buyerName: buyerFullName?.trim(),
    buyerPhotoUrl: buyerPhotoUrl,
    buyerIsVerified: buyerIsVerified,
    sellerName: sellerName?.trim(),
    propertyTitle: property['title'] as String?,
    propertyPrice: ((property['price'] ?? 0) as num).round(),
    propertyImageUrl: imageUrl,
    isChatEnabled: map['is_chat_enabled'] as bool? ?? false,
    confirmedVisitDate: map['confirmed_visit_date'] as String?,
    requestedVisitDate: map['requested_visit_date'] as String?,
    visitStatus: map['visit_status'] as String?,
    paymentMethod: map['payment_method'] as String?,
    buyerSolvencySubmitted: map['buyer_solvency_submitted'] as bool? ?? false,
    sellerSolvencyAccepted: map['seller_solvency_accepted'] as bool? ?? false,
    secondBuyerPending: map['second_buyer_pending'] as bool? ?? false,
    tasacionStatus: map['tasacion_appointment_status'] as String?,
    feinBuyerConfirmed: map['fein_buyer_confirmed'] as bool? ?? false,
    notariaApptStatus: map['notaria_appt_status'] as String?,
  );

  return offer;
}
