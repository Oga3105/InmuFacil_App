import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const String _kApiBaseUrl = 'http://localhost:8000/api/v1';
const String _kWsBaseUrl  = 'ws://localhost:8000/api/v1';

// ── Trust badge levels ────────────────────────────────────────────────────────

enum TrustBadge { none, bronze, silver, gold }

TrustBadge _deriveTrustBadge({
  required bool emailVerified,
  required bool dniVerified,
  required bool fullKyc,
}) {
  if (fullKyc) return TrustBadge.gold;
  if (dniVerified) return TrustBadge.silver;
  if (emailVerified) return TrustBadge.bronze;
  return TrustBadge.none;
}

// ── Entities ──────────────────────────────────────────────────────────────────

class ChatConversation {
  const ChatConversation({
    required this.offerId,
    required this.otherUserName,
    required this.otherUserPhotoUrl,
    required this.trustBadge,
    required this.propertyTitle,
    required this.propertyId,
    required this.lastMessage,
    required this.lastDate,
    this.unreadCount = 0,
  });

  final String offerId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final TrustBadge trustBadge;
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
    this.messageType = 'text',
    this.metadata,
    this.isRead = false,
    this.isOptimistic = false,
  });

  final String id;
  final String senderId;
  final String message;
  final DateTime timestamp;

  /// 'text' | 'action'
  final String messageType;

  /// Populated for messageType == 'action'.
  /// Keys: action_type ('offer_proposal' | 'visit_request' | 'docs_request'),
  ///       amount (double?), date (ISO string?), notes (string?).
  final Map<String, dynamic>? metadata;

  final bool isRead;

  /// True while the message is being sent (optimistic update, not yet confirmed).
  final bool isOptimistic;

  bool get isAction => messageType == 'action';
}

// ── Chat List Provider ────────────────────────────────────────────────────────

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

    final currentUserId = await _storage.read(key: 'user_id');

    for (final offer in allOffers) {
      final map = offer as Map<String, dynamic>;
      final isChatEnabled = map['is_chat_enabled'] as bool? ?? false;
      if (!isChatEnabled) continue;

      final id = (map['id'] ?? '').toString();
      if (seen.contains(id)) continue;
      seen.add(id);

      final property = map['property'] as Map<String, dynamic>? ?? {};
      final buyer = map['buyer'] as Map<String, dynamic>? ?? {};

      final buyerId = (buyer['id'] ?? '').toString();
      final isBuyer = buyerId == currentUserId;

      // Determine the other user's info
      String otherName;
      String? otherPhotoUrl;
      bool otherEmailVerified = false;
      bool otherDniVerified = false;
      bool otherFullKyc = false;

      if (isBuyer) {
        // Current user is buyer → other user is seller (property owner)
        final sellerName = property['seller_name'] as String? ?? '';
        otherName = sellerName.trim().isEmpty ? 'Vendedor' : sellerName.trim();
        otherPhotoUrl = null; // Seller photo not yet in snippet
      } else {
        // Current user is seller → other user is buyer
        otherName = (buyer['full_name'] as String? ?? '').trim();
        if (otherName.isEmpty) otherName = 'Comprador';
        otherPhotoUrl = buyer['photo_url'] as String?;
        otherEmailVerified = true; // Buyer passed registration
        otherDniVerified = buyer['is_verified'] as bool? ?? false;
        otherFullKyc = otherDniVerified;
      }

      final badge = _deriveTrustBadge(
        emailVerified: otherEmailVerified,
        dniVerified: otherDniVerified,
        fullKyc: otherFullKyc,
      );

      conversations.add(ChatConversation(
        offerId: id,
        otherUserName: otherName,
        otherUserPhotoUrl: otherPhotoUrl,
        trustBadge: badge,
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

// ── Chat Detail Provider ──────────────────────────────────────────────────────

final chatDetailProvider = AsyncNotifierProvider.autoDispose
    .family<ChatDetailNotifier, List<ChatMessage>, String>(
  (offerId) => ChatDetailNotifier(offerId),
);

/// Tracks WebSocket connection state per offerId (OUR connection).
class _WsConnectedNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => {};
  void setConnected(String offerId, bool value) {
    state = {...state, offerId: value};
  }
  bool isConnected(String offerId) => state[offerId] ?? false;
}

final chatWsConnectedProvider =
    NotifierProvider<_WsConnectedNotifier, Map<String, bool>>(
  _WsConnectedNotifier.new,
);

/// Tracks whether the OTHER participant is online per offerId (presence events).
class _OtherOnlineNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => {};
  void setOnline(String offerId, bool value) {
    state = {...state, offerId: value};
  }
}

final chatOtherOnlineProvider =
    NotifierProvider<_OtherOnlineNotifier, Map<String, bool>>(
  _OtherOnlineNotifier.new,
);

class ChatDetailNotifier extends AsyncNotifier<List<ChatMessage>> {
  ChatDetailNotifier(this._offerId);

  final String _offerId;
  late final Dio _dio;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPhotoUrl;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _wsSub;
  bool _wsConnected = false;

  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  String? get currentUserPhotoUrl => _currentUserPhotoUrl;
  bool get wsConnected => _wsConnected;

  @override
  Future<List<ChatMessage>> build() async {
    _dio = Dio(BaseOptions(baseUrl: _kApiBaseUrl));
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    _currentUserId = await storage.read(key: 'user_id');

    // Fetch current user info for AppBar avatar
    try {
      final meResp = await _dio.get('/users/me');
      _currentUserName = meResp.data['full_name'] as String?;
      _currentUserPhotoUrl = meResp.data['photo_url'] as String?;
    } catch (_) {}

    // Mark messages as read when conversation opens
    _markRead();

    // Connect WebSocket for real-time updates
    _connectWebSocket();

    // Dispose WS on provider disposal
    ref.onDispose(() {
      _wsSub?.cancel();
      _channel?.sink.close();
    });

    return _fetchMessages(_offerId);
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<List<ChatMessage>> _fetchMessages(String offerId) async {
    final resp = await _dio.get('/offers/$offerId/chat');
    final List<dynamic> data = resp.data is List ? resp.data as List : [];
    return data.map(_mapMessage).toList();
  }

  ChatMessage _mapMessage(dynamic item) {
    final map = item as Map<String, dynamic>;
    return ChatMessage(
      id: (map['id'] ?? '').toString(),
      senderId: (map['sender_id'] ?? '').toString(),
      message: map['message'] as String? ?? '',
      timestamp:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
      messageType: map['message_type'] as String? ?? 'text',
      metadata: map['metadata'] as Map<String, dynamic>?,
      isRead: map['is_read'] as bool? ?? false,
    );
  }

  // ── WebSocket ─────────────────────────────────────────────────────────────

  void _connectWebSocket() {
    try {
      final userId = _currentUserId ?? '0';
      _channel = WebSocketChannel.connect(
        Uri.parse('$_kWsBaseUrl/chat/ws/$_offerId?user_id=$userId'),
      );
      _wsConnected = true;
      try { ref.read(chatWsConnectedProvider.notifier).setConnected(_offerId, true); } catch (_) {}
      _wsSub = _channel!.stream.listen(
        _onWsMessage,
        onError: (_) {
          _wsConnected = false;
          try { ref.read(chatWsConnectedProvider.notifier).setConnected(_offerId, false); } catch (_) {}
          _scheduleReconnect();
        },
        onDone: () {
          _wsConnected = false;
          try { ref.read(chatWsConnectedProvider.notifier).setConnected(_offerId, false); } catch (_) {}
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (_) {
      // WebSocket not available (dev env without backend) — REST polling works
    }
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 3), () {
      if (state is AsyncData) _connectWebSocket();
    });
  }

  void _onWsMessage(dynamic raw) {
    try {
      final frame = json.decode(raw as String) as Map<String, dynamic>;
      final event = frame['event'] as String?;

      if (event == 'message') {
        final newMsg = _mapMessage(frame['data']);
        final current = state.asData?.value ?? [];
        // Deduplicate: ignore if already in list
        if (current.any((m) => m.id == newMsg.id)) return;
        state = AsyncData([...current, newMsg]);
        // Auto-mark read if the message is from the other user
        if (newMsg.senderId != _currentUserId) _markRead();
      } else if (event == 'presence') {
        final data = frame['data'] as Map<String, dynamic>? ?? {};
        final isOnline = data['online'] as bool? ?? false;
        try {
          ref.read(chatOtherOnlineProvider.notifier).setOnline(_offerId, isOnline);
        } catch (_) {}
      } else if (event == 'read') {
        // Update is_read for our optimistic messages
        final current = state.asData?.value ?? [];
        state = AsyncData(
          current.map((m) => m.isOptimistic
              ? ChatMessage(
                  id: m.id,
                  senderId: m.senderId,
                  message: m.message,
                  timestamp: m.timestamp,
                  messageType: m.messageType,
                  metadata: m.metadata,
                  isRead: true,
                  isOptimistic: false,
                )
              : m).toList(),
        );
      }
    } catch (_) {
      // Malformed frame — ignore
    }
  }

  // ── Mark read ─────────────────────────────────────────────────────────────

  Future<void> _markRead() async {
    try {
      await _dio.patch('/chat/$_offerId/read');
    } catch (_) {
      // Best-effort
    }
  }

  // ── Send text message ─────────────────────────────────────────────────────

  /// Sends a plain text message with optimistic UI update.
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

  // ── Send action message ───────────────────────────────────────────────────

  /// Sends a structured action message (offer proposal, visit request, etc.).
  Future<void> sendAction({
    required String actionType,
    required Map<String, dynamic> metadata,
  }) async {
    final prev = state.asData?.value ?? [];
    final optimistic = ChatMessage(
      id: 'temp_action_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUserId ?? '',
      message: '[ACTION:$actionType]',
      timestamp: DateTime.now(),
      messageType: 'action',
      metadata: {'action_type': actionType, ...metadata},
      isOptimistic: true,
    );
    state = AsyncData([...prev, optimistic]);
    try {
      await _dio.post(
        '/chat/$_offerId/action',
        data: {'action_type': actionType, 'metadata': metadata},
      );
      state = AsyncData(await _fetchMessages(_offerId));
    } catch (e) {
      state = AsyncData(prev);
      rethrow;
    }
  }
}
