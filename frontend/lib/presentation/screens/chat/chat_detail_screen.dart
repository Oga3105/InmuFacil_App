import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/currency_input_formatter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/offers_provider.dart';
import '../../providers/solvency_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/report_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../../widgets/visits/visit_cancel_dialog.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kNavy      = Color(0xFF135BEC);
const _kGold      = Color(0xFFB8860B);

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
          SnackBar(content: Text('chat.send_error'.tr())),
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

  Future<String?> _showDateTimePickerDialog() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      locale: Localizations.localeOf(context),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kNavy),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return null;

    // Native analog clock time picker with 24H / AM-PM toggle overlaid
    final use24hNotifier = ValueNotifier<bool>(true);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 11, minute: 0),
      helpText: 'chat.visit_time_help'.tr(),
      builder: (ctx, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: use24hNotifier,
          builder: (ctx2, use24h, _) {
            final size = MediaQuery.of(ctx).size;
            // Material 3 dial-mode dialog is ~328×528 px, centered on screen.
            // The toggle sits to the right of the keyboard-mode icon (bottom-left).
            const dw = 328.0;
            const dh = 528.0;
            final toggleLeft = ((size.width - dw) / 2 + 64).clamp(8.0, size.width - 140);
            final toggleBottom = ((size.height - dh) / 2 + 10).clamp(8.0, size.height - 60);
            return MediaQuery(
              data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: use24h),
              child: Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(primary: _kNavy),
                ),
                child: Stack(
                  children: [
                    child!,
                    Positioned(
                      left: toggleLeft,
                      bottom: toggleBottom,
                      child: Material(
                        color: Colors.transparent,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _FormatBtn(
                              label: '24H',
                              active: use24h,
                              onTap: () => use24hNotifier.value = true,
                            ),
                            const SizedBox(width: 4),
                            _FormatBtn(
                              label: 'AM/PM',
                              active: !use24h,
                              onTap: () => use24hNotifier.value = false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    use24hNotifier.dispose();
    if (pickedTime == null || !mounted) return null;

    final hour = pickedTime.hour;
    final minute = pickedTime.minute;
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
          text: TextSpan(
            children: [
              TextSpan(
                text: 'chat.offer_proposal_title'.tr() + ' ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF135BEC),
                ),
              ),
              TextSpan(
                text: '',
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
              if (v == null || v.isEmpty) return 'chat.error_amount_required'.tr();
              final parsed = CurrencyInputFormatter.parse(v);
              if (parsed == null || parsed <= 0) return 'chat.error_amount_invalid'.tr();
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
            child: Text('common.cancel'.tr()),
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
            child: Text('chat.send_button'.tr()),
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

    // Compute visit status: none | pending | accepted | cancelled
    final _msgs = messagesAsync.asData?.value ?? [];
    String visitStatus = 'none';
    for (final m in _msgs) {
      if (!m.isAction) continue;
      final t = m.metadata?['action_type'] as String?;
      if (t == 'visit_request') visitStatus = 'pending';
      else if (t == 'visit_accepted') visitStatus = 'accepted';
      else if (t == 'visit_rejected') visitStatus = 'none';
      else if (t == 'visit_cancelled') visitStatus = 'none';
    }

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context, conv),
      body: Column(
        children: [
          if (conv != null && conv.propertyTitle.isNotEmpty)
            _PropertyBanner(
              conversation: conv,
              onTap: () => context.push('/property/${conv!.propertyId}'),
            ),
          // Only show seller solvency banner after provider loaded & user is seller
          if (messagesAsync is AsyncData && !notifier.isBuyer)
            _SellerSolvencyBanner(offerId: widget.offerId),
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
                    final isMine = notifier.currentUserId != null &&
                        msg.senderId == notifier.currentUserId;
                    final senderPhoto = isMine
                        ? notifier.currentUserPhotoUrl
                        : notifier.otherUserPhotoUrl;
                    if (msg.isAction) {
                      final actionType = msg.metadata?['action_type'] as String?;
                      final msgIdx = messages.indexOf(msg);

                      // A visit_request is answered if a later message has visit_accepted/rejected
                      bool isAnswered = false;
                      if (actionType == 'visit_request') {
                        isAnswered = messages.skip(msgIdx + 1).any((m) =>
                          m.isAction &&
                          (m.metadata?['action_type'] == 'visit_accepted' ||
                           m.metadata?['action_type'] == 'visit_rejected'));
                      }

                      // A visit_accepted card is inactive if a later visit_cancelled exists
                      bool isActive = true;
                      if (actionType == 'visit_accepted') {
                        isActive = !messages.skip(msgIdx + 1).any((m) =>
                          m.isAction &&
                          m.metadata?['action_type'] == 'visit_cancelled');
                      }

                      return _ActionCard(
                        message: msg,
                        isMine: isMine,
                        offerId: widget.offerId,
                        isAnswered: isAnswered,
                        isActive: isActive,
                        onReschedule: _sendVisitRequest,
                      );
                    }
                    return _MessageBubble(
                      message: msg,
                      isMine: isMine,
                      senderPhotoUrl: senderPhoto,
                    );
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
            isBuyer: notifier.isBuyer,
            visitStatus: visitStatus,
            hasExistingOfferProposal: ['pending', 'counter_offer', 'accepted', 'signing_pending', 'signed', 'completed']
                .contains(notifier.offerStatus?.toLowerCase() ?? ''),
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
    // Watch the async state so the AppBar rebuilds when notifier fields are populated
    ref.watch(chatDetailProvider(widget.offerId));
    final notifier = ref.read(chatDetailProvider(widget.offerId).notifier);

    // Prefer notifier data (fetched from API) over conv (may not be loaded yet)
    final otherName = notifier.otherUserName ?? conv?.otherUserName ?? '';
    final otherPhoto = notifier.otherUserPhotoUrl ?? conv?.otherUserPhotoUrl;
    final myPhoto = notifier.currentUserPhotoUrl;

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBarBackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo + brand text (matches offer_management_screen style)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_inmufacil.png',
                    height: 32,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  Builder(builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        children: [
                          TextSpan(
                            text: 'Inmu',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),
                          TextSpan(
                            text: 'Fácil',
                            style: TextStyle(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Vertical divider
          Builder(builder: (context) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            height: 28,
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          )),
          // Other user avatar
          Builder(builder: (context) => CircleAvatar(
            radius: 17,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage: (otherPhoto?.isNotEmpty ?? false)
                ? NetworkImage(otherPhoto!)
                : null,
            child: (otherPhoto?.isNotEmpty ?? false)
                ? null
                : Icon(Icons.person_rounded, size: 19, color: Theme.of(context).colorScheme.onPrimary),
          )),
          const SizedBox(width: 8),
          // Other user name + presence dot
          Flexible(
            child: Builder(builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final cs = Theme.of(context).colorScheme;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    otherName.isEmpty ? 'Chat' : otherName,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: otherOnline
                              ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                              : cs.outlineVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        otherOnline ? 'chat.online'.tr() : 'chat.offline'.tr(),
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ],
      ),
      actions: [
        if (notifier.otherUserId != null)
          ReportButton(reportedUserId: notifier.otherUserId!),
        // Inicio button — same style as offer_management_screen
        if (MediaQuery.sizeOf(context).width >= 650)
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
          onTap: () => context.go('/'),
          child: Builder(builder: (context) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_rounded, size: 18, color: Theme.of(context).colorScheme.onPrimary),
                const SizedBox(width: 6),
                Text(
                  'common.home'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )),
          ),
        ),
        const SizedBox(width: 12),
        // Current user avatar with dropdown menu
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: const UserAvatarMenu(),
        ),
      ],
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

// ── Seller's anonymised solvency banner ──────────────────────────────────────

class _SellerSolvencyBanner extends ConsumerWidget {
  const _SellerSolvencyBanner({required this.offerId});

  final String offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(buyerPassportProvider(offerId));

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (passport) {
        if (passport == null) {
          // Buyer has not submitted a passport yet
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              border: const Border(bottom: BorderSide(color: Color(0xFF93C5FD))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF1D4ED8), size: 18),
                const SizedBox(width: 10),
                Expanded(
                      child: Text(
                    'chat.solvency_not_completed'.tr(),
                    style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8)),
                  ),
                ),
              ],
            ),
          );
        }

        final level = passport.solvencyLevel ?? 'bronze';
        final (levelLabel, levelColor, levelIcon) = switch (level) {
          'gold'   => ('chat.level_gold'.tr(),    const Color(0xFFB8860B), Icons.emoji_events_rounded),
          'silver' => ('chat.level_silver'.tr(),  const Color(0xFF64748B), Icons.shield_rounded),
          _        => ('chat.level_bronze'.tr(), const Color(0xFFCD7F32), Icons.shield_outlined),
        };

        final stressLabel = switch (passport.stressIndex) {
          'low_risk'    => ('solvency.low_risk'.tr(),   const Color(0xFF16A34A)),
          'medium_risk' => ('solvency.medium_risk'.tr(),  Colors.orange),
          _             => ('solvency.high_risk'.tr(),   Colors.red),
        };

        final paymentLabel = switch (passport.paymentMethod) {
          'cash'              => 'solvency.cash'.tr(),
          'mortgage_approved' => 'solvency.mortgage_approved'.tr(),
          'mortgage_pending'  => 'solvency.mortgage_pending'.tr(),
          'house_to_sell'     => 'solvency.house_to_sell'.tr(),
          _                   => 'solvency.unspecified_payment'.tr(),
        };

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              leading: Icon(levelIcon, color: levelColor, size: 22),
              title: Row(
                children: [
                  Text(
                    'chat.qualified_candidate'.tr(namedArgs: {'level': levelLabel}),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kNavy),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: stressLabel.$2.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      stressLabel.$1,
                      style: TextStyle(color: stressLabel.$2, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'chat.tap_for_details'.tr(),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        _SolvencyChip(Icons.payments_outlined, paymentLabel),
                        const SizedBox(width: 8),
                        if (passport.hasPreApproval)
                          _SolvencyChip(Icons.check_circle_outline, 'solvency.pre_approval'.tr()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (passport.knowsExtraCosts)
                          _SolvencyChip(Icons.lightbulb_outline, 'solvency.knows_costs'.tr()),
                        const SizedBox(width: 8),
                        if (passport.hasInitialSavings)
                          _SolvencyChip(Icons.savings_outlined, 'solvency.has_savings'.tr()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('chat.solvency_draft_wip'.tr()),
                              backgroundColor: _kNavy,
                            ),
                          );
                        },
                        icon: const Icon(Icons.handshake_outlined, color: Colors.white, size: 18),
                        label: Text(
                          'chat.accept_solvency_btn'.tr(),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kNavy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SolvencyChip extends StatelessWidget {
  const _SolvencyChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.primary),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PropertyBanner extends StatelessWidget {
  const _PropertyBanner({required this.conversation, required this.onTap});

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.home_outlined, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'chat.reference'.tr(namedArgs: {'title': conversation.propertyTitle.toUpperCase()}),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'chat.active_offer'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant, size: 18),
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
          Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 1)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Text(
              _label(),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 1)),
        ],
      ),
    );
  }

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'chat.today'.tr();
    if (d == today.subtract(const Duration(days: 1))) return 'chat.yesterday_caps'.tr();
    final diffDays = today.difference(d).inDays;
    if (diffDays < 7) {
      final days = ['time.weekdays_short.mon'.tr(), 'time.weekdays_short.tue'.tr(), 'time.weekdays_short.wed'.tr(), 'time.weekdays_short.thu'.tr(), 'time.weekdays_short.fri'.tr(), 'time.weekdays_short.sat'.tr(), 'time.weekdays_short.sun'.tr()];
      return days[date.weekday - 1];
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    this.senderPhotoUrl,
  });

  final ChatMessage message;
  final bool isMine;
  final String? senderPhotoUrl;

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
            CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFF135BEC),
              backgroundImage: (senderPhotoUrl?.isNotEmpty ?? false)
                  ? NetworkImage(senderPhotoUrl!)
                  : null,
              child: (senderPhotoUrl?.isNotEmpty ?? false)
                  ? null
                  : const Icon(Icons.person_rounded, size: 16, color: Colors.white),
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
                color: isMine ? _kNavy : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                      color: isMine ? Colors.white : Theme.of(context).colorScheme.onSurface,
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
                              : Theme.of(context).colorScheme.onSurfaceVariant,
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
    this.isAnswered = false,
    this.isActive = true,
    this.onReschedule,
  });

  final ChatMessage message;
  final bool isMine;
  final String offerId;
  final bool isAnswered;
  /// For visit_accepted cards: false when a subsequent visit_cancelled exists.
  final bool isActive;
  final VoidCallback? onReschedule;

  @override
  ConsumerState<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends ConsumerState<_ActionCard> {
  bool _loading = false;

  String get _actionType =>
      widget.message.metadata?['action_type'] as String? ?? '';

  Future<void> _respond(String status) async {
    setState(() => _loading = true);
    try {
      final date = widget.message.metadata?['date'] as String?;
      await ref.read(chatDetailProvider(widget.offerId).notifier).sendAction(
        actionType: status == 'accepted' ? 'visit_accepted' : 'visit_rejected',
        metadata: date != null ? {'date': date} : {},
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('chat.respond_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reschedule() async {
    if (widget.onReschedule != null) {
      widget.onReschedule!();
    }
  }

  Future<void> _cancel() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const VisitCancelDialog(),
    );
    if (reason == null || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(chatDetailProvider(widget.offerId).notifier).sendAction(
        actionType: 'visit_cancelled',
        metadata: {'reason': reason},
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('chat.cancel_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  (IconData, String, Color, Color) _getConfig(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (_actionType) {
      'visit_request' => (
          Icons.calendar_month_outlined,
          'chat.action_visit_request'.tr(),
          cs.primary,
          cs.primaryContainer,
        ),
      'visit_accepted' => (
          Icons.check_circle_outline,
          'chat.action_visit_accepted'.tr(),
          const Color(0xFF16A34A),
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF052E16)
              : const Color(0xFFF0FDF4),
        ),
      'visit_rejected' => (
          Icons.cancel_outlined,
          'chat.action_visit_rejected'.tr(),
          cs.error,
          cs.errorContainer,
        ),
      'offer_proposal' => (
          Icons.monetization_on_outlined,
          'chat.action_offer_proposal'.tr(),
          _kGold,
          const Color(0xFFFFF7ED),
        ),
      'docs_request' => (
          Icons.folder_outlined,
          'chat.action_docs_request'.tr(),
          const Color(0xFF7C3AED),
          cs.surfaceContainerHighest,
        ),
      'visit_cancelled' => (
          Icons.event_busy_outlined,
          'chat.action_visit_cancelled'.tr(),
          const Color(0xFFD97706),
          const Color(0xFFFFF7ED),
        ),
      _ => (
          Icons.info_outline,
          _actionType.isNotEmpty
              ? 'chat.action_generic'.tr()
              : 'chat.action_generic'.tr(),
          cs.onSurfaceVariant,
          cs.surfaceContainerHighest,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (icon, label, color, bg) = _getConfig(context);
    final meta = widget.message.metadata ?? {};
    final amount = meta['amount'] != null
        ? '\u20AC${(meta['amount'] as num).toStringAsFixed(0)}'
        : null;
    final date = meta['date'] as String?;
    final reason = meta['reason'] as String?;
    final notes = meta['notes'] as String?;

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
                        child: Row(
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
                  if (amount != null || date != null || reason != null || notes != null) ...[
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
                    if (reason != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 14, color: color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              reason,
                              style: TextStyle(fontSize: 12, color: color),
                            ),
                          ),
                        ],
                      ),
                    if (notes != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes_outlined, size: 14, color: color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              notes,
                              style: TextStyle(fontSize: 12, color: color),
                            ),
                          ),
                        ],
                      ),
                  ],
                  // Action buttons (only to receiver, only while not yet answered)
                  if (!widget.isMine && _actionType == 'visit_request' && !widget.isAnswered) ...[
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
                             onPressed: _loading ? null : () => _respond('rejected'),
                            child: Text(
                              'chat.reject'.tr(),
                              style: const TextStyle(
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
                            onPressed: _loading ? null : () => _respond('accepted'),
                            child: _loading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'chat.accept'.tr(),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Replace / Cancel buttons for Confirmed visits (hidden once cancelled)
                  if (_actionType == 'visit_accepted' && widget.isActive) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kNavy,
                              side: BorderSide(
                                  color: _kNavy.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: _loading ? null : _reschedule,
                            child: Text(
                              'chat.reschedule'.tr(),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            onPressed: _loading ? null : _cancel,
                            child: Text(
                              'chat.cancel'.tr(),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
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
    required this.isBuyer,
    required this.visitStatus,
    required this.hasExistingOfferProposal,
  });

  final VoidCallback onVisit;
  final VoidCallback onOffer;
  final bool isBuyer;
  /// 'none' | 'pending' | 'accepted' | rejected maps back to 'none'
  final String visitStatus;
  final bool hasExistingOfferProposal;

  @override
  Widget build(BuildContext context) {
    // Buyer can request a visit only when none is pending/accepted
    final showVisita = isBuyer && visitStatus != 'pending' && visitStatus != 'accepted';
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (showVisita) ...[
            _QuickActionButton(
              icon: Icons.calendar_month_outlined,
              label: 'chat.quick_visit'.tr(),
              color: _kNavy,
              onTap: onVisit,
            ),
            const SizedBox(width: 8),
          ],
          if (!hasExistingOfferProposal) ...[
            _QuickActionButton(
              icon: Icons.payments_outlined,
              label: 'chat.quick_offer'.tr(),
              color: _kGold,
              onTap: onOffer,
            ),
            const SizedBox(width: 8),
          ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 11, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            'chat.encryption_note'.tr(),
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
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
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
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

// ── 24H / AM-PM format toggle button ─────────────────────────────────────────

class _FormatBtn extends StatelessWidget {
  const _FormatBtn({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _kNavy : Colors.transparent,
          border: Border.all(color: _kNavy),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : _kNavy,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
