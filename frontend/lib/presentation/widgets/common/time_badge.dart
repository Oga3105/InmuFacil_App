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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final diff = now.difference(createdAt!);
    final style = _getBadgeStyle(diff, isDark, colorScheme);
    final timeText = _formatDuration(diff);

    final showUpdated =
        updatedAt != null && updatedAt!.difference(createdAt!).inMinutes > 60;
    final updatedText =
        showUpdated ? _formatDuration(now.difference(updatedAt!)) : null;

    final double iconSize = large ? 14 : 13;
    final double prefixSize = large ? 12 : 11;
    final double timeSize = large ? 12 : 11;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        // Pill 1: fecha de publicacion
        _buildPill(
          icon: Icons.history_rounded,
          iconSize: iconSize,
          prefix: style.prefix,
          prefixSize: prefixSize,
          text: timeText,
          textSize: timeSize,
          bgColor: style.bgColor,
          borderColor: style.borderColor,
          iconColor: style.iconColor,
          textColor: style.textColor,
        ),
        // Pill 2: ultima actualizacion (solo si difiere > 60 min de la creacion)
        if (updatedText != null)
          Builder(builder: (context) {
            final updatedDiff = DateTime.now().difference(updatedAt!);
            final updStyle = _getBadgeStyle(updatedDiff, isDark, colorScheme);
            return _buildPill(
              icon: Icons.update_rounded,
              iconSize: iconSize,
              prefix: 'Actualización',
              prefixSize: prefixSize,
              text: updatedText,
              textSize: timeSize,
              bgColor: updStyle.bgColor,
              borderColor: updStyle.borderColor,
              iconColor: updStyle.iconColor,
              textColor: updStyle.textColor,
            );
          },),
      ],
    );
  }

  Widget _buildPill({
    required IconData icon,
    required double iconSize,
    required String? prefix,
    required double prefixSize,
    required String text,
    required double textSize,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
          const SizedBox(width: 5),
          if (prefix != null) ...[
            Text(
              prefix,
              style: TextStyle(
                fontSize: prefixSize,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeStyle _getBadgeStyle(Duration diff, bool isDark, ColorScheme cs) {
    if (diff.inHours < 24) {
      return _BadgeStyle(
        prefix: 'Publicación',
        bgColor: isDark ? const Color(0xFF0A1628) : const Color(0xFFEFF6FF),
        borderColor: isDark ? const Color(0xFF1E3A6E) : const Color(0xFFBFDBFE),
        iconColor: cs.primary,
        textColor: cs.primary,
      );
    } else if (diff.inDays < 8) {
      return _BadgeStyle(
        prefix: 'Publicación',
        bgColor: isDark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4),
        borderColor: isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0),
        iconColor: const Color(0xFF16A34A),
        textColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
      );
    } else if (diff.inDays < 31) {
      return _BadgeStyle(
        prefix: 'Publicación',
        bgColor: isDark ? const Color(0xFF2A1500) : const Color(0xFFFFF7ED),
        borderColor: isDark ? const Color(0xFF92400E) : const Color(0xFFFED7AA),
        iconColor: isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
        textColor: isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C),
      );
    } else {
      return _BadgeStyle(
        prefix: 'Publicación',
        bgColor: cs.surfaceContainerHighest,
        borderColor: cs.outlineVariant,
        iconColor: cs.onSurfaceVariant,
        textColor: cs.onSurfaceVariant,
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
