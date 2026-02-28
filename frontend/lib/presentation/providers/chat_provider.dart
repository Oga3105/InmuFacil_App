import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _kApiBaseUrl = 'http://localhost:8000/api/v1';

// --- Entities ---

class ChatConversation {
  const ChatConversation({
    required this.offerId,
    required this.otherUserName,
    required this.propertyTitle,
    required this.propertyId,
    required this.lastMessage,
    required this.lastDate,
    this.unreadCount = 0,
  });

  final String offerId;
  final String otherUserName;
  final String propertyTitle;
  final String propertyId;
  final String lastMessage;
  final DateTime lastDate;
  final int unreadCount;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.timestamp,
  });

  final String id;
  final String senderId;
  final String message;
  final DateTime timestamp;
}

// --- Chat List Provider ---

final chatListProvider =
    AsyncNotifierProvider<ChatListNotifier, List<ChatConversation>>(
  ChatListNotifier.new,
);

class ChatListNotifier extends AsyncNotifier<List<ChatConversation>> {
  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  @override
  Future<List<ChatConversation>> build() async {
    _dio = Dio(BaseOptions(baseUrl: _kApiBaseUrl));
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return _fetchConversations();
  }

  Future<List<ChatConversation>> _fetchConversations() async {
    final results = await Future.wait([
      _dio.get('/offers/me/sent'),
      _dio.get('/offers/me/received'),
    ]);

    final List<dynamic> sent =
        results[0].data is List ? results[0].data as List : [];
    final List<dynamic> received =
        results[1].data is List ? results[1].data as List : [];

    final allOffers = [...sent, ...received];
    final seen = <String>{};
    final conversations = <ChatConversation>[];

    for (final offer in allOffers) {
      final map = offer as Map<String, dynamic>;
      final isChatEnabled = map['is_chat_enabled'] as bool? ?? false;
      if (!isChatEnabled) continue;

      final id = (map['id'] ?? '').toString();
      if (seen.contains(id)) continue;
      seen.add(id);

      final property = map['property'] as Map<String, dynamic>? ?? {};
      final buyer = map['buyer'] as Map<String, dynamic>? ?? {};
      final seller = map['seller'] as Map<String, dynamic>? ?? {};
      final currentUserId = await _storage.read(key: 'user_id');
      final buyerId = (buyer['id'] ?? '').toString();
      final otherUser = (buyerId == currentUserId) ? seller : buyer;
      final otherName =
          '${otherUser['first_name'] ?? ''} ${otherUser['last_name'] ?? ''}'
              .trim();

      conversations.add(ChatConversation(
        offerId: id,
        otherUserName: otherName.isEmpty ? 'Usuario' : otherName,
        propertyTitle: property['title'] as String? ?? 'Propiedad',
        propertyId: (property['id'] ?? '').toString(),
        lastMessage: map['last_message'] as String? ?? '',
        lastDate:
            DateTime.tryParse(map['updated_at'] as String? ?? '') ??
                DateTime.now(),
        unreadCount: (map['unread_count'] as int?) ?? 0,
      ));
    }

    conversations.sort((a, b) => b.lastDate.compareTo(a.lastDate));
    return conversations;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchConversations);
  }
}

// --- Chat Detail Provider (read messages) ---

final chatDetailProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, offerId) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'auth_token');
  final dio = Dio(BaseOptions(baseUrl: _kApiBaseUrl));
  if (token != null) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
  final resp = await dio.get('/offers/$offerId/chat');
  final List<dynamic> data = resp.data is List ? resp.data as List : [];
  return data.map((item) {
    final map = item as Map<String, dynamic>;
    return ChatMessage(
      id: (map['id'] ?? '').toString(),
      senderId: (map['sender_id'] ?? '').toString(),
      message: map['message'] as String? ?? '',
      timestamp:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }).toList();
});

// --- Send Message (used directly in screen via ref.read) ---

Future<void> sendChatMessage(
    WidgetRef ref, String offerId, String text) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'auth_token');
  final dio = Dio(BaseOptions(baseUrl: _kApiBaseUrl));
  if (token != null) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
  await dio.post('/offers/$offerId/chat', data: {'message': text});
  ref.invalidate(chatDetailProvider(offerId));
}
