/// Modelo de datos para una notificacion del Centro de Notificaciones.
///
/// Mapea directamente al schema `NotificationResponse` del backend.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    this.deepLink,
    this.offerId,
    this.urgencyType,
    this.sentAt,
  });

  final int id;
  final String title;
  final String body;
  final String notificationType;
  final bool isRead;
  final DateTime createdAt;
  final String? deepLink;
  final int? offerId;
  final String? urgencyType;
  final DateTime? sentAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      notificationType: json['notification_type'] as String? ?? 'urgency',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      deepLink: json['deep_link'] as String?,
      offerId: json['offer_id'] as int?,
      urgencyType: json['urgency_type'] as String?,
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'] as String)
          : null,
    );
  }
}

/// Respuesta completa de la lista de notificaciones del backend.
class NotificationListModel {
  const NotificationListModel({
    required this.items,
    required this.total,
    required this.unreadCount,
  });

  final List<NotificationModel> items;
  final int total;
  final int unreadCount;

  factory NotificationListModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return NotificationListModel(
      items: rawItems
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  static const empty = NotificationListModel(
    items: [],
    total: 0,
    unreadCount: 0,
  );
}
