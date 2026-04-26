import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/env_config.dart';
import '../../core/network/dio_factory.dart';

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
  late Dio _dio;

  @override
  Future<List<ChatConversation>> build() async {
    _dio = buildAuthDio();
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return [];
    _dio.options.headers['Authorization'] = 'Bearer $token';
    return _fetchConversations();
  }

  Future<List<ChatConversation>> _fetchConversations() async {
    try {
      // Fetch user ID safely — failure is non-blocking
      String currentUserId = '';
      try {
        final meResp = await _dio.get('/users/me');
        currentUserId = (meResp.data['id'] ?? '').toString();
      } catch (_) {}

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
        try {
          final map = offer as Map<String, dynamic>;

          final id = (map['id'] ?? '').toString();
          if (seen.contains(id)) continue;
          seen.add(id);

          String lastMsg = map['last_message'] as String? ?? '';
          // Sanitize technical/error placeholders from the backend
          // (e.g. '[Error Decrypting]', '[offer_proposal]', '[ACTION:...]')
          if (lastMsg.startsWith('[') && lastMsg.endsWith(']')) lastMsg = '';
          final unread = (map['unread_count'] as int?) ?? 0;
          final chatEnabled = map['is_chat_enabled'] as bool? ?? false;

          // Date from backend serializer (= last message time after backend restart)
          DateTime? lastDate =
              DateTime.tryParse(map['updated_at'] as String? ?? '')?.toLocal();

          // Fast path: backend already tells us there are messages.
          // Slow path: backend hasn't been restarted yet so last_message is empty
          // even though chat was enabled. Fetch messages directly to check.
          if (lastMsg.isEmpty && unread == 0) {
            if (!chatEnabled) continue; // Definitely no messages — skip.

            // chatEnabled but backend didn't compute last_message yet.
            // Call the messages endpoint to get the real state.
            try {
              final resp = await _dio.get('/offers/$id/chat');
              final msgs = resp.data is List ? resp.data as List : [];
              if (msgs.isEmpty) continue; // No messages — skip.

              // Use last message for display
              final last = msgs.last as Map<String, dynamic>;
              lastMsg = last['message'] as String? ?? '...';
              // Sanitize technical/error strings from the backend
              if (lastMsg.startsWith('[') && lastMsg.endsWith(']')) lastMsg = '...';
              lastDate = DateTime.tryParse(
                    (last['created_at'] ?? last['timestamp'])?.toString() ?? '',
                  )?.toLocal();
            } catch (_) {
              continue; // Can't load messages — skip.
            }
          }

          // Fallback date: offer creation time, never DateTime.now()
          lastDate ??=
              DateTime.tryParse(map['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.fromMillisecondsSinceEpoch(0);

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
            otherName =
                sellerName.trim().isEmpty ? 'Vendedor' : sellerName.trim();
            otherPhotoUrl = property['seller_photo_url'] as String?;
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
            lastMessage: lastMsg.isNotEmpty
                ? lastMsg
                : (unread > 0 ? '$unread mensaje(s) nuevo(s)' : '...'),
            lastDate: lastDate,
            unreadCount: unread,
          ));
        } catch (_) {
          // Skip malformed entries — do not crash the full list.
        }
      }

      conversations.sort((a, b) => b.lastDate.compareTo(a.lastDate));
      return conversations;
    } catch (_) {
      rethrow;
    }
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
  String? _otherUserName;
  String? _otherUserPhotoUrl;
  int? _otherUserId;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _wsSub;
  bool _wsConnected = false;
  bool _isBuyer = false;
  String? _offerStatus;

  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  String? get currentUserPhotoUrl => _currentUserPhotoUrl;
  String? get otherUserName => _otherUserName;
  String? get otherUserPhotoUrl => _otherUserPhotoUrl;
  int? get otherUserId => _otherUserId;
  bool get wsConnected => _wsConnected;
  bool get isBuyer => _isBuyer;
  String? get offerStatus => _offerStatus;

  @override
  Future<List<ChatMessage>> build() async {
    _dio = buildAuthDio();
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }

    // PRIMARY: fetch current user from API (storage may not store user_id after login)
    try {
      final meResp = await _dio.get('/users/me');
      _currentUserId = (meResp.data['id'] ?? '').toString();
      _currentUserName = meResp.data['full_name'] as String?;
      _currentUserPhotoUrl = meResp.data['photo_url'] as String?;
    } catch (_) {
      // Fallback to storage
      _currentUserId = await storage.read(key: 'user_id');
    }

    // Determine role and other-user info from sent/received offer lists
    try {
      final results = await Future.wait([
        _dio.get('/offers/me/sent'),
        _dio.get('/offers/me/received'),
      ]);
      final sent = results[0].data is List ? results[0].data as List : [];
      final received = results[1].data is List ? results[1].data as List : [];

      final sentOffer = sent.cast<Map<String, dynamic>?>().firstWhere(
          (o) => (o?['id'] ?? '').toString() == _offerId,
          orElse: () => null);
      if (sentOffer != null) {
        _isBuyer = true;
        _offerStatus = sentOffer['status'] as String?;
        final property = sentOffer['property'] as Map<String, dynamic>? ?? {};
        _otherUserName = (property['seller_name'] as String?)?.trim();
        if (_otherUserName == null || _otherUserName!.isEmpty)
          _otherUserName = 'Vendedor';
        _otherUserPhotoUrl = property['seller_photo_url'] as String?;
        final ownerIdRaw = property['owner_id'] ?? sentOffer['property_owner_id'];
        if (ownerIdRaw != null) _otherUserId = int.tryParse(ownerIdRaw.toString());
      } else {
        final receivedOffer = received.cast<Map<String, dynamic>?>().firstWhere(
            (o) => (o?['id'] ?? '').toString() == _offerId,
            orElse: () => null);
        if (receivedOffer != null) {
          _isBuyer = false;
          _offerStatus = receivedOffer['status'] as String?;
          final buyer = receivedOffer['buyer'] as Map<String, dynamic>? ?? {};
          _otherUserName = (buyer['full_name'] as String?)?.trim();
          if (_otherUserName == null || _otherUserName!.isEmpty)
            _otherUserName = 'Comprador';
          _otherUserPhotoUrl = buyer['photo_url'] as String?;
          final buyerIdRaw = buyer['id'] ?? receivedOffer['buyer_id'];
          if (buyerIdRaw != null) _otherUserId = int.tryParse(buyerIdRaw.toString());
        }
      }
    } catch (_) {}

    // Ensure this chat is visible in the inbox
    try {
      await _dio.post('/offers/$_offerId/chat/enable');
      ref.invalidate(chatListProvider);
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
      timestamp: DateTime.tryParse(
            (map['created_at'] ?? map['timestamp'])?.toString() ?? '',
          )?.toLocal() ??
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
        Uri.parse('${EnvConfig.apiBaseUrl.replaceFirst('https', 'wss').replaceFirst('http', 'ws')}/chat/ws/$_offerId?user_id=$userId'),
      );
      _wsConnected = true;
      try {
        ref.read(chatWsConnectedProvider.notifier).setConnected(_offerId, true);
      } catch (_) {}
      _wsSub = _channel!.stream.listen(
        _onWsMessage,
        onError: (_) {
          _wsConnected = false;
          try {
            ref
                .read(chatWsConnectedProvider.notifier)
                .setConnected(_offerId, false);
          } catch (_) {}
          _scheduleReconnect();
        },
        onDone: () {
          _wsConnected = false;
          try {
            ref
                .read(chatWsConnectedProvider.notifier)
                .setConnected(_offerId, false);
          } catch (_) {}
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
          ref
              .read(chatOtherOnlineProvider.notifier)
              .setOnline(_offerId, isOnline);
        } catch (_) {}
      } else if (event == 'read') {
        // Update is_read for our optimistic messages
        final current = state.asData?.value ?? [];
        state = AsyncData(
          current
              .map((m) => m.isOptimistic
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
                  : m)
              .toList(),
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
