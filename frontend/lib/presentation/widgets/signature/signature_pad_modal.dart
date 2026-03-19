import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Stroke model
// ---------------------------------------------------------------------------

class _Stroke {
  _Stroke(this.color, this.width);

  final Color color;
  final double width;
  final List<Offset> points = [];
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.strokes);

  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => old.strokes != strokes;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Result returned when the user confirms the signature.
class SignatureResult {
  const SignatureResult({
    required this.strokesJson,
    required this.isEmpty,
  });

  /// JSON-encoded list of strokes for backend verification.
  final String strokesJson;
  final bool isEmpty;
}

/// Shows the signature pad as a bottom sheet.
///
/// Returns [SignatureResult] or null if dismissed.
Future<SignatureResult?> showSignaturePadModal(BuildContext context) {
  return showModalBottomSheet<SignatureResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SignaturePadSheet(),
  );
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

class _SignaturePadSheet extends StatefulWidget {
  const _SignaturePadSheet();

  @override
  State<_SignaturePadSheet> createState() => _SignaturePadSheetState();
}

class _SignaturePadSheetState extends State<_SignaturePadSheet> {
  final List<_Stroke> _strokes = [];
  _Stroke? _current;

  bool get _isEmpty => _strokes.every((s) => s.points.isEmpty);

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _current = _Stroke(const Color(0xFF1E293B), 2.5);
      _current!.points.add(d.localPosition);
      _strokes.add(_current!);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_current == null) return;
    setState(() => _current!.points.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    _current = null;
  }

  void _clear() => setState(() => _strokes.clear());

  String _encodeStrokes() {
    final data = _strokes
        .where((s) => s.points.isNotEmpty)
        .map((s) => s.points.map((p) => [p.dx, p.dy]).toList())
        .toList();
    return jsonEncode(data);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.draw_outlined, color: Color(0xFF2563EB), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'signature.pad_title'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text('signature.clear'.tr()),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Canvas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: _SignaturePainter(_strokes),
                      child: _isEmpty
                          ? Center(
                              child: Text(
                                'signature.pad_hint'.tr(),
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Legal notice
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'signature.legal_notice'.tr(),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('common.cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isEmpty
                          ? null
                          : () {
                              Navigator.of(context).pop(
                                SignatureResult(
                                  strokesJson: _encodeStrokes(),
                                  isEmpty: false,
                                ),
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                      child: Text('signature.confirm'.tr()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
