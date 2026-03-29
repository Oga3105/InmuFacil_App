import 'package:flutter/material.dart';

/// Public shared widget for displaying how long a property has been listed.
/// Shows a pill-shaped badge with a clock icon and color-coded text based on age.
/// Optionally shows an "Actualizado" subtitle if the listing was modified.
///
/// Usage:
///   PropertyTimeBadge(createdAt: property.createdAt, updatedAt: property.updatedAt)
class PropertyTimeBadge extends StatelessWidget {

  const PropertyTimeBadge({
    super.key,
    this.createdAt,
    this.updatedAt,
    this.large = false,
  });
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// If true, uses slightly larger font (for detail screens).
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (createdAt == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final diff = now.difference(createdAt!);
    final style = _getBadgeStyle(diff);
    final timeText = _formatDuration(diff);

    // Show "updated" subtitle only if updatedAt is meaningfully later than createdAt
    final showUpdated =
        updatedAt != null && updatedAt!.difference(createdAt!).inMinutes > 60;
    final updatedText =
        showUpdated ? _formatDuration(now.difference(updatedAt!)) : null;

    final double iconSize = large ? 14 : 13;
    final double prefixSize = large ? 12 : 11;
    final double timeSize = large ? 12 : 11;
    final double updatedSize = large ? 11 : 10;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: style.bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: style.borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: iconSize, color: style.iconColor),
              const SizedBox(width: 5),
              if (style.prefix != null) ...[
                Text(
                  style.prefix!,
                  style: TextStyle(
                    fontSize: prefixSize,
                    fontWeight: FontWeight.w800,
                    color: style.textColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                timeText,
                style: TextStyle(
                  fontSize: timeSize,
                  fontWeight: FontWeight.w600,
                  color: style.textColor,
                ),
              ),
              if (updatedText != null) ...[
                Text(
                  '  ·  Actualizado hace $updatedText',
                  style: TextStyle(
                    fontSize: updatedSize,
                    fontStyle: FontStyle.italic,
                    color: style.textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  _BadgeStyle _getBadgeStyle(Duration diff) {
    if (diff.inHours < 24) {
      return const _BadgeStyle(
        prefix: 'NUEVO:',
        bgColor: Color(0xFFEFF6FF),
        borderColor: Color(0xFFBFDBFE),
        iconColor: Color(0xFF135BEC),
        textColor: Color(0xFF135BEC),
      );
    } else if (diff.inDays < 8) {
      return const _BadgeStyle(
        prefix: 'RECIENTE:',
        bgColor: Color(0xFFF0FDF4),
        borderColor: Color(0xFFBBF7D0),
        iconColor: Color(0xFF16A34A),
        textColor: Color(0xFF15803D),
      );
    } else if (diff.inDays < 31) {
      return const _BadgeStyle(
        prefix: null,
        bgColor: Color(0xFFFFF7ED),
        borderColor: Color(0xFFFED7AA),
        iconColor: Color(0xFFEA580C),
        textColor: Color(0xFFC2410C),
      );
    } else {
      return const _BadgeStyle(
        prefix: null,
        bgColor: Color(0xFFF9FAFB),
        borderColor: Color(0xFFE5E7EB),
        iconColor: Color(0xFF9CA3AF),
        textColor: Color(0xFF6B7280),
      );
    }
  }

  String _formatDuration(Duration diff) {
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'hace ${m == 0 ? 'unos minutos' : '$m min'}';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'hace $h ${h == 1 ? 'hora' : 'horas'}';
    } else if (diff.inDays < 7) {
      final d = diff.inDays;
      return 'hace $d ${d == 1 ? 'día' : 'días'}';
    } else if (diff.inDays < 31) {
      final w = (diff.inDays / 7).floor();
      return 'hace $w ${w == 1 ? 'semana' : 'semanas'}';
    } else if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor();
      return 'hace $mo ${mo == 1 ? 'mes' : 'meses'}';
    } else {
      final y = (diff.inDays / 365).floor();
      return 'hace $y ${y == 1 ? 'año' : 'años'}';
    }
  }
}

class _BadgeStyle {

  const _BadgeStyle({
    required this.prefix,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });
  final String? prefix;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
}
