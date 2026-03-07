import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/currency_input_formatter.dart';
import '../../../core/utils/temp_translations.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kNavy      = Color(0xFF1E3A5F);
const _kNavyLight = Color(0xFFEEF3FA);
const _kGold      = Color(0xFFB8860B);
const _kGoldLight = Color(0xFFFFF8E1);

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

  // ── Send text ─────────────────────────────────────────────────────────────

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar el mensaje. Intentalo de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Send action ───────────────────────────────────────────────────────────

  Future<void> _sendVisitRequest() async {
    final result = await _showDateTimePickerDialog();
    if (result == null || !mounted) return;

    await ref
        .read(chatDetailProvider(widget.offerId).notifier)
        .sendAction(
          actionType: 'visit_request',
          metadata: {'date': result},
        );
    _scrollToBottom();
  }

  Future<void> _sendOfferProposal() async {
    final amount = await _showAmountDialog();
    if (amount == null || !mounted) return;

    await ref
        .read(chatDetailProvider(widget.offerId).notifier)
        .sendAction(
          actionType: 'offer_proposal',
          metadata: {'amount': amount},
        );
    _scrollToBottom();
  }

  Future<void> _requestDocuments() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Solicitar',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF2563EB),
                ),
              ),
              TextSpan(
                text: ' documentos',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
        content: const Text(
          'Se enviara una solicitud de documentacion al otro participante.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref
        .read(chatDetailProvider(widget.offerId).notifier)
        .sendAction(
          actionType: 'docs_request',
          metadata: {},
        );
    _scrollToBottom();
  }

  Future<String?> _showDateTimePickerDialog() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kNavy),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 11, minute: 0),
      helpText: 'Hora preferente de visita',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kNavy),
        ),
        child: child!,
      ),
    );
    if (!mounted) return null;

    final hour = pickedTime?.hour ?? 11;
    final minute = pickedTime?.minute ?? 0;
    return '${picked.day}/${picked.month}/${picked.year} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<int?> _showAmountDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Propuesta de ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF2563EB),
                ),
              ),
              TextSpan(
                text: 'oferta',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              hintText: '0',
              suffixText: '\u20AC',
              suffixStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF1E293B),
              ),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Introduce un importe';
              final parsed = CurrencyInputFormatter.parse(v);
              if (parsed == null || parsed <= 0) return 'Importe no valido';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  ctx,
                  CurrencyInputFormatter.parse(controller.text) ?? 0,
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatDetailProvider(widget.offerId));
    final notifier = ref.read(chatDetailProvider(widget.offerId).notifier);

    ref.listen<AsyncValue<List<ChatMessage>>>(
      chatDetailProvider(widget.offerId),
      (prev, next) {
        final prevCount = prev?.asData?.value.length ?? 0;
        final nextCount = next.asData?.value.length ?? 0;
        if (nextCount > prevCount) _scrollToBottom();
      },
    );

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
          if (conv != null && conv.propertyTitle.isNotEmpty)
            _PropertyBanner(
              conversation: conv,
              onTap: () => context.push('/property/${conv!.propertyId}'),
            ),
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: _kNavy)),
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
                    final item = flatItems[flatItems.length - 1 - index];
                    if (item is DateTime) {
                      return _DateSeparator(date: item);
                    }
                    final msg = item as ChatMessage;
                    final isMine = msg.senderId == notifier.currentUserId;
                    if (msg.isAction) {
                      return _ActionCard(
                        message: msg,
                        isMine: isMine,
                        offerId: widget.offerId,
                      );
                    }
                    return _MessageBubble(message: msg, isMine: isMine);
                  },
                );
              },
            ),
          ),
          // End-to-end note
          const _EncryptionNote(),
          // Quick action bar
          _QuickActionBar(
            onVisit: _sendVisitRequest,
            onOffer: _sendOfferProposal,
            onDocs: _requestDocuments,
            hasExistingOfferProposal: messagesAsync.asData?.value
                .any((m) => m.isAction &&
                    m.metadata?['action_type'] == 'offer_proposal') ??
                false,
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
    final otherOnline = ref.watch(
        chatOtherOnlineProvider.select((map) => map[widget.offerId] ?? false));
    final notifier = ref.read(chatDetailProvider(widget.offerId).notifier);
    final otherInitial = (conv?.otherUserName.isNotEmpty ?? false)
        ? conv!.otherUserName[0].toUpperCase()
        : '?';
    final myInitial = (notifier.currentUserName?.isNotEmpty ?? false)
        ? notifier.currentUserName![0].toUpperCase()
        : '?';

    return AppBar(
      backgroundColor: _kNavy,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          // Back
          AppBarBackButton(onPressed: () => Navigator.of(context).pop()),
          // Logo + InmuFácil text
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Image.asset(
              'assets/images/logo_inmufacil.png',
              height: 22,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const Text(
            'InmuFácil',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          // Vertical divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            height: 26,
            width: 1,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          // Other user avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: (conv?.otherUserPhotoUrl?.isNotEmpty ?? false)
                ? NetworkImage(conv!.otherUserPhotoUrl!)
                : null,
            child: (conv?.otherUserPhotoUrl?.isNotEmpty ?? false)
                ? null
                : Text(
                    otherInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
          ),
          const SizedBox(width: 7),
          // Other user name + presence
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  conv?.otherUserName ?? 'Chat',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: otherOnline
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      otherOnline ? 'En linea' : 'Desconectado',
                      style: const TextStyle(
                        color: Color(0xFFB0C4DE),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Inicio button — official blue
          TextButton(
            onPressed: () => context.go('/'),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Inicio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Current user avatar
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage:
                (notifier.currentUserPhotoUrl?.isNotEmpty ?? false)
                    ? NetworkImage(notifier.currentUserPhotoUrl!)
                    : null,
            child: (notifier.currentUserPhotoUrl?.isNotEmpty ?? false)
                ? null
                : Text(
                    myInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  List<Object> _buildFlatList(List<ChatMessage> messages) {
    final result = <Object>[];
    DateTime? lastDay;
    for (final msg in messages) {
      final day =
          DateTime(msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);
      if (lastDay == null || day != lastDay) {
        result.add(msg.timestamp);
        lastDay = day;
      }
      result.add(msg);
    }
    return result;
  }
}

// ── Property banner ───────────────────────────────────────────────────────────

class _PropertyBanner extends StatelessWidget {
  const _PropertyBanner({required this.conversation, required this.onTap});

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
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kNavyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.home_outlined, color: _kNavy, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REFERENCIA: ${conversation.propertyTitle.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'chat.active_offer'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Date separator ────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFCBD5E1), height: 1)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
          const Expanded(child: Divider(color: Color(0xFFCBD5E1), height: 1)),
        ],
      ),
    );
  }

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'HOY';
    if (d == today.subtract(const Duration(days: 1))) return 'AYER';
    final diffDays = today.difference(d).inDays;
    if (diffDays < 7) {
      const days = ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB', 'DOM'];
      return days[date.weekday - 1];
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

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
                color: isMine ? _kNavy : Colors.white,
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
                    color: Colors.black.withValues(alpha: 0.06),
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
                      color: isMine ? Colors.white : const Color(0xFF1E293B),
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
                              ? Colors.white.withValues(alpha: 0.65)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        _StatusTick(
                          isOptimistic: message.isOptimistic,
                          isRead: message.isRead,
                        ),
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

// ── Status tick ───────────────────────────────────────────────────────────────

class _StatusTick extends StatelessWidget {
  const _StatusTick({required this.isOptimistic, required this.isRead});

  final bool isOptimistic;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    if (isOptimistic) {
      return Icon(Icons.check, size: 12, color: Colors.white.withValues(alpha: 0.5));
    }
    return Icon(
      Icons.done_all,
      size: 12,
      color: isRead
          ? const Color(0xFFFFD700)  // Gold double-tick = read
          : Colors.white.withValues(alpha: 0.7),
    );
  }
}

// ── Action card ───────────────────────────────────────────────────────────────

class _ActionCard extends ConsumerStatefulWidget {
  const _ActionCard({
    required this.message,
    required this.isMine,
    required this.offerId,
  });

  final ChatMessage message;
  final bool isMine;
  final String offerId;

  @override
  ConsumerState<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends ConsumerState<_ActionCard> {
  bool _loading = false;

  String get _actionType =>
      widget.message.metadata?['action_type'] as String? ?? '';

  (IconData, String, Color, Color) get _config => switch (_actionType) {
        'visit_request' => (
            Icons.calendar_month_outlined,
            'Solicitud de Visita',
            _kNavy,
            _kNavyLight,
          ),
        'offer_proposal' => (
            Icons.monetization_on_outlined,
            'Propuesta de Oferta',
            _kGold,
            _kGoldLight,
          ),
        'docs_request' => (
            Icons.folder_outlined,
            'Solicitud de Documentos',
            const Color(0xFF7C3AED),
            const Color(0xFFF5F3FF),
          ),
        _ => (
            Icons.info_outline,
            'Accion',
            _kNavy,
            _kNavyLight,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, label, color, bg) = _config;
    final meta = widget.message.metadata ?? {};
    final amount = meta['amount'] != null
        ? '\u20AC${(meta['amount'] as num).toStringAsFixed(0)}'
        : null;
    final date = meta['date'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: widget.isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: color,
                        ),
                      ),
                      const Spacer(),
                      // Shield badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 9, color: Color(0xFF16A34A)),
                            SizedBox(width: 3),
                            Text(
                              'AES-256',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Details
                  if (amount != null || date != null) ...[
                    const SizedBox(height: 10),
                    if (amount != null)
                      Text(
                        amount,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    if (date != null)
                      Row(
                        children: [
                          Icon(Icons.event_outlined, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                  ],
                  // Action buttons (only shown to receiver)
                  if (!widget.isMine) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(
                                  color: Colors.red.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: _loading ? null : () {},
                            child: const Text(
                              'Rechazar',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: color,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: _loading ? null : () {},
                            child: _loading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Aceptar',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Timestamp
                  const SizedBox(height: 6),
                  Text(
                    '${widget.message.timestamp.hour.toString().padLeft(2, '0')}:'
                    '${widget.message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick action bar ──────────────────────────────────────────────────────────

class _QuickActionBar extends StatelessWidget {
  const _QuickActionBar({
    required this.onVisit,
    required this.onOffer,
    required this.onDocs,
    required this.hasExistingOfferProposal,
  });

  final VoidCallback onVisit;
  final VoidCallback onOffer;
  final VoidCallback onDocs;
  final bool hasExistingOfferProposal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _QuickActionButton(
            icon: Icons.calendar_month_outlined,
            label: 'Visita',
            color: _kNavy,
            onTap: onVisit,
          ),
          const SizedBox(width: 8),
          if (!hasExistingOfferProposal)
            _QuickActionButton(
              icon: Icons.monetization_on_outlined,
              label: 'Oferta',
              color: _kGold,
              onTap: onOffer,
            ),
          if (!hasExistingOfferProposal) const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.folder_outlined,
            label: 'Documentos',
            color: const Color(0xFF7C3AED),
            onTap: onDocs,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Encryption note ───────────────────────────────────────────────────────────

class _EncryptionNote extends StatelessWidget {
  const _EncryptionNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 11, color: Color(0xFF94A3B8)),
          SizedBox(width: 4),
          Text(
            'Tus mensajes estan protegidos por cifrado de extremo a extremo.',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

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
                        color: _kNavy,
                      ),
                    ),
                  )
                : Material(
                    key: const ValueKey('send'),
                    color: _kNavy,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: onSend,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
