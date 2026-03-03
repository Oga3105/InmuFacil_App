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
    this.isOptimistic = false,
  });

  final String id;
  final String senderId;
  final String message;
  final DateTime timestamp;

  /// True while the message is being sent (optimistic update, not yet confirmed).
  final bool isOptimistic;
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
    if (token == null) return [];
    _dio.options.headers['Authorization'] = 'Bearer $token';
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
      ),);
    }

    conversations.sort((a, b) => b.lastDate.compareTo(a.lastDate));
    return conversations;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchConversations);
  }
}

// --- Chat Detail Provider (AsyncNotifier with optimistic send) ---

// Riverpod 3.x: factory receives the arg and injects it via constructor.
final chatDetailProvider = AsyncNotifierProvider.autoDispose
    .family<ChatDetailNotifier, List<ChatMessage>, String>(
  (offerId) => ChatDetailNotifier(offerId),
);

class ChatDetailNotifier extends AsyncNotifier<List<ChatMessage>> {
  ChatDetailNotifier(this._offerId);

  final String _offerId;
  late final Dio _dio;
  String? _currentUserId;

  /// The authenticated user's ID — available once [build] completes.
  String? get currentUserId => _currentUserId;

  @override
  Future<List<ChatMessage>> build() async {
    _dio = Dio(BaseOptions(baseUrl: _kApiBaseUrl));
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    _currentUserId = await storage.read(key: 'user_id');
    return _fetchMessages(_offerId);
  }

  Future<List<ChatMessage>> _fetchMessages(String offerId) async {
    final resp = await _dio.get('/offers/$offerId/chat');
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
  }

  /// Sends [text] with an optimistic UI update.
  /// On success replaces the optimistic item with the server-confirmed message.
  /// On failure reverts to previous state.
  Future<void> sendMessage(String text) async {
    final prev = state.asData?.value ?? [];
    final optimistic = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUserId ?? '',
      message: text,
      timestamp: DateTime.now(),
      isOptimistic: true,
    );
    state = AsyncData([...prev, optimistic]);
    try {
      await _dio.post('/offers/$_offerId/chat', data: {'message': text});
      state = AsyncData(await _fetchMessages(_offerId));
    } catch (e) {
      state = AsyncData(prev);
      rethrow;
    }
  }
}
