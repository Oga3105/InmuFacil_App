import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/notification_model.dart';
import 'auth_provider.dart';
import 'urgency_provider.dart';

const String _kBaseUrl = 'http://localhost:8000/api/v1';

// ─── Dio helpers (reusa el patron existente del proyecto) ─────────────────────

Future<String?> _getToken() async {
  const storage = FlutterSecureStorage();
  return storage.read(key: 'auth_token');
}

Dio _buildDio() => Dio(BaseOptions(baseUrl: _kBaseUrl));

// ─── Provider principal: historial de notificaciones ──────────────────────────

/// Carga y mantiene el historial de notificaciones del usuario autenticado.
/// autoDispose: se destruye cuando ningun widget lo observa (e.g., al salir de la pantalla).
final notificationsProvider =
    FutureProvider.autoDispose<NotificationListModel>((ref) async {
  final isAuth = ref.watch(authProvider).isAuthenticated;
  if (!isAuth) return NotificationListModel.empty;

  final token = await _getToken();
  if (token == null) return NotificationListModel.empty;

  final dio = _buildDio();
  final response = await dio.get(
    '/notifications',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  return NotificationListModel.fromJson(
    response.data as Map<String, dynamic>,
  );
});

/// Conteo de notificaciones no leidas — observado por la campana en la AppBar.
/// Se mantiene en cache mientras el notificationsProvider este activo.
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final asyncList = ref.watch(notificationsProvider);
  return asyncList.asData?.value.unreadCount ?? 0;
});

// ─── Operaciones mutativas ────────────────────────────────────────────────────

/// Marca una notificacion como leida y refresca el provider.
Future<void> markNotificationRead(WidgetRef ref, int notificationId) async {
  final token = await _getToken();
  if (token == null) return;

  final dio = _buildDio();
  await dio.patch(
    '/notifications/$notificationId/read',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  ref.invalidate(notificationsProvider);
}

/// Marca todas las notificaciones como leidas y refresca.
Future<void> markAllNotificationsRead(WidgetRef ref) async {
  final token = await _getToken();
  if (token == null) return;

  final dio = _buildDio();
  await dio.patch(
    '/notifications/read-all',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  ref.invalidate(notificationsProvider);
}

/// Sincroniza las acciones urgentes calculadas por el urgencyProvider con el backend.
/// Debe llamarse en el login o cuando cambia el estado de urgencia.
/// Es idempotente: el backend usa upsert, no genera duplicados.
Future<void> syncUrgencyNotifications(WidgetRef ref) async {
  final token = await _getToken();
  if (token == null) return;

  final urgentActions = ref.read(urgencyProvider);
  if (urgentActions.isEmpty) return;

  final payload = urgentActions
      .map(
        (action) => {
          'offer_id': action.offerId,
          'property_title': action.propertyTitle,
          'urgency_type': action.type.name,
          'label': action.label,
          'route': action.route,
        },
      )
      .toList();

  final dio = _buildDio();
  try {
    await dio.post(
      '/notifications/sync',
      data: {'urgent_actions': payload},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    ref.invalidate(notificationsProvider);
  } on DioException catch (_) {
    // Degradacion elegante: el historial en pantalla se obtiene en la proxima carga
  }
}

/// Registra el token FCM del dispositivo en el backend.
Future<void> registerFcmToken(String fcmToken) async {
  final token = await _getToken();
  if (token == null) return;

  final dio = _buildDio();
  try {
    await dio.post(
      '/notifications/register-fcm-token',
      data: {'fcm_token': fcmToken},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  } on DioException catch (_) {
    // No critico: se reintentara en la proxima sesion
  }
}
