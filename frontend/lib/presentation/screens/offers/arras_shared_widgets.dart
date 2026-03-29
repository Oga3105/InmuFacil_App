import 'package:flutter/material.dart';

const kArrasBlue  = Color(0xFF135BEC);
const kArrasGreen = Color(0xFF16A34A);
// Note: for dark mode, prefer colorScheme.primary over kArrasBlue in build methods.

class ArrasStepIndicator extends StatelessWidget {
  const ArrasStepIndicator({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: colorScheme.onPrimaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(total, (i) {
          final done = i < current;
          final active = i == current;
          final greenColor = isDark ? const Color(0xFF4ADE80) : kArrasGreen;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: done ? greenColor : Colors.white24,
                    ),
                  ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? greenColor
                        : active
                            ? Colors.white
                            : Colors.white24,
                    border: Border.all(
                      color: done
                          ? greenColor
                          : active
                              ? Colors.white
                              : Colors.white24,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: active
                                ? colorScheme.onPrimaryContainer
                                : Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (i < total - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: done ? greenColor : Colors.white24,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class ArrasBottomBar extends StatelessWidget {
  const ArrasBottomBar({
    super.key,
    required this.page,
    required this.onPrev,
    required this.onNext,
    required this.onConfirm,
    required this.confirmLabel,
    this.loading = false,
  });

  final int page;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onConfirm;
  final String confirmLabel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          if (page > 0)
            OutlinedButton(
              onPressed: onPrev,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Atras', style: TextStyle(color: Colors.grey.shade700)),
            ),
          const Spacer(),
          if (page < 2)
            FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              ),
              child: Text('Continuar', style: TextStyle(color: colorScheme.onPrimary)),
            )
          else
            FilledButton.icon(
              onPressed: onConfirm,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(confirmLabel),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF4ADE80) : kArrasGreen,
                disabledBackgroundColor: colorScheme.onSurfaceVariant.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class ArrasPageHeader extends StatelessWidget {
  const ArrasPageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class ArrasInterviewCard extends StatelessWidget {
  const ArrasInterviewCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class ArrasSwitchTile extends StatelessWidget {
  const ArrasSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colorScheme.onPrimaryContainer)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: colorScheme.primary,
        ),
      ],
    );
  }
}

class ArrasMethodTile extends StatelessWidget {
  const ArrasMethodTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary.withValues(alpha: 0.06) : Colors.transparent,
          border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outlineVariant,
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (selected) Icon(Icons.check_circle, color: colorScheme.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
