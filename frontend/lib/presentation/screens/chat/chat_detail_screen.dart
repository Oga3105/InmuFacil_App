import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/temp_translations.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.offerId});

  final String offerId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Animates to offset 0, which is the bottom in a reverse ListView.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels != 0) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      await ref
          .read(chatDetailProvider(widget.offerId).notifier)
          .sendMessage(text);
      _scrollToBottom();
    } catch (_) {
      // Optimistic update already reverted by notifier on error.
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatDetailProvider(widget.offerId));
    final notifier = ref.read(chatDetailProvider(widget.offerId).notifier);

    // Auto-scroll when new messages are appended.
    ref.listen<AsyncValue<List<ChatMessage>>>(
      chatDetailProvider(widget.offerId),
      (prev, next) {
        final prevCount = prev?.asData?.value.length ?? 0;
        final nextCount = next.asData?.value.length ?? 0;
        if (nextCount > prevCount) _scrollToBottom();
      },
    );

    // Resolve conversation context from list cache.
    final convs = ref.watch(chatListProvider).asData?.value;
    ChatConversation? conv;
    if (convs != null) {
      try {
        conv = convs.firstWhere((c) => c.offerId == widget.offerId);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(context, conv),
      body: Column(
        children: [
          // Property context banner
          if (conv != null && conv.propertyTitle.isNotEmpty)
            _PropertyBanner(
              conversation: conv,
              onTap: () => context.push('/property/${conv!.propertyId}'),
            ),

          // Messages
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'chat.error_loading'.tr(),
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(chatDetailProvider(widget.offerId)),
                      child: Text('chat.retry'.tr()),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'chat.start_conversation'.tr(),
                      style: const TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                  );
                }
                final flatItems = _buildFlatList(messages);
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: flatItems.length,
                  itemBuilder: (context, index) {
                    // Reversed: index 0 = last item in flatItems.
                    final item = flatItems[flatItems.length - 1 - index];
                    if (item is DateTime) {
                      return _DateSeparator(date: item);
                    }
                    final msg = item as ChatMessage;
                    return _MessageBubble(
                      message: msg,
                      isMine: msg.senderId == notifier.currentUserId,
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          _InputBar(
            controller: _controller,
            sending: _sending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ChatConversation? conv) {
    final initial = (conv?.otherUserName.isNotEmpty ?? false)
        ? conv!.otherUserName[0].toUpperCase()
        : '?';

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          // ── LEFT: back button + brand logo ──────────────────────────────
          AppBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 2),
          // InmuFácil wordmark
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Inmu',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: 'Fácil',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── RIGHT: peer avatar + name + online + view property ───────────
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2563EB),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                conv?.otherUserName ?? 'Chat',
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'chat.online'.tr(),
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (conv != null && conv.propertyId.isNotEmpty) ...[
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: () =>
                  context.push('/property/${conv!.propertyId}'),
              icon: const Icon(
                Icons.home_outlined,
                size: 16,
                color: Color(0xFF2563EB),
              ),
              label: Text(
                'chat.view_property'.tr(),
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE2E8F0), height: 1),
      ),
    );
  }

  /// Returns a flat list interleaving [DateTime] separators and [ChatMessage]
  /// items, grouped by calendar day.
  List<Object> _buildFlatList(List<ChatMessage> messages) {
    final result = <Object>[];
    DateTime? lastDay;
    for (final msg in messages) {
      final day =
          DateTime(msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);
      if (lastDay == null || day != lastDay) {
        result.add(msg.timestamp); // DateTime acts as separator marker
        lastDay = day;
      }
      result.add(msg);
    }
    return result;
  }
}

// ─── Property banner ──────────────────────────────────────────────────────────

class _PropertyBanner extends StatelessWidget {
  const _PropertyBanner({
    required this.conversation,
    required this.onTap,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.propertyTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'chat.active_offer'.tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Date separator ───────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: Color(0xFFCBD5E1), height: 1),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              _label(),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Divider(color: Color(0xFFCBD5E1), height: 1),
          ),
        ],
      ),
    );
  }

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'chat.today'.tr();
    if (d == today.subtract(const Duration(days: 1))) {
      return 'chat.yesterday'.tr();
    }
    final diffDays = today.difference(d).inDays;
    if (diffDays < 7) {
      const days = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
      return days[date.weekday - 1];
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            const CircleAvatar(
              radius: 12,
              backgroundColor: Color(0xFFE2E8F0),
              child: Icon(Icons.person, size: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.68,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? const Color(0xFF2563EB)
                    : Colors.white,
                borderRadius: isMine
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMine
                          ? Colors.white
                          : const Color(0xFF1E293B),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMine
                              ? Colors.white.withOpacity(0.65)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        _StatusTick(isOptimistic: message.isOptimistic),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Status tick ──────────────────────────────────────────────────────────────

class _StatusTick extends StatelessWidget {
  const _StatusTick({required this.isOptimistic});

  final bool isOptimistic;

  @override
  Widget build(BuildContext context) {
    if (isOptimistic) {
      // Single grey tick: message is being sent.
      return Icon(Icons.check, size: 12, color: Colors.white.withOpacity(0.5));
    }
    // Double tick: message delivered.
    return Icon(Icons.done_all, size: 12, color: Colors.white.withOpacity(0.9));
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attach / add button
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFF2563EB),
              size: 26,
            ),
          ),

          // Text input
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'chat.message_hint'.tr(),
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              minLines: 1,
              maxLines: 5,
            ),
          ),
          const SizedBox(width: 4),

          // Send / loading indicator
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  )
                : IconButton(
                    key: const ValueKey('send'),
                    onPressed: onSend,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
