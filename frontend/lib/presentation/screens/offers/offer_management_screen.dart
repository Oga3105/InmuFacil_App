import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/offers_provider.dart';
import '../../providers/my_properties_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';

class OfferManagementScreen extends ConsumerWidget {
  const OfferManagementScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(receivedOffersProvider);
    final propertiesAsync = ref.watch(myPropertiesProvider);
    final user = ref.watch(authProvider).user;

    final property = propertiesAsync.whenOrNull(
      data: (list) => list.where((p) => p.id == propertyId).firstOrNull,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, user),
      body: ListView(
        children: [
          // Property header card
          _PropertyHeaderCard(property: property, propertyId: propertyId),

          // Section title + filter row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Text(
                  'Ofertas Recibidas',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list, size: 14),
                  label: const Text('Filtrar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Mas recientes',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                      SizedBox(width: 4),
                      Icon(Icons.expand_more,
                          size: 14, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

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
              final offers = allOffers
                  .where((o) => o.propertyId == propertyId)
                  .toList();
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

  PreferredSizeWidget _buildAppBar(BuildContext context, dynamic user) {
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
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
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
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
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
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
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
                  Icon(Icons.home_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Inicio',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2563EB),
            backgroundImage: (user?.profilePhotoUrl != null &&
                    user!.profilePhotoUrl!.isNotEmpty)
                ? NetworkImage(user.profilePhotoUrl!)
                : null,
            child: (user?.profilePhotoUrl == null ||
                    user!.profilePhotoUrl!.isEmpty)
                ? Text(
                    (user?.name?.isNotEmpty == true)
                        ? user!.name![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

// --- Property Header Card ---

class _PropertyHeaderCard extends StatelessWidget {
  const _PropertyHeaderCard({required this.property, required this.propertyId});

  final dynamic property;
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Property image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (property?.images.isNotEmpty == true)
                      ? Image.network(
                          property!.images.first,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(72),
                        )
                      : _imagePlaceholder(72),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ACTIVO badge + ref
                      Row(
                        children: [
                          _StatusBadgeSmall(
                            label: _statusLabel(property?.status),
                            color: _statusColor(property?.status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ref. #${propertyId.padLeft(4, '0')}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property?.title ?? 'Propiedad',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        property?.address ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCell(label: 'OFERTAS', value: '—'),
                _StatDivider(),
                _StatCell(label: 'VISITAS', value: '—'),
                _StatDivider(),
                _StatCell(label: 'FAVORITOS', value: '—'),
              ],
            ),
          ],
        ),
      ),
    );
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

  Widget _imagePlaceholder(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.home_outlined,
            color: Colors.grey.shade400, size: size * 0.45),
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
        color: color.withOpacity(0.1),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Colors.grey.shade200);
  }
}

// --- Offer Card ---

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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Buyer row
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    buyerInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.buyerName ?? 'Comprador',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          'Recibida el $dateStr',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
                _SolvenciaBadge(paymentTerm: offer.paymentTerm),
              ],
            ),

            const SizedBox(height: 14),
            Divider(color: Colors.grey.shade100),
            const SizedBox(height: 14),

            // Amount + diff + conditions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OFERTA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '\u20AC${_formatAmount(offer.amount)}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.askingPrice > 0)
                            _DiffPill(diff: diff),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Conditions + closing date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (offer.paymentTerm != null) ...[
                      const Text(
                        'CONDICIONES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _ConditionChip(paymentTerm: offer.paymentTerm!),
                    ],
                    if (offer.closingDate != null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'FECHA CIERRE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_outlined,
                              size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(offer.closingDate!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // Message preview
            if (offer.conditions != null &&
                offer.conditions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () =>
                    setState(() => _messageExpanded = !_messageExpanded),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _messageExpanded
                          ? offer.conditions!
                          : _truncate(offer.conditions!, 80),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Action buttons (only for pending)
            if (offer.status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: FilledButton(
                      onPressed: () => _confirmAccept(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Aceptar Oferta',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: OutlinedButton(
                      onPressed: () => _showCounterDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        side: const BorderSide(
                            color: Color(0xFFF59E0B)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Contraofertar',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => _confirmReject(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                    ),
                    child: const Text('Rechazar',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ] else ...[
              _StatusBadge(status: offer.status),
            ],
          ],
        ),
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

  String _formatAmount(double amount) {
    final s = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

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
                backgroundColor: const Color(0xFF16A34A)),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(receivedOffersProvider.notifier)
          .counter(widget.offer.id, widget.offer.amount);
    }
  }

  Future<void> _showCounterDialog(BuildContext context) async {
    _counterController.clear();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Text('Contraofertar'),
        content: TextField(
          controller: _counterController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Tu contraoferta',
            prefixText: '\u20AC ',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B)),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (submitted == true && mounted) {
      final amount = double.tryParse(_counterController.text);
      if (amount != null && amount > 0) {
        await ref
            .read(receivedOffersProvider.notifier)
            .counter(widget.offer.id, amount);
      }
    }
  }
}

// --- Solvencia Badge ---

class _SolvenciaBadge extends StatelessWidget {
  const _SolvenciaBadge({this.paymentTerm});

  final String? paymentTerm;

  @override
  Widget build(BuildContext context) {
    final isCash = paymentTerm == 'cash';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCash
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCash
              ? const Color(0xFF86EFAC)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Text(
        isCash ? 'SOLVENCIA VERIFICADA' : 'COMPRADOR PROFESIONAL',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: isCash
              ? const Color(0xFF16A34A)
              : const Color(0xFF2563EB),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// --- Diff Pill ---

class _DiffPill extends StatelessWidget {
  const _DiffPill({required this.diff});

  final double diff;

  @override
  Widget build(BuildContext context) {
    final isNeg = diff < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isNeg
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}%',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: isNeg
              ? const Color(0xFFEA580C)
              : const Color(0xFF16A34A),
        ),
      ),
    );
  }
}

// --- Condition Chip ---

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({required this.paymentTerm});

  final String paymentTerm;

  @override
  Widget build(BuildContext context) {
    final isCash = paymentTerm == 'cash';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isCash
              ? Icons.payments_outlined
              : Icons.account_balance_outlined,
          size: 14,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 4),
        Text(
          isCash ? 'Pago al Contado' : 'Necesita Hipoteca',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// --- Status Badge (accepted/rejected/countered) ---

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final config = _config(status);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      ),
    );
  }

  Map<String, dynamic> _config(String s) {
    switch (s) {
      case 'accepted':
        return {
          'bg': const Color(0xFFDCFCE7),
          'fg': const Color(0xFF16A34A),
          'label': 'ACEPTADA',
        };
      case 'rejected':
        return {
          'bg': const Color(0xFFF1F5F9),
          'fg': const Color(0xFF64748B),
          'label': 'RECHAZADA',
        };
      case 'countered':
        return {
          'bg': const Color(0xFFFEF9C3),
          'fg': const Color(0xFFCA8A04),
          'label': 'CONTRAOFERTA ENVIADA',
        };
      default:
        return {
          'bg': const Color(0xFFEFF6FF),
          'fg': const Color(0xFF2563EB),
          'label': 'PENDIENTE',
        };
    }
  }
}

// --- Trust Footer ---

class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              size: 20, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Todas las ofertas son legalmente vinculantes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Ver proceso de cierre',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Page Footer ---

class _PageFooter extends StatelessWidget {
  const _PageFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_rounded,
                  size: 14, color: Color(0xFF2563EB)),
              const SizedBox(width: 4),
              const Text(
                'InmuFacil Secure-Tech',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '\u00A9 2024 InmuFacil. Todos los derechos reservados.',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FooterLink(label: 'Ayuda', onTap: () {}),
              const SizedBox(width: 16),
              _FooterLink(label: 'Legal', onTap: () {}),
              const SizedBox(width: 16),
              _FooterLink(label: 'Seguridad', onTap: () {}),
            ],
          ),
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
