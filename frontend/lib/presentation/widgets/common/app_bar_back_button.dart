import 'package:flutter/material.dart';

/// Back button for AppBars.
/// Default: transparent background, blue arrow.
/// Hover/Press: blue circle (#135BEC) + white arrow.
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
  bool _pressed = false;

  static const _blue = Color(0xFF135BEC);

  bool get _active => _hovered || _pressed;

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
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _active ? _blue : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: _active
                  ? [
                      BoxShadow(
                        color: _blue.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: _active ? Colors.white : _blue,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cancel / close button for AppBars.
/// White circle by default; animates to red (#DC2626) on hover/press.
/// Matches the red cancel buttons used throughout the app.
class AppBarCloseButton extends StatefulWidget {
  const AppBarCloseButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Cancelar',
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  State<AppBarCloseButton> createState() => _AppBarCloseButtonState();
}

class _AppBarCloseButtonState extends State<AppBarCloseButton> {
  bool _hovered = false;

  static const _red = Color(0xFFDC2626);
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
              color: _hovered ? _red : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: _red.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
              border: _hovered
                  ? Border.all(
                      color: _red,
                      width: 1,
                    )
                  : null,
            ),
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: _hovered ? Colors.white : _dark,
            ),
          ),
        ),
      ),
    );
  }
}
