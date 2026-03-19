import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Renders informational "zone chip" cards for AI-recommended twin zones.
///
/// This widget displays a conceptual overlay of recommended areas in the
/// discovery flow. Full flutter_map tile integration is out of scope here;
/// the component shows zone metadata as expandable chips below the map.
///
/// Usage:
///   TwinZoneMapLayer(twinZones: zones)
///
/// Each entry in [twinZones] is expected to contain:
///   - 'name'      (String)  — display name of the zone
///   - 'advantage' (String)  — key lifestyle advantage vs the searched zone
///   - 'delta_pct' (num)     — percentage improvement (e.g. 12 => "12%")
class TwinZoneMapLayer extends StatelessWidget {
  const TwinZoneMapLayer({super.key, required this.twinZones});

  final List<Map<String, dynamic>> twinZones;

  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    if (twinZones.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'discovery.twin_zones.header'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: twinZones.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _ZoneChipCard(zone: twinZones[index]);
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ZoneChipCard extends StatelessWidget {
  const _ZoneChipCard({required this.zone});

  final Map<String, dynamic> zone;

  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final name = zone['name'] as String? ?? '';
    final advantage = zone['advantage'] as String? ?? '';
    final deltaPct = zone['delta_pct'] as num? ?? 0;

    final tooltipText = 'discovery.twin_zones.tooltip_template'
        .tr(namedArgs: {
          'pct': deltaPct.toString(),
          'advantage': advantage,
        });

    return Tooltip(
      message: tooltipText,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _green,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                advantage,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'discovery.twin_zones.ai_label'.tr(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _green,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
