import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/temp_translations.dart';
import '../../../providers/property_form_provider.dart';

class PropertyStep3PhotosExtras extends ConsumerWidget {
  const PropertyStep3PhotosExtras({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(propertyFormProvider);
    final notifier = ref.read(propertyFormProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Extras card (FIRST) ───────────────────────────────────────────
          _SectionCard(
            icon: Icons.star_outline_rounded,
            title: 'property_wizard.extras_card'.tr(),
            child: _AmenitiesGrid(s: s, notifier: notifier),
          ),
          const SizedBox(height: 16),

          // ── Visitas card ───────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.calendar_month_outlined,
            title: 'property_wizard.visits_card'.tr(),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'property_wizard.allow_visits_label'.tr(),
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                'property_wizard.allow_visits_hint'.tr(),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              value: s.allowVisits,
              onChanged: (_) => notifier.toggleAllowVisits(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Fotos card (SECOND) ───────────────────────────────────────────
          _SectionCard(
            icon: Icons.photo_library_outlined,
            title: 'property_wizard.photos_card'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Counter row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'property_wizard.photos_hint'.tr(),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      '${s.visibleMedia.length} / $kMaxPhotos',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: s.remainingPhotoSlots == 0
                            ? const Color(0xFFDC2626)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Grid: [Add tile] + [photo tiles] with drag-reorder
                _PhotoGrid(
                  items: s.visibleMedia,
                  canAddMore: s.remainingPhotoSlots > 0,
                  onAdd: notifier.pickImages,
                  onRemove: (item) => item.isLocal
                      ? notifier.removeLocalImage(item.localId)
                      : notifier.markRemoteImageForDeletion(item.localId),
                  onReorder: notifier.reorderMedia,
                ),

                // Drag hint — always visible
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.drag_indicator_outlined,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'property_wizard.drag_hint'.tr(),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
                if (s.step3Error != null) ...[
                  const SizedBox(height: 10),
                  _ErrorBanner(message: s.step3Error!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Photo grid — horizontal scrollable row with drag reorder ─────────────────

class _PhotoGrid extends StatefulWidget {
  const _PhotoGrid({
    required this.items,
    required this.canAddMore,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });

  final List<PropertyMediaItem> items;
  final bool canAddMore;
  final VoidCallback onAdd;
  final void Function(PropertyMediaItem) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  State<_PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<_PhotoGrid> {
  int? _draggingIndex;
  int? _hoverIndex;

  static const double _tileSize = 160;
  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Añadir fotos" tile — always first when canAddMore
          if (widget.canAddMore) ...[
            GestureDetector(
              onTap: widget.onAdd,
              child: const _AddPhotoTile(size: _tileSize),
            ),
            const SizedBox(width: _spacing),
          ],

          // Photo tiles with drag-and-drop
          for (int i = 0; i < widget.items.length; i++) ...[
            DragTarget<int>(
              onWillAcceptWithDetails: (details) => details.data != i,
              onAcceptWithDetails: (details) {
                final from = details.data;
                widget.onReorder(from, i);
                setState(() {
                  _draggingIndex = null;
                  _hoverIndex = null;
                });
              },
              onMove: (_) => setState(() => _hoverIndex = i),
              onLeave: (_) => setState(() => _hoverIndex = null),
              builder: (context, candidateData, rejectedData) {
                final isHovered = _hoverIndex == i && candidateData.isNotEmpty;
                return LongPressDraggable<int>(
                  data: i,
                  delay: const Duration(milliseconds: 300),
                  onDragStarted: () => setState(() => _draggingIndex = i),
                  onDragEnd: (_) => setState(() {
                    _draggingIndex = null;
                    _hoverIndex = null;
                  }),
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.85,
                      child: SizedBox(
                        width: _tileSize,
                        height: _tileSize,
                        child: _MediaTile(
                          item: widget.items[i],
                          onRemove: () {},
                          showRemove: false,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    width: _tileSize,
                    height: _tileSize,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _tileSize,
                    height: _tileSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: isHovered
                          ? Border.all(
                              color: const Color(0xFF2563EB), width: 2)
                          : null,
                    ),
                    child: _MediaTile(
                      item: widget.items[i],
                      onRemove: () => widget.onRemove(widget.items[i]),
                      showRemove: _draggingIndex == null,
                    ),
                  ),
                );
              },
            ),
            if (i < widget.items.length - 1)
              const SizedBox(width: _spacing),
          ],
        ],
      ),
    );
  }
}

// ─── "AÑADIR FOTOS" tile (dashed border — matches HTML reference) ─────────────

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          // border-primary/40  →  #2563EB at 40% opacity
          color: const Color(0xFF2563EB).withOpacity(0.4),
          strokeWidth: 2,
          dashLength: 7,
          gapLength: 5,
          radius: 12,
        ),
        child: Container(
          decoration: BoxDecoration(
            // bg-primary/5  →  #2563EB at 5% opacity
            color: const Color(0xFF2563EB).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // add_a_photo  →  Icons.add_a_photo (filled)
              const Icon(
                Icons.add_a_photo,
                color: Color(0xFF2563EB),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'property_wizard.add_photos'.tr(),
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dashed border painter ────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
            strokeWidth / 2,
            strokeWidth / 2,
            size.width - strokeWidth,
            size.height - strokeWidth),
        Radius.circular(radius),
      ));

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength ||
      old.radius != radius;
}

// ─── Media tile ──────────────────────────────────────────────────────────────

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.item,
    required this.onRemove,
    this.showRemove = true,
  });
  final PropertyMediaItem item;
  final VoidCallback onRemove;
  final bool showRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildImage(),
        ),
        if (showRemove)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 13),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    if (item.isRemote && item.remoteUrl != null) {
      return Image.network(item.remoteUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _Placeholder());
    }
    if (kIsWeb && item.previewBytes != null) {
      return Image.memory(item.previewBytes!, fit: BoxFit.cover);
    }
    if (!kIsWeb && item.xFile != null) {
      return Image.file(File(item.xFile!.path), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _Placeholder());
    }
    return const _Placeholder();
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_outlined, color: Colors.grey),
      );
}

// ─── Amenities grid ──────────────────────────────────────────────────────────

class _AmenitiesGrid extends StatelessWidget {
  const _AmenitiesGrid({required this.s, required this.notifier});
  final PropertyFormState s;
  final PropertyFormNotifier notifier;

  static const _amenities = [
    ('pool', Icons.pool_outlined),
    ('garage', Icons.garage_outlined),
    ('terrace', Icons.deck_outlined),
    ('garden', Icons.park_outlined),
    ('lift', Icons.elevator_outlined),
    ('ac', Icons.ac_unit_outlined),
    ('heating', Icons.whatshot_outlined),
    ('storage', Icons.inventory_2_outlined),
    ('wardrobes', Icons.door_sliding_outlined),
    ('exterior', Icons.wb_sunny_outlined),
    ('accessibility', Icons.accessible_outlined),
  ];

  bool _val(String key) {
    switch (key) {
      case 'pool': return s.hasPool;
      case 'garage': return s.hasGarage;
      case 'terrace': return s.hasTerrace;
      case 'garden': return s.hasGarden;
      case 'lift': return s.hasLift;
      case 'ac': return s.hasAC;
      case 'heating': return s.hasHeating;
      case 'storage': return s.hasStorage;
      case 'wardrobes': return s.hasWardrobes;
      case 'exterior': return s.hasExterior;
      case 'accessibility': return s.hasAccessibility;
      default: return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _amenities.map((entry) {
        final (key, icon) = entry;
        final label = 'amenity.$key'.tr();
        final selected = _val(key);
        return FilterChip(
          avatar: Icon(icon,
              size: 16,
              color: selected ? Colors.white : Colors.grey.shade600),
          label: Text(label, style: const TextStyle(fontSize: 13)),
          selected: selected,
          onSelected: (_) => notifier.toggleAmenity(key),
          selectedColor: const Color(0xFF2563EB),
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: Colors.white,
          checkmarkColor: Colors.white,
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF2563EB)
                  : Colors.grey.shade300,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF87171)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Color(0xFFDC2626), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
