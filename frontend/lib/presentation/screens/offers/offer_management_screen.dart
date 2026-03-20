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

  static const _sortLabels = {
    _OfferSort.newest: 'Más recientes',
    _OfferSort.oldest: 'Más antiguas',
    _OfferSort.priceAsc: 'Precio: menor a mayor',
    _OfferSort.priceDesc: 'Precio: mayor a menor',
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
      backgroundColor: const Color(0xFFF1F5F9),
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
                const Text(
                  'Ofertas Recibidas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
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
                                    ? const Color(0xFF1E3A5F)
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
                                      ? const Color(0xFF1E3A5F)
                                      : const Color(0xFF334155),
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
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort,
                            size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          _sortLabels[_sortBy]!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more,
                            size: 14, color: Color(0xFF64748B)),
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
                    const Icon(Icons.error_outline,
                        size: 48, color: Color(0xFF64748B)),
                    const SizedBox(height: 12),
                    const Text('Error al cargar ofertas'),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref
                          .read(receivedOffersProvider.notifier)
                          .refresh(),
                      child: const Text('Reintentar'),
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
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No has recibido ofertas aun',
                          style: TextStyle(
                            color: Colors.grey.shade500,
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
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
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
                        style: TextStyle(color: Color(0xFF2563EB))),
                    TextSpan(
                        text: 'Facil',
                        style: TextStyle(color: Color(0xFF16A34A))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => context.go('/'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_rounded, size: 18, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Inicio',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: const UserAvatarMenu(),
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
        child: Row(
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
            // Title + badge + price
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
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    property?.title ?? 'Propiedad',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property != null
                              ? 'Precio de salida ${_formatPrice(property?.price)}'
                              : 'Precio de salida —',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Stats column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                analyticsAsync.when(
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatCell(label: 'OFERTAS', value: '—'),
                      _StatDivider(),
                      _StatCell(label: 'VISITAS', value: '—'),
                      _StatDivider(),
                      _StatCell(label: 'FAVORITOS', value: '—'),
                    ],
                  ),
                  data: (analytics) {
                    final a = analytics ??
                        const PropertyAnalytics(
                            views: 0, favorites: 0, offers: 0);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatCell(
                            label: 'OFERTAS', value: '${a.offers}'),
                        _StatDivider(),
                        _StatCell(
                            label: 'VISITAS', value: '${a.views}'),
                        _StatDivider(),
                        _StatCell(
                            label: 'FAVORITOS', value: '${a.favorites}'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
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
        return 'ACTIVO';
      case 'draft':
        return 'BORRADOR';
      case 'unpublished':
        return 'RETIRADO';
      default:
        return 'ACTIVO';
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

  Widget _imagePlaceholder() => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF6EE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.home_outlined,
            color: Color(0xFF86EFAC), size: 36),
      );
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2563EB),
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
    return Container(width: 1, height: 28, color: Colors.grey.shade200);
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Buyer avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFDBEAFE),
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(
                          buyerInitial,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
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
                        offer.buyerName ?? 'Comprador',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Recibida el $dateStr',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      if (offer.buyerIsVerified) const _BuyerVerifiedBadge(),
                    ],
                  ),
                ),
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
            ),
          ),

          Divider(
              height: 1, thickness: 1, color: Colors.grey.shade100),

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
                      const Text(
                        'CANTIDAD OFRECIDA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
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
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
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
                        const Text(
                          'CONDICIONES',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
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
                        const Text(
                          'FECHA CIERRE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
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
                height: 1, thickness: 1, color: Colors.grey.shade100),
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            _messageExpanded
                                ? 'Ocultar mensaje'
                                : 'Leer mensaje completo',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _messageExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 14,
                            color: const Color(0xFF2563EB),
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
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
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
        title: const Text('Aceptar oferta'),
        content: Text(
            'Vas a aceptar la oferta de \u20AC${widget.offer.amount.toStringAsFixed(0)}. Esta accion no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Aceptar'),
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
        title: const Text('Rechazar oferta'),
        content: const Text(
            'El comprador sera notificado de que su oferta ha sido rechazada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Rechazar'),
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
        title: const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Contra',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'ofertar',
                style: TextStyle(
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
            labelText: 'Tu contraoferta',
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
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Enviar'),
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
            backgroundColor: const Color(0xFF2563EB),
            shape: _shape,
            padding: _pad,
            tapTargetSize: _tts,
          ),
          child: const Text('Aceptar Oferta',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
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
          child: const Text('Contraofertar',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        OutlinedButton(
          onPressed: onReject,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF94A3B8),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: _shape,
            padding: _pad,
            tapTargetSize: _tts,
          ),
          child: const Text('Rechazar',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 12, color: Color(0xFF16A34A)),
          SizedBox(width: 4),
          Text(
            'VERIFICADO',
            style: TextStyle(
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
      isCash ? 'Pago al\nContado' : 'Necesita\nHipoteca',
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF1E293B),
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
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
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
        children: const [
          Icon(Icons.bolt, size: 14, color: Color(0xFFF59E0B)),
          SizedBox(width: 3),
          Text(
            'Inmediato',
            style: TextStyle(
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
        const Icon(Icons.event_outlined,
            size: 14, color: Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          _fmt(date),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1E293B),
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
          'fg': const Color(0xFF2563EB),
          'label': 'PENDIENTE',
        };
      case 'accepted':
        return {
          'bg': const Color(0xFFDCFCE7),
          'fg': const Color(0xFF16A34A),
          'label': 'ACEPTADA',
        };
      case 'counter_offer':
      case 'countered':
        return {
          'bg': const Color(0xFFFEF9C3),
          'fg': const Color(0xFFCA8A04),
          'label': 'CONTRAOFERTA ENVIADA',
        };
      case 'signing_pending':
        return {
          'bg': const Color(0xFFEDE9FE),
          'fg': const Color(0xFF7C3AED),
          'label': 'EN FIRMA',
        };
      case 'signed':
        return {
          'bg': const Color(0xFFEDE9FE),
          'fg': const Color(0xFF6D28D9),
          'label': 'FIRMADA',
        };
      case 'completed':
        return {
          'bg': const Color(0xFFDCFCE7),
          'fg': const Color(0xFF15803D),
          'label': 'COMPLETADA',
        };
      case 'rejected':
        return {
          'bg': const Color(0xFFFEF2F2),
          'fg': const Color(0xFFDC2626),
          'label': 'RECHAZADA',
        };
      case 'withdrawn':
        return {
          'bg': const Color(0xFFFFF7ED),
          'fg': const Color(0xFFF59E0B),
          'label': 'RETIRADA',
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
        title: const Text('Rechazar oferta'),
        content: const Text(
            'El comprador sera notificado de que su oferta ha sido rechazada. Esta accion no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
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
          const SnackBar(content: Text('Oferta rechazada')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Error al rechazar la oferta. Intentalo de nuevo.')),
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  color: Color(0xFF16A34A), size: 18),
              SizedBox(width: 8),
              Text(
                'Solvencia del comprador',
                style: TextStyle(
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
            error: (_, __) => const Text(
              'El comprador aun no tiene pasaporte de solvencia.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            data: (passport) {
              if (passport == null) {
                return const Text(
                  'El comprador aun no ha completado el pasaporte de solvencia.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                );
              }
              final level = passport.solvencyLevel ?? 'bronze';
              final (levelLabel, levelColor, levelBg, levelIcon) =
                  switch (level) {
                'gold' => (
                  'Oro',
                  const Color(0xFFB8860B),
                  const Color(0xFFFFFBEB),
                  Icons.emoji_events_outlined
                ),
                'silver' => (
                  'Plata',
                  const Color(0xFF64748B),
                  const Color(0xFFF8FAFC),
                  Icons.verified_outlined
                ),
                _ => (
                  'Bronce',
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
                          'Nivel $levelLabel',
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
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Compra conjunta',
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
                      label: 'Conoce gastos adicionales',
                      value: passport.knowsExtraCosts ? 'Si' : 'No'),
                  _SolvencyRow(
                      label: 'Ahorros iniciales',
                      value: passport.hasInitialSavings ? 'Si' : 'No'),
                  _SolvencyRow(
                      label: 'Preaprobacion hipotecaria',
                      value: passport.hasPreApproval ? 'Si' : 'No'),
                  _SolvencyRow(
                      label: 'Financiacion',
                      value: passport.paymentMethodLabel ??
                          passport.paymentMethod ??
                          '-'),
                  if (passport.isMultiBuyer &&
                      passport.secondBuyerName != null)
                    _SolvencyRow(
                        label: 'Segundo comprador',
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
                  label: const Text('Aceptar solvencia y ver timeline'),
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
                label: const Text('Rechazar'),
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
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified_user,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Todas las ofertas son legalmente vinculantes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'InmuFacil asegura la identidad de cada comprador.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Ver proceso\nde cierre',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF2563EB),
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
                  size: 14, color: Color(0xFF2563EB)),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'InmuFacil Secure-Tech  \u00B7  \u00A9 2023 InmuFacil S.L. Todos los derechos reservados. Sistema de transacciones seguras bajo protocolo AES-256',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 12),
              _FooterLink(label: 'Ayuda', onTap: () {}),
              const SizedBox(width: 10),
              _FooterLink(label: 'Legal', onTap: () {}),
              const SizedBox(width: 10),
              _FooterLink(label: 'Seguridad', onTap: () {}),
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
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF64748B),
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
      label: const Text('Chat',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        side: const BorderSide(color: Color(0xFF2563EB)),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
