import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/currency_input_formatter.dart';
import '../../providers/offers_provider.dart';
import '../../providers/my_properties_provider.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../providers/solvency_provider.dart' as solvency_prov;
import '../../providers/property_analytics_provider.dart';

enum _OfferSort {
  newest,
  oldest,
  priceAsc,
  priceDesc,
}

class OfferManagementScreen extends ConsumerStatefulWidget {
  const OfferManagementScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<OfferManagementScreen> createState() =>
      _OfferManagementScreenState();
}

class _OfferManagementScreenState extends ConsumerState<OfferManagementScreen> {
  _OfferSort _sortBy = _OfferSort.newest;

  static Map<_OfferSort, String> get _sortLabels => {
    _OfferSort.newest: 'offers.sort_newest'.tr(),
    _OfferSort.oldest: 'offers.sort_oldest'.tr(),
    _OfferSort.priceAsc: 'offers.sort_price_asc'.tr(),
    _OfferSort.priceDesc: 'offers.sort_price_desc'.tr(),
  };

  List<OfferData> _sorted(List<OfferData> offers) {
    final list = List<OfferData>.from(offers);
    switch (_sortBy) {
      case _OfferSort.newest:
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      case _OfferSort.oldest:
        list.sort((a, b) =>
            (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
      case _OfferSort.priceAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
      case _OfferSort.priceDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(receivedOffersProvider);
    final propertiesAsync = ref.watch(myPropertiesProvider);

    final property = propertiesAsync.whenOrNull(
      data: (list) =>
          list.where((p) => p.id == widget.propertyId).firstOrNull,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context, ref),
      body: ListView(
        children: [
          // Property header card
          _PropertyHeaderCard(
              property: property, propertyId: widget.propertyId),

          // Section title + sort row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Text(
                  'offers.received_title'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<_OfferSort>(
                  onSelected: (v) => setState(() => _sortBy = v),
                  offset: const Offset(0, 36),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  itemBuilder: (_) => _OfferSort.values
                      .map(
                        (s) => PopupMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Icon(
                                s == _sortBy
                                    ? Icons.check
                                    : Icons.check,
                                size: 16,
                                color: s == _sortBy
                                    ? const Color(0xFF135BEC)
                                    : Colors.transparent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _sortLabels[s]!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: s == _sortBy
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: s == _sortBy
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort,
                            size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          _sortLabels[_sortBy]!,
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.expand_more,
                            size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Offers list
          offersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('offers.error_loading'.tr()),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref
                          .read(receivedOffersProvider.notifier)
                          .refresh(),
                      child: Text('offers.retry'.tr()),
                    ),
                  ],
                ),
              ),
            ),
            data: (allOffers) {
              final offers = _sorted(allOffers
                  .where((o) => o.propertyId == widget.propertyId)
                  .toList());
              if (offers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: Theme.of(context).colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                        Text(
                          'offers.no_offers'.tr(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: offers
                    .map((o) => _OfferCard(
                          offer: o,
                          askingPrice: property?.price ?? 0,
                        ))
                    .toList(),
              );
            },
          ),

          // Trust footer
          const _TrustFooter(),

          // Page footer
          const _PageFooter(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
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
              context.go('/profile');
            }
          },
        ),
      ),
      title: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go('/'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo_inmufacil.png', height: 32),
              const SizedBox(width: 8),
              const Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(
                        text: 'Inmu',
                        style: TextStyle(color: Color(0xFF135BEC))),
                    TextSpan(
                        text: 'Fácil',
                        style: TextStyle(color: Color(0xFF16A34A))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Builder(builder: (context) {
          final isMobile = MediaQuery.of(context).size.width < 650;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile) ...[
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF135BEC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.home_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('common.home'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: UserAvatarMenu(),
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Property Header Card
// ---------------------------------------------------------------------------

class _PropertyHeaderCard extends ConsumerWidget {
  const _PropertyHeaderCard(
      {required this.property, required this.propertyId});

  final dynamic property;
  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(propertyAnalyticsProvider(propertyId));
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            Widget statsWidget() => analyticsAsync.when(
              loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatCell(label: 'offers.stat_offers'.tr(), value: '\u2014'),
                  _StatDivider(),
                  _StatCell(label: 'offers.stat_visits'.tr(), value: '\u2014'),
                  _StatDivider(),
                  _StatCell(label: 'offers.stat_favorites'.tr(), value: '\u2014'),
                ],
              ),
              data: (analytics) {
                final a = analytics ??
                    const PropertyAnalytics(views: 0, favorites: 0, offers: 0);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatCell(label: 'offers.stat_offers'.tr(), value: '${a.offers}'),
                    _StatDivider(),
                    _StatCell(label: 'offers.stat_visits'.tr(), value: '${a.views}'),
                    _StatDivider(),
                    _StatCell(label: 'offers.stat_favorites'.tr(), value: '${a.favorites}'),
                  ],
                );
              },
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Property image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (property?.images?.isNotEmpty == true)
                      ? Image.network(
                          property!.images.first,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                const SizedBox(width: 14),
                // Title + badge + price (+ stats on mobile)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusBadgeSmall(
                            label: _statusLabel(property?.status),
                            color: _statusColor(property?.status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ref. IF-${propertyId.padLeft(4, '0')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        property?.title ?? 'offers.property_fallback'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              property != null
                                  ? 'offers.starting_price'.tr(args: [_formatPrice(property?.price)])
                                  : 'offers.starting_price_empty'.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (isMobile) ...[
                        const SizedBox(height: 10),
                        statsWidget(),
                      ],
                    ],
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [statsWidget()],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatPrice(int? price) {
    if (price == null) return '\u2014';
    return '${CurrencyInputFormatter.format(price)}\u20AC';
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'published':
        return 'offers.status_active'.tr();
      case 'draft':
        return 'offers.status_draft'.tr();
      case 'unpublished':
        return 'offers.status_unpublished'.tr();
      default:
        return 'offers.status_active'.tr();
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'published':
        return const Color(0xFF16A34A);
      case 'draft':
        return const Color(0xFFF59E0B);
      case 'unpublished':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF16A34A);
    }
  }

  Widget _imagePlaceholder() {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.home_outlined,
              color: colorScheme.secondary, size: 36),
        );
      },
    );
  }
}

class _StatusBadgeSmall extends StatelessWidget {
  const _StatusBadgeSmall({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF135BEC),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: Theme.of(context).colorScheme.outlineVariant);
  }
}

// ---------------------------------------------------------------------------
// Offer Card
// ---------------------------------------------------------------------------

class _OfferCard extends ConsumerStatefulWidget {
  const _OfferCard({required this.offer, this.askingPrice = 0});

  final OfferData offer;
  final double askingPrice;

  @override
  ConsumerState<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends ConsumerState<_OfferCard> {
  final _counterController = TextEditingController();
  bool _messageExpanded = false;

  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  double get _diffPercent {
    if (widget.askingPrice <= 0) return 0;
    return ((widget.offer.amount - widget.askingPrice) /
            widget.askingPrice) *
        100;
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final diff = _diffPercent;
    final buyerInitial = (offer.buyerName?.isNotEmpty == true)
        ? offer.buyerName![0].toUpperCase()
        : '?';
    final dateStr = offer.createdAt != null
        ? _formatDate(offer.createdAt!)
        : '';
    final isPending = offer.status == 'pending';
    final photoUrl = offer.buyerPhotoUrl;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Top section: buyer info + action buttons ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final buyerInfo = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Buyer avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : null,
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? Text(
                              buyerInitial,
                              style: const TextStyle(
                                color: Color(0xFF135BEC),
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Buyer name + date + badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.buyerName ?? 'offers.buyer_fallback'.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (dateStr.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'offers.received_on'.tr(args: [dateStr]),
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          if (offer.buyerIsVerified) const _BuyerVerifiedBadge(),
                        ],
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      if (isPending)
                        _ActionButtonsRow(
                          offer: offer,
                          onAccept: () => _confirmAccept(context),
                          onCounter: () => _showCounterDialog(context),
                          onReject: () => _confirmReject(context),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusBadge(status: offer.status),
                            if (offer.status != 'withdrawn' &&
                                offer.status != 'rejected') ...[
                              const SizedBox(width: 8),
                              _ChatButtonSmall(offerId: offer.id),
                            ],
                          ],
                        ),
                    ],
                  ],
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buyerInfo,
                      const SizedBox(height: 10),
                      if (isPending)
                        _ActionButtonsRow(
                          offer: offer,
                          onAccept: () => _confirmAccept(context),
                          onCounter: () => _showCounterDialog(context),
                          onReject: () => _confirmReject(context),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusBadge(status: offer.status),
                            if (offer.status != 'withdrawn' &&
                                offer.status != 'rejected') ...[
                              const SizedBox(width: 8),
                              _ChatButtonSmall(offerId: offer.id),
                            ],
                          ],
                        ),
                    ],
                  );
                }
                return buyerInfo;
              },
            ),
          ),

          Divider(
              height: 1, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant),

          // ---- Middle section: amount + conditions + date ----
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MONTO OFRECIDO
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'offers.amount_offered'.tr(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '\u20AC${_formatAmount(offer.amount)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (widget.askingPrice > 0)
                            _DiffPill(diff: diff),
                        ],
                      ),
                    ],
                  ),
                ),
                // CONDICIONES
                if (offer.paymentTerm != null)
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'offers.conditions_header'.tr(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _ConditionChip(
                            paymentTerm: offer.paymentTerm!),
                      ],
                    ),
                  ),
                // FECHA CIERRE
                if (offer.closingDate != null)
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'offers.closing_date'.tr(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _ClosingDateChip(
                            date: offer.closingDate!),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ---- Message section ----
          if (offer.conditions != null &&
              offer.conditions!.isNotEmpty) ...[
            Divider(
                height: 1, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant),
             Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(
                      () => _messageExpanded = !_messageExpanded),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _messageExpanded
                            ? offer.conditions!
                            : _truncate(offer.conditions!, 120),
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            _messageExpanded
                                ? 'offers.hide_message'.tr()
                                : 'offers.read_message'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF135BEC),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _messageExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 14,
                            color: const Color(0xFF135BEC),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 4),

          // ---- Solvency acceptance section for accepted offers ----
          if (offer.status == 'accepted')
            _SolvencyAcceptanceSection(offer: offer),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'offers.month_jan'.tr(), 'offers.month_feb'.tr(),
      'offers.month_mar'.tr(), 'offers.month_apr'.tr(),
      'offers.month_may'.tr(), 'offers.month_jun'.tr(),
      'offers.month_jul'.tr(), 'offers.month_aug'.tr(),
      'offers.month_sep'.tr(), 'offers.month_oct'.tr(),
      'offers.month_nov'.tr(), 'offers.month_dec'.tr(),
    ];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  String _formatAmount(int amount) => CurrencyInputFormatter.format(amount);

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }

  Future<void> _confirmAccept(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: Text('offers.accept_title'.tr()),
        content: Text(
            'offers.accept_body'.tr(args: ['\u20AC${widget.offer.amount.toStringAsFixed(0)}'])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('common.accept'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(receivedOffersProvider.notifier)
          .accept(widget.offer.id);
    }
  }

  Future<void> _confirmReject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: Text('offers.reject_title'.tr()),
        content: Text(
            'offers.reject_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('common.reject'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(receivedOffersProvider.notifier)
          .reject(widget.offer.id);
    }
  }

  Future<void> _showCounterDialog(BuildContext context) async {
    _counterController.clear();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'offers.counter_title_prefix'.tr(),
                style: const TextStyle(
                  color: Color(0xFF135BEC),
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'offers.counter_title_suffix'.tr(),
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        content: TextField(
          controller: _counterController,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: InputDecoration(
            labelText: 'offers.counter_label'.tr(),
            suffixText: ' €',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('common.send'.tr()),
          ),
        ],
      ),
    );
    if (submitted == true && mounted) {
      final amount = CurrencyInputFormatter.parse(_counterController.text);
      if (amount != null && amount > 0) {
        await ref
            .read(receivedOffersProvider.notifier)
            .counter(widget.offer.id, amount);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Action Buttons Row (horizontal layout on right of offer card)
// ---------------------------------------------------------------------------

class _ActionButtonsRow extends StatelessWidget {
  const _ActionButtonsRow({
    required this.offer,
    required this.onAccept,
    required this.onCounter,
    required this.onReject,
  });

  final OfferData offer;
  final VoidCallback onAccept;
  final VoidCallback onCounter;
  final VoidCallback onReject;

  static const _shape =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)));
  static const _pad = EdgeInsets.symmetric(horizontal: 10, vertical: 8);
  static const _tts = MaterialTapTargetSize.shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        FilledButton(
          onPressed: onAccept,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF135BEC),
            shape: _shape,
            padding: _pad,
            tapTargetSize: _tts,
          ),
          child: Text('offers.accept_btn'.tr(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        OutlinedButton(
          onPressed: onCounter,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF59E0B),
            side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
            shape: _shape,
            padding: _pad,
            tapTargetSize: _tts,
          ),
          child: Text('offers.counter_btn'.tr(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        OutlinedButton(
          onPressed: onReject,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            shape: _shape,
            padding: _pad,
            tapTargetSize: _tts,
          ),
          child: Text('offers.reject_btn'.tr(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        _ChatButtonSmall(offerId: offer.id),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Buyer Badge
// ---------------------------------------------------------------------------

class _BuyerVerifiedBadge extends StatelessWidget {
  const _BuyerVerifiedBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.secondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_outlined, size: 12, color: Color(0xFF16A34A)),
          const SizedBox(width: 4),
          Text(
            'offers.verified'.tr(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF16A34A),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Diff Pill
// ---------------------------------------------------------------------------

class _DiffPill extends StatelessWidget {
  const _DiffPill({required this.diff});

  final double diff;

  @override
  Widget build(BuildContext context) {
    final isNeg = diff < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isNeg
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}%',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: isNeg
              ? const Color(0xFFEA580C)
              : const Color(0xFF16A34A),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Condition Chip
// ---------------------------------------------------------------------------

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({required this.paymentTerm});

  final String paymentTerm;

  @override
  Widget build(BuildContext context) {
    final isCash = paymentTerm == 'cash';
    return Text(
      isCash ? 'offers.payment_cash'.tr() : 'offers.payment_mortgage'.tr(),
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Closing Date Chip
// ---------------------------------------------------------------------------

class _ClosingDateChip extends StatelessWidget {
  const _ClosingDateChip({required this.date});

  final DateTime date;

  String _fmt(DateTime dt) {
    final months = [
      'offers.month_jan'.tr(), 'offers.month_feb'.tr(),
      'offers.month_mar'.tr(), 'offers.month_apr'.tr(),
      'offers.month_may'.tr(), 'offers.month_jun'.tr(),
      'offers.month_jul'.tr(), 'offers.month_aug'.tr(),
      'offers.month_sep'.tr(), 'offers.month_oct'.tr(),
      'offers.month_nov'.tr(), 'offers.month_dec'.tr(),
    ];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  bool get _isImmediate =>
      date.difference(DateTime.now()).inDays <= 7;

  @override
  Widget build(BuildContext context) {
    if (_isImmediate) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, size: 14, color: Color(0xFFF59E0B)),
          const SizedBox(width: 3),
          Text(
            'offers.immediate'.tr(),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFF59E0B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_outlined,
            size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          _fmt(date),
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Status Badge (accepted / rejected / countered)
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final config = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config['bg'] as Color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config['label'] as String,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: config['fg'] as Color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Map<String, dynamic> _config(String s) {
    switch (s) {
      case 'pending':
        return {
          'bg': const Color(0xFFEFF6FF),
          'fg': const Color(0xFF135BEC),
          'label': 'offers.status_pending'.tr(),
        };
      case 'accepted':
        return {
          'bg': const Color(0xFFDCFCE7),
          'fg': const Color(0xFF16A34A),
          'label': 'offers.status_accepted'.tr(),
        };
      case 'counter_offer':
      case 'countered':
        return {
          'bg': const Color(0xFFFEF9C3),
          'fg': const Color(0xFFCA8A04),
          'label': 'offers.status_counter'.tr(),
        };
      case 'signing_pending':
        return {
          'bg': const Color(0xFFEDE9FE),
          'fg': const Color(0xFF7C3AED),
          'label': 'offers.status_signing'.tr(),
        };
      case 'signed':
        return {
          'bg': const Color(0xFFEDE9FE),
          'fg': const Color(0xFF6D28D9),
          'label': 'offers.status_signed'.tr(),
        };
      case 'completed':
        return {
          'bg': const Color(0xFFDCFCE7),
          'fg': const Color(0xFF15803D),
          'label': 'offers.status_completed'.tr(),
        };
      case 'rejected':
        return {
          'bg': const Color(0xFFFEF2F2),
          'fg': const Color(0xFFDC2626),
          'label': 'offers.status_rejected'.tr(),
        };
      case 'withdrawn':
        return {
          'bg': const Color(0xFFFFF7ED),
          'fg': const Color(0xFFF59E0B),
          'label': 'offers.status_withdrawn'.tr(),
        };
      default:
        return {
          'bg': const Color(0xFFF1F5F9),
          'fg': const Color(0xFF64748B),
          'label': s.toUpperCase(),
        };
    }
  }
}

// ---------------------------------------------------------------------------
// Solvency Acceptance Section — shown inside _OfferCard when status == 'accepted'
// ---------------------------------------------------------------------------

class _SolvencyAcceptanceSection extends ConsumerStatefulWidget {
  const _SolvencyAcceptanceSection({required this.offer});

  final OfferData offer;

  @override
  ConsumerState<_SolvencyAcceptanceSection> createState() =>
      _SolvencyAcceptanceSectionState();
}

class _SolvencyAcceptanceSectionState
    extends ConsumerState<_SolvencyAcceptanceSection> {
  bool _rejecting = false;
  bool _accepting = false;

  Future<void> _acceptAndNavigate(BuildContext context) async {
    setState(() => _accepting = true);
    try {
      await ref
          .read(receivedOffersProvider.notifier)
          .acceptSolvency(widget.offer.id);
    } catch (_) {
      // Endpoint may already be accepted; proceed to timeline regardless
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
    if (mounted) {
      context.push(
        '/offers/${widget.offer.id}/timeline',
        extra: widget.offer,
      );
    }
  }

  Future<void> _confirmReject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('offers.reject_title'.tr()),
        content: Text(
            'offers.reject_body_solvency'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('common.reject'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _rejecting = true);
    try {
      await ref
          .read(receivedOffersProvider.notifier)
          .reject(widget.offer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('offers.offer_rejected_snackbar'.tr())),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('offers.reject_error_snackbar'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _rejecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passportAsync =
        ref.watch(solvency_prov.buyerPassportProvider(widget.offer.id));

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 8),
              Text(
                'offers.solvency_title'.tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF166534)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          passportAsync.when(
            loading: () => const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => Text(
              'offers.no_passport'.tr(),
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            data: (passport) {
              if (passport == null) {
                return Text(
                  'offers.incomplete_passport'.tr(),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                );
              }
              final level = passport.solvencyLevel ?? 'bronze';
              final (levelLabel, levelColor, levelBg, levelIcon) =
                  switch (level) {
                'gold' => (
                  'offers.gold'.tr(),
                  const Color(0xFFB8860B),
                  const Color(0xFFFFFBEB),
                  Icons.emoji_events_outlined
                ),
                'silver' => (
                  'offers.silver'.tr(),
                  const Color(0xFF64748B),
                  colorScheme.surfaceContainerHighest,
                  Icons.verified_outlined
                ),
                _ => (
                  'offers.bronze'.tr(),
                  const Color(0xFFD97706),
                  const Color(0xFFFFF7ED),
                  Icons.shield_outlined
                ),
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: levelBg,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: levelColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(levelIcon, color: levelColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'offers.level'.tr(args: [levelLabel]),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: levelColor,
                          ),
                        ),
                        if (passport.isMultiBuyer) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF135BEC),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'offers.joint_purchase'.tr(),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _SolvencyRow(
                      label: 'offers.knows_costs'.tr(),
                      value: passport.knowsExtraCosts ? 'common.yes'.tr() : 'common.no'.tr()),
                  _SolvencyRow(
                      label: 'offers.initial_savings'.tr(),
                      value: passport.hasInitialSavings ? 'common.yes'.tr() : 'common.no'.tr()),
                  _SolvencyRow(
                      label: 'offers.preapproval'.tr(),
                      value: passport.hasPreApproval ? 'common.yes'.tr() : 'common.no'.tr()),
                  _SolvencyRow(
                      label: 'offers.financing'.tr(),
                      value: passport.paymentMethodLabel ??
                          passport.paymentMethod ??
                          '-'),
                  if (passport.isMultiBuyer &&
                      passport.secondBuyerName != null)
                    _SolvencyRow(
                        label: 'offers.second_buyer'.tr(),
                        value: passport.secondBuyerName!),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: (_accepting || _rejecting)
                      ? null
                      : () => _acceptAndNavigate(context),
                  icon: _accepting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.verified_user_outlined, size: 16),
                  label: Text('offers.accept_solvency'.tr()),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed:
                    _rejecting ? null : () => _confirmReject(context),
                icon: _rejecting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cancel_outlined, size: 16),
                label: Text('common.reject'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SolvencyRow extends StatelessWidget {
  const _SolvencyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trust Footer
// ---------------------------------------------------------------------------

class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF135BEC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified_user,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'offers.all_binding'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'offers.identity_secured'.tr(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: Text(
              'offers.view_closing'.tr(),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF135BEC),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page Footer
// ---------------------------------------------------------------------------

class _PageFooter extends StatelessWidget {
  const _PageFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.shield_rounded,
                  size: 14, color: Color(0xFF135BEC)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'offers.footer_text'.tr(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 12),
              _FooterLink(label: 'offers.help'.tr(), onTap: () {}),
              const SizedBox(width: 10),
              _FooterLink(label: 'offers.legal_link'.tr(), onTap: () {}),
              const SizedBox(width: 10),
              _FooterLink(label: 'offers.security_mgmt_link'.tr(), onTap: () {}),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ChatButtonSmall — habilita chat y navega a la sala privada (compacto)
// ---------------------------------------------------------------------------

class _ChatButtonSmall extends ConsumerStatefulWidget {
  const _ChatButtonSmall({required this.offerId});
  final String offerId;

  @override
  ConsumerState<_ChatButtonSmall> createState() => _ChatButtonSmallState();
}

class _ChatButtonSmallState extends ConsumerState<_ChatButtonSmall> {
  bool _loading = false;

  Future<void> _onPressed() async {
    setState(() => _loading = true);
    try {
      await ref.read(receivedOffersProvider.notifier).enableChat(widget.offerId);
    } catch (_) {
      // already enabled
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (mounted) context.push('/chat/${widget.offerId}');
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _onPressed,
      icon: _loading
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chat_bubble_outline, size: 14),
      label: Text('offers.chat'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF135BEC),
        side: const BorderSide(color: Color(0xFF135BEC)),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
