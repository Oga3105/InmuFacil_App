import 'package:flutter/material.dart';

/// Back button for AppBars — same hover style as the property navigation arrows.
/// White circle by default; animates to brand blue (#135BEC) on hover/press.
class AppBarBackButton extends StatefulWidget {
  const AppBarBackButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Volver',
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  State<AppBarBackButton> createState() => _AppBarBackButtonState();
}

class _AppBarBackButtonState extends State<AppBarBackButton> {
  bool _hovered = false;

  static const _blue = Color(0xFF135BEC);
  static const _dark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered ? _blue : Colors.white.withOpacity(0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _hovered
                      ? _blue.withOpacity(0.35)
                      : Colors.black.withOpacity(0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: _hovered ? _blue : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: _hovered ? Colors.white : _dark,
            ),
          ),
        ),
      ),
    );
  }
}
