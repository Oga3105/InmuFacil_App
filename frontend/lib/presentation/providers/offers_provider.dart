import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    this.propertyTitle,
    this.propertyPrice,
    this.propertyImageUrl,
  });

  final String id;
  final String propertyId;
  final String buyerId;
  final double amount;
  final String status;
  final String? conditions;
  final String? paymentTerm;
  final DateTime? closingDate;
  final DateTime? createdAt;
  final String? buyerName;
  final String? propertyTitle;
  final double? propertyPrice;
  final String? propertyImageUrl;
}

// --- Sent Offers Provider ---

final sentOffersProvider =
    AsyncNotifierProvider<SentOffersNotifier, List<OfferData>>(
  SentOffersNotifier.new,
);

class SentOffersNotifier extends AsyncNotifier<List<OfferData>> {
  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  @override
  Future<List<OfferData>> build() async {
    _dio = Dio(BaseOptions(baseUrl: _kOffersApiBaseUrl));
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
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
}

// --- Received Offers Provider ---

final receivedOffersProvider =
    AsyncNotifierProvider<ReceivedOffersNotifier, List<OfferData>>(
  ReceivedOffersNotifier.new,
);

class ReceivedOffersNotifier extends AsyncNotifier<List<OfferData>> {
  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  @override
  Future<List<OfferData>> build() async {
    _dio = Dio(BaseOptions(baseUrl: _kOffersApiBaseUrl));
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
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

  Future<void> counter(String offerId, double newAmount) async {
    await _dio.post('/offers/$offerId/counter', data: {'amount': newAmount});
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
    required double amount,
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
  return OfferData(
    id: (map['id'] ?? '').toString(),
    propertyId: (property['id'] ?? map['property_id'] ?? '').toString(),
    buyerId: (buyer['id'] ?? map['buyer_id'] ?? '').toString(),
    amount: ((map['amount'] ?? 0) as num).toDouble(),
    status: map['status'] as String? ?? 'pending',
    conditions: map['conditions'] as String?,
    paymentTerm: map['payment_term'] as String?,
    closingDate: DateTime.tryParse(map['closing_date'] as String? ?? ''),
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
    buyerName:
        '${buyer['first_name'] ?? ''} ${buyer['last_name'] ?? ''}'.trim(),
    propertyTitle: property['title'] as String?,
    propertyPrice: ((property['price'] ?? 0) as num).toDouble(),
    propertyImageUrl: imageUrl,
  );
}
