import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config/env_config.dart';
import '../../core/network/dio_factory.dart';

// --- Entity ---

class VisitSlot {
  const VisitSlot({
    required this.windowId,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  final String windowId;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
}

// --- Slots Provider (FutureProvider.family — Riverpod 3 compatible) ---

final slotsProvider = FutureProvider.autoDispose
    .family<List<VisitSlot>, String>((ref, propertyId) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'auth_token');
  final dio = buildAuthDio();
  if (token != null) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
  final resp = await dio.get('/visits/properties/$propertyId/slots');
  final List<dynamic> data = resp.data is List ? resp.data as List : [];
  return data.map((item) {
    final map = item as Map<String, dynamic>;
    return VisitSlot(
      windowId: (map['id'] ?? map['window_id'] ?? '').toString(),
      startTime:
          DateTime.tryParse(map['start_time'] as String? ?? '') ??
              DateTime.now(),
      endTime: DateTime.tryParse(map['end_time'] as String? ?? '') ??
          DateTime.now(),
      isAvailable: map['is_available'] as bool? ?? true,
    );
  }).toList();
});

// --- Book Visit Notifier (Notifier — Riverpod 3 compatible) ---

enum BookingStatus { idle, loading, success, error }

class BookingState {
  const BookingState({this.status = BookingStatus.idle, this.errorMessage});
  final BookingStatus status;
  final String? errorMessage;
}

final bookVisitProvider =
    NotifierProvider<BookVisitNotifier, BookingState>(BookVisitNotifier.new);

class BookVisitNotifier extends Notifier<BookingState> {
  @override
  BookingState build() => const BookingState();

  Future<void> bookSlot({
    required String windowId,
    required DateTime startTime,
    String? notes,
  }) async {
    state = const BookingState(status: BookingStatus.loading);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final dio = buildAuthDio();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      await dio.post('/visits/book', data: {
        'window_id': windowId,
        'start_time': startTime.toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      state = const BookingState(status: BookingStatus.success);
    } catch (e) {
      state = const BookingState(
        status: BookingStatus.error,
        errorMessage: 'No se pudo reservar la visita. Intenta de nuevo.',
      );
    }
  }

  void reset() => state = const BookingState();
}

// ── My Visits Provider ────────────────────────────────────────────────────────

/// A single scheduled visit (booked appointment).
class MyVisit {
  const MyVisit({
    required this.id,
    required this.propertyTitle,
    required this.propertyId,
    required this.startTime,
    required this.status,
    required this.role, // 'buyer' or 'seller'
    this.notes,
  });

  final String id;
  final String propertyTitle;
  final String propertyId;
  final DateTime startTime;
  final String status;
  final String role;
  final String? notes;
}

/// Fetches chat-based visits by scanning action messages via the existing
/// GET /offers/{id}/chat endpoint — no new backend endpoint required.
final chatVisitsProvider = FutureProvider<List<MyVisit>>((ref) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'auth_token');
  if (token == null) return [];

  final dio = buildAuthDio();
  dio.options.headers['Authorization'] = 'Bearer $token';

  // Step 1: get all offers for this user
  List<dynamic> allOffers = [];
  try {
    final me = await dio.get('/users/me');
    final currentUserId = (me.data['id'] ?? '').toString();

    final results = await Future.wait([
      dio.get('/offers/me/sent'),
      dio.get('/offers/me/received'),
    ]);
    final sent = results[0].data is List ? results[0].data as List : [];
    final received = results[1].data is List ? results[1].data as List : [];

    // Keep unique offers; annotate with role
    final seen = <String>{};
    for (final o in [...sent, ...received]) {
      final id = (o['id'] ?? '').toString();
      if (seen.add(id)) {
        final buyerId = ((o['buyer'] as Map?)?['id'] ?? o['buyer_id'] ?? '').toString();
        allOffers.add({...o as Map, '_role': buyerId == currentUserId ? 'buyer' : 'seller'});
      }
    }
  } catch (_) {
    return [];
  }

  if (allOffers.isEmpty) return [];

  // Step 2: for each offer, fetch messages and look for visit actions
  final visits = <MyVisit>[];
  await Future.wait(allOffers.map((offer) async {
    final offerId = (offer['id'] ?? '').toString();
    final propTitle = ((offer['property'] as Map?)?['title'] as String?) ?? 'Propiedad';
    final propId = ((offer['property'] as Map?)?['id'] ?? offer['property_id'] ?? '').toString();
    final role = offer['_role'] as String? ?? 'buyer';

    try {
      final resp = await dio.get('/offers/$offerId/chat');
      final msgs = resp.data is List ? resp.data as List : [];

      // Find latest visit state from action messages
      String? visitStatus;
      String? visitDate;
      for (final m in msgs) {
        final meta = m['metadata'] as Map?;
        if (meta == null) continue;
        final act = meta['action_type'] as String? ?? '';
        if (act == 'visit_request') {
          visitStatus = 'requested';
          visitDate = meta['date'] as String?;
        } else if (act == 'visit_accepted') {
          visitStatus = 'approved';
          visitDate = meta['date'] as String?;
        } else if (act == 'visit_rejected' || act == 'visit_cancelled') {
          visitStatus = 'rejected';
          visitDate = null;
        }
      }

      if (visitStatus == 'requested' || visitStatus == 'approved') {
        visits.add(MyVisit(
          id: 'chat_$offerId',
          propertyTitle: propTitle,
          propertyId: propId,
          startTime: _parseVisitDateStr(visitDate) ?? DateTime.now(),
          status: visitStatus!,
          role: role,
        ));
      }
    } catch (_) {
      // Skip offers where messages can't be loaded
    }
  }));

  return visits;
});

DateTime? _parseVisitDateStr(String? s) {
  if (s == null || s.isEmpty) return null;
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso.toLocal();
  try {
    final parts = s.split(' ');
    final dp = parts[0].split('/');
    final tp = parts.length > 1 ? parts[1].split(':') : ['0', '0'];
    return DateTime(int.parse(dp[2]), int.parse(dp[1]), int.parse(dp[0]),
        int.parse(tp[0]), int.parse(tp[1]));
  } catch (_) {
    return null;
  }
}

/// Fetches all visits for the current user (as buyer + as seller), merged and sorted.
final myVisitsProvider = FutureProvider<List<MyVisit>>((ref) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'auth_token');
  if (token == null) return [];

  final dio = buildAuthDio();
  dio.options.headers['Authorization'] = 'Bearer $token';

  List<dynamic> buyerData = [];
  List<dynamic> sellerData = [];

  try {
    final resp = await dio.get('/visits/agenda', queryParameters: {'role': 'buyer'});
    buyerData = resp.data is List ? resp.data as List : [];
  } catch (_) {}

  try {
    final resp = await dio.get('/visits/agenda', queryParameters: {'role': 'seller'});
    sellerData = resp.data is List ? resp.data as List : [];
  } catch (_) {}

  MyVisit _map(dynamic item, String role) {
    final map = item as Map<String, dynamic>;
    final window = map['window'] as Map<String, dynamic>? ?? {};
    final property = window['property'] as Map<String, dynamic>? ?? {};
    return MyVisit(
      id: (map['id'] ?? '').toString(),
      propertyTitle: (property['title'] as String?) ?? 'Propiedad',
      propertyId: (property['id'] ?? '').toString(),
      startTime:
          DateTime.tryParse(map['start_time'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      status: (map['status'] as String?) ?? 'requested',
      role: role,
      notes: map['notes'] as String?,
    );
  }

  final all = [
    ...buyerData.map((e) => _map(e, 'buyer')),
    ...sellerData.map((e) => _map(e, 'seller')),
  ];

  // Deduplicate by id (shouldn't happen but safe)
  final seen = <String>{};
  final unique = all.where((v) => seen.add(v.id)).toList();
  unique.sort((a, b) => a.startTime.compareTo(b.startTime));
  return unique;
});

// --- Request Visit by Email (when no slots available) ---

enum EmailRequestStatus { idle, loading, success, error }

class EmailRequestState {
  const EmailRequestState({this.status = EmailRequestStatus.idle, this.errorMessage});
  final EmailRequestStatus status;
  final String? errorMessage;
}

final requestVisitByEmailProvider =
    NotifierProvider<RequestVisitByEmailNotifier, EmailRequestState>(
        RequestVisitByEmailNotifier.new);

class RequestVisitByEmailNotifier extends Notifier<EmailRequestState> {
  @override
  EmailRequestState build() => const EmailRequestState();

  Future<void> request({
    required String propertyId,
    String message = '',
  }) async {
    state = const EmailRequestState(status: EmailRequestStatus.loading);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final dio = buildAuthDio();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      await dio.post('/visits/request-email', data: {
        'property_id': int.tryParse(propertyId) ?? 0,
        'message': message,
      });
      state = const EmailRequestState(status: EmailRequestStatus.success);
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data['detail'] as String? ?? 'Error al enviar la solicitud')
          : 'Error al enviar la solicitud';
      state = EmailRequestState(
        status: EmailRequestStatus.error,
        errorMessage: detail,
      );
    } catch (_) {
      state = const EmailRequestState(
        status: EmailRequestStatus.error,
        errorMessage: 'Error inesperado. Intentalo de nuevo.',
      );
    }
  }

  void reset() => state = const EmailRequestState();
}

final cancelVisitProvider = FutureProvider.family<bool, String>((ref, appointmentId) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'auth_token');
  if (token == null) return false;

  final dio = buildAuthDio();
  dio.options.headers['Authorization'] = 'Bearer $token';

  try {
    await dio.patch('/visits/$appointmentId/status', data: {
      'status': 'cancelled',
    });
    return true;
  } catch (_) {
    return false;
  }
});
