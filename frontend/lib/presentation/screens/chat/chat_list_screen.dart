import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_localization/easy_localization.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

// ── Palette (Navy Blue & Gold) ────────────────────────────────────────────────
const _kNavy      = Color(0xFF1E3A5F);
const _kNavyLight = Color(0xFFEEF3FA);
const _kGold      = Color(0xFFB8860B);
const _kGoldLight = Color(0xFFFFF8E1);
const _kSilver    = Color(0xFF607D8B);
const _kBronze    = Color(0xFF8D6E63);

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key, this.embeddedInProfile = false});

  /// When true the widget renders without a Scaffold (for embedding in tabs).
  final bool embeddedInProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatAsync = ref.watch(chatListProvider);

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        return isWide
            ? _WideLayout(chatAsync: chatAsync, ref: ref)
            : _NarrowLayout(chatAsync: chatAsync, ref: ref);
      },
    );

    if (embeddedInProfile) return body;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: body,
    );
  }
}

// ── Wide layout (desktop two-pane) ────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.chatAsync, required this.ref});

  final AsyncValue<List<ChatConversation>> chatAsync;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 380,
          child: _InboxPane(chatAsync: chatAsync, ref: ref),
        ),
        const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
        const Expanded(child: _EmptyDetailPane()),
      ],
    );
  }
}

// ── Narrow layout (mobile full-screen list) ───────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.chatAsync, required this.ref});

  final AsyncValue<List<ChatConversation>> chatAsync;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        title: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_inmufacil.png', height: 28),
                const SizedBox(width: 8),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF2563EB))),
                      TextSpan(text: 'Fácil', style: TextStyle(color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 650)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text('Inicio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const UserAvatarMenu(),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
      ),
      body: _InboxPane(chatAsync: chatAsync, ref: ref),
    );
  }
}

// ── Inbox pane ────────────────────────────────────────────────────────────────

class _InboxPane extends StatelessWidget {
  const _InboxPane({required this.chatAsync, required this.ref});

  final AsyncValue<List<ChatConversation>> chatAsync;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header (web pane only)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mensajes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _kNavy,
                ),
              ),
              const SizedBox(height: 12),
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar conversaciones...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // List
        Expanded(
          child: chatAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: _kNavy)),
            error: (err, _) => _ErrorState(
              onRetry: () => ref.read(chatListProvider.notifier).refresh(),
            ),
            data: (conversations) {
              if (conversations.isEmpty) return const _EmptyListState();
              return RefreshIndicator(
                color: _kNavy,
                onRefresh: () => ref.read(chatListProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    return _ConversationTile(
                      conversation: conv,
                      onTap: () => context.push('/chat/${conv.offerId}'),
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Bottom security badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 13, color: Color(0xFF16A34A)),
              SizedBox(width: 6),
              Text(
                'CHAT ENCRIPTADO END-TO-END',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Conversation tile ─────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        splashColor: _kNavy.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with online dot
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _kNavy,
                    backgroundImage:
                        (conversation.otherUserPhotoUrl?.isNotEmpty ?? false)
                            ? NetworkImage(conversation.otherUserPhotoUrl!)
                            : null,
                    child:
                        (conversation.otherUserPhotoUrl?.isNotEmpty ?? false)
                            ? null
                            : const Icon(Icons.person_rounded, size: 28, color: Colors.white),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + trust badge
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      conversation.otherUserName,
                                      style: TextStyle(
                                        fontWeight: hasUnread
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        fontSize: 14,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (conversation.trustBadge !=
                                      TrustBadge.none) ...[
                                    const SizedBox(width: 6),
                                    _TrustBadgeChip(
                                        badge: conversation.trustBadge),
                                  ],
                                ],
                              ),
                              // Property title
                              Text(
                                conversation.propertyTitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Time + unread badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDate(conversation.lastDate),
                              style: TextStyle(
                                fontSize: 11,
                                color: hasUnread
                                    ? _kNavy
                                    : const Color(0xFF94A3B8),
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            if (hasUnread) ...[
                              const SizedBox(height: 4),
                              _UnreadBadge(count: conversation.unreadCount),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (conversation.lastMessage.isNotEmpty)
                      Text(
                        conversation.lastMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: hasUnread
                              ? const Color(0xFF334155)
                              : const Color(0xFF94A3B8),
                          fontWeight: hasUnread
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'AYER';
    } else if (diff.inDays < 7) {
      const days = ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB', 'DOM'];
      return days[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

// ── Trust badge chip ──────────────────────────────────────────────────────────

class _TrustBadgeChip extends StatelessWidget {
  const _TrustBadgeChip({required this.badge});

  final TrustBadge badge;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (badge) {
      TrustBadge.gold   => ('ORO', _kGold, _kGoldLight),
      TrustBadge.silver => ('PLATA', _kSilver, const Color(0xFFECEFF1)),
      TrustBadge.bronze => ('BRONCE', _kBronze, const Color(0xFFFBEFEB)),
      TrustBadge.none   => ('', Colors.transparent, Colors.transparent),
    };
    if (badge == TrustBadge.none) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 9, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Unread badge ──────────────────────────────────────────────────────────────

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: _kNavy,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Empty list state (no chat-enabled conversations yet) ──────────────────────

class _EmptyListState extends StatelessWidget {
  const _EmptyListState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _kNavyLight,
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: _kNavy,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin conversaciones activas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando el vendedor active el chat en una oferta, aparecera aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty detail pane (right side on wide layout) ────────────────────────────

class _EmptyDetailPane extends StatelessWidget {
  const _EmptyDetailPane();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _kNavyLight,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 32,
                  color: _kNavy,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tus Conversaciones Seguras',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Selecciona un chat para ver los mensajes. Todas las comunicaciones en InmuFacil estan protegidas por encriptacion avanzada para tu seguridad.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FeatureChip(
                    icon: Icons.shield_outlined,
                    label: 'PROTECCION P2P',
                    color: _kNavy,
                  ),
                  _FeatureChip(
                    icon: Icons.gavel_outlined,
                    label: 'VALIDEZ LEGAL',
                    color: _kNavy,
                  ),
                  _FeatureChip(
                    icon: Icons.verified_user_outlined,
                    label: 'KYC VERIFICADO',
                    color: _kNavy,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(
            'chat.error_loading'.tr(),
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text('chat.retry'.tr()),
          ),
        ],
      ),
    );
  }
}
