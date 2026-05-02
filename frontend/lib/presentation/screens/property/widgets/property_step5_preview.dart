import 'dart:math' as math;
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/formatters/currency_input_formatter.dart';
import '../../../providers/property_form_provider.dart';

// ─── Entry point ───────────────────────────────────────────────────────────────

class PropertyStep5Preview extends ConsumerWidget {
  const PropertyStep5Preview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(propertyFormProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        return isDesktop
            ? _DesktopPreview(s: s)
            : _MobilePreview(s: s);
      },
    );
  }
}

// ─── Desktop layout ────────────────────────────────────────────────────────────

class _DesktopPreview extends StatelessWidget {
  const _DesktopPreview({required this.s});
  final PropertyFormState s;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview banner
              _PreviewBanner(),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT column (7/12)
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PreviewCarousel(
                            mediaItems: s.visibleMedia, isMobile: false),
                        const SizedBox(height: 32),
                        _PreviewDescriptionSection(s: s),
                        const SizedBox(height: 32),
                        _PreviewLocationSection(
                            location: s.selectedLocation),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  // RIGHT column (5/12) — sticky summary card
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _PreviewSummaryCard(s: s),
                        const SizedBox(height: 24),
                        _PreviewMortgageCard(s: s),
                      ],
                    ),
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

// ─── Mobile layout ─────────────────────────────────────────────────────────────

class _MobilePreview extends StatelessWidget {
  const _MobilePreview({required this.s});
  final PropertyFormState s;

  @override
  Widget build(BuildContext context) {
    final price = CurrencyInputFormatter.parse(s.priceText) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PreviewBanner(),
          _PreviewCarousel(mediaItems: s.visibleMedia, isMobile: true),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price
                Builder(builder: (context) {
                  final cs = Theme.of(context).colorScheme;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price > 0
                            ? '${CurrencyInputFormatter.format(price)} €'
                            : '— €',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.titleText.isNotEmpty ? s.titleText : 'property_wizard.no_title'.tr(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: cs.onSurface,
                        ),
                      ),
                      if (s.addressText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                s.addressText,
                                style: TextStyle(
                                    fontSize: 13, color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                }),
                const SizedBox(height: 20),
                _StatsGrid(s: s),
                Builder(builder: (context) => Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 40)),
                _PreviewDescriptionSection(s: s),
                const SizedBox(height: 32),
                _PreviewLocationSection(location: s.selectedLocation),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Preview banner ────────────────────────────────────────────────────────────

class _PreviewBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'property_wizard.preview_badge'.tr(),
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'property_wizard.preview_hint'.tr(),
              style: TextStyle(fontSize: 12, color: colorScheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary card (right column) ──────────────────────────────────────────────

class _PreviewSummaryCard extends StatelessWidget {
  const _PreviewSummaryCard({required this.s});
  final PropertyFormState s;

  @override
  Widget build(BuildContext context) {
    final price = CurrencyInputFormatter.parse(s.priceText) ?? 0;

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF135BEC).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price > 0
                    ? '${CurrencyInputFormatter.format(price)} €'
                    : '— €',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'property_wizard.vat_included'.tr(),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            s.titleText.isNotEmpty ? s.titleText : 'property_wizard.no_title'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // Address
          if (s.addressText.isNotEmpty)
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    s.addressText,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          // Stats grid
          _StatsGrid(s: s),
        ],
      ),
    );
  }
}

// ─── Mortgage card ─────────────────────────────────────────────────────────────

class _PreviewMortgageCard extends StatelessWidget {
  const _PreviewMortgageCard({required this.s});
  final PropertyFormState s;

  int? get _monthlyEstimate {
    final price = CurrencyInputFormatter.parse(s.priceText) ?? 0;
    if (price <= 0) return null;
    const rate = 0.035 / 12;
    const n = 360;
    final principal = price * 0.8;
    final monthly = principal * rate / (1 - math.pow(1 + rate, -n));
    return monthly.round();
  }

  @override
  Widget build(BuildContext context) {
    final monthly = _monthlyEstimate;
    if (monthly == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_outlined,
                color: Color(0xFF135BEC), size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'property_wizard.mortgage_label'.tr(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF135BEC),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Builder(builder: (context) => Text(
                'property_wizard.mortgage_from'.tr(namedArgs: {'amount': '${CurrencyInputFormatter.format(monthly)}\u20AC'}),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stats grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.s});
  final PropertyFormState s;

  String get _surfaceLabel {
    final surface = double.tryParse(s.surfaceText) ?? 0;
    if (surface <= 0) return '— m\u00B2';
    return '${surface % 1 == 0 ? surface.toInt() : surface} m\u00B2';
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: [
        _StatItem(icon: Icons.bed, label: 'property_wizard.bedrooms_short'.tr(namedArgs: {'count': '${s.bedrooms}'})),
        _StatItem(
            icon: Icons.bathtub_outlined, label: 'property_wizard.bathrooms_short'.tr(namedArgs: {'count': '${s.bathrooms}'})),
        _StatItem(icon: Icons.square_foot, label: _surfaceLabel),
        if (s.selectedType != null)
          _StatItem(
            icon: Icons.apartment_outlined,
            label: _typeLabel(s.selectedType!.backendValue),
          ),
        if (s.hasExterior)
          _StatItem(
              icon: Icons.wb_sunny_outlined, label: 'amenity.exterior'.tr()),
        if (s.hasLift)
          _StatItem(
              icon: Icons.elevator_outlined, label: 'amenity.lift'.tr()),
        if (s.hasPool)
          _StatItem(icon: Icons.pool_outlined, label: 'amenity.pool'.tr()),
        if (s.hasGarage)
          _StatItem(icon: Icons.garage_outlined, label: 'amenity.garage'.tr()),
        if (s.hasTerrace)
          _StatItem(icon: Icons.balcony_outlined, label: 'amenity.terrace'.tr()),
      ],
    );
  }

  static String _typeLabel(String v) {
    final map = {
      'piso': 'property_wizard.type_piso'.tr(),
      'casa': 'property_wizard.type_casa'.tr(),
      'chalet': 'property_wizard.type_chalet'.tr(),
      'local': 'property_wizard.type_local'.tr(),
      'garaje': 'property_wizard.type_garaje'.tr(),
      'terreno': 'property_wizard.type_terreno'.tr(),
    };
    return map[v] ?? v;
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: colorScheme.onSurfaceVariant, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Description section ───────────────────────────────────────────────────────

class _PreviewDescriptionSection extends StatelessWidget {
  const _PreviewDescriptionSection({required this.s});
  final PropertyFormState s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(builder: (context) => Text(
          'property_wizard.about_property'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        )),
        const SizedBox(height: 12),
        Builder(builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Text(
            s.descriptionText.isNotEmpty
                ? s.descriptionText
                : 'property_wizard.no_description_preview'.tr(),
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: s.descriptionText.isNotEmpty
                  ? cs.onSurface
                  : cs.onSurfaceVariant,
            ),
          );
        }),
        if (s.descriptionText.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: null,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              foregroundColor: const Color(0xFF135BEC),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('property_wizard.read_more'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Icon(Icons.keyboard_arrow_down, size: 16),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Location / map section ────────────────────────────────────────────────────

class _PreviewLocationSection extends StatelessWidget {
  const _PreviewLocationSection({required this.location});
  final LatLng? location;

  @override
  Widget build(BuildContext context) {
    final loc = location ?? const LatLng(40.4168, -3.7038);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(builder: (context) => Text(
              'property_wizard.approx_location'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )),
            Builder(builder: (context) {
              final cs = Theme.of(context).colorScheme;
              return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cs.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 14, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(
                    'property_wizard.protected_location_badge'.tr(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            );
            }),
          ],
        ),
        const SizedBox(height: 16),
        Builder(builder: (context) => Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: loc,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.inmufacil.app',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: loc,
                          radius: 200,
                          useRadiusInMeter: true,
                          color: const Color(0xFF135BEC).withValues(alpha: 0.2),
                          borderColor: const Color(0xFF135BEC),
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      'property_wizard.location_privacy_note'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

// ─── Photo carousel ────────────────────────────────────────────────────────────

class _PreviewCarousel extends StatefulWidget {
  const _PreviewCarousel(
      {required this.mediaItems, required this.isMobile});
  final List<PropertyMediaItem> mediaItems;
  final bool isMobile;

  @override
  State<_PreviewCarousel> createState() => _PreviewCarouselState();
}

class _PreviewCarouselState extends State<_PreviewCarousel> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index.clamp(0, widget.mediaItems.length - 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.isMobile ? 300.0 : 500.0;
    final images = widget.mediaItems;
    final hasMultiple = images.length > 1;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Main image area
          ClipRRect(
            borderRadius: widget.isMobile
                ? BorderRadius.zero
                : BorderRadius.circular(16),
            child: images.isEmpty
                ? Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 48),
                    ),
                  )
                : PageView.builder(
                    controller: _controller,
                    itemCount: images.length,
                    onPageChanged: (i) =>
                        setState(() => _current = i),
                    itemBuilder: (_, i) =>
                        _MediaTile(item: images[i]),
                  ),
          ),

          // Left arrow
          if (hasMultiple && _current > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrow(
                  icon: Icons.chevron_left,
                  onPressed: () => _goTo(_current - 1),
                ),
              ),
            ),

          // Right arrow
          if (hasMultiple && _current < images.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrow(
                  icon: Icons.chevron_right,
                  onPressed: () => _goTo(_current + 1),
                ),
              ),
            ),

          // Top-right: share + favorite (decorative in preview)
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: [
                _CircleButton(
                    icon: Icons.share_outlined,
                    color: const Color(0xFF0F172A),
                    onPressed: () {}),
                const SizedBox(width: 8),
                _CircleButton(
                    icon: Icons.favorite_border,
                    color: Colors.grey.shade400,
                    onPressed: () {}),
              ],
            ),
          ),

          // Fullscreen icon (bottom-left)
          if (images.isNotEmpty)
            Positioned(
              bottom: hasMultiple ? 44 : 12,
              left: 12,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.fullscreen,
                    color: Colors.white, size: 20),
              ),
            ),

          // Dots indicator
          if (hasMultiple)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      images.length > 7 ? 7 : images.length,
                      (i) {
                        final count = images.length;
                        final dotIndex =
                            count > 7 ? (i * (count - 1) ~/ 6) : i;
                        final active = dotIndex == _current ||
                            (i == 6 && _current >= dotIndex);
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 3),
                          width: active ? 8 : 6,
                          height: active ? 8 : 6,
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white38,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

          // Watermark overlay
          if (images.isNotEmpty)
            Positioned(
              bottom: hasMultiple ? 52 : 20,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'InmuFacil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton(
      {required this.icon,
      required this.color,
      required this.onPressed});
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.item});
  final PropertyMediaItem item;

  @override
  Widget build(BuildContext context) {
    if (item.isRemote) {
      return Image.network(
        item.remoteUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (kIsWeb && item.previewBytes != null) {
      return Image.memory(item.previewBytes!,
          fit: BoxFit.cover, width: double.infinity);
    }
    if (!kIsWeb && item.xFile != null) {
      return FutureBuilder<Uint8List>(
        future: item.xFile!.readAsBytes(),
        builder: (context, snap) {
          if (snap.hasData) {
            return Image.memory(snap.data!,
                fit: BoxFit.cover, width: double.infinity);
          }
          return _placeholder();
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported,
              color: Colors.grey, size: 48),
        ),
      );
}
