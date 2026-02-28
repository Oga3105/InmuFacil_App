import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _kVisitsApiBaseUrl = 'http://localhost:8000/api/v1';

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
  final dio = Dio(BaseOptions(baseUrl: _kVisitsApiBaseUrl));
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
      final dio = Dio(BaseOptions(baseUrl: _kVisitsApiBaseUrl));
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
