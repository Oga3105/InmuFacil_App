import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:inmufacil_frontend/presentation/providers/verification_provider.dart';

/// Dashed border painter for upload containers
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    this.color = const Color(0xFFCBD5E1),
    this.strokeWidth = 1.5,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
    this.radius = 12.0,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// L-shape corner mark painter
class CornerMarkPainter extends CustomPainter {
  CornerMarkPainter({this.color = const Color(0xFF135BEC), this.length = 20, this.strokeWidth = 2.5});

  final Color color;
  final double length;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, length), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(length, 0), paint);
    canvas.drawLine(Offset(size.width - length, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);
    canvas.drawLine(Offset(0, size.height - length), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(Offset(size.width - length, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - length), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DocumentUploadCard extends StatelessWidget {

  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.onTap,
    this.imageFile,
    this.imageBytes,
    required this.status,
    this.compact = false,
  });
  final String title;
  final VoidCallback onTap;
  /// Native platforms: File reference
  final File? imageFile;
  /// Web: raw bytes for preview
  final Uint8List? imageBytes;
  final UploadStatus status;
  final bool compact;

  bool get _hasImage => imageBytes != null || imageFile != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    final height = compact ? 200.0 : 220.0;

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _hasImage ? null : DashedBorderPainter(
          color: colorScheme.outlineVariant,
          radius: 12,
        ),
        child: CustomPaint(
          painter: _hasImage ? null : CornerMarkPainter(color: colorScheme.primary),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: _hasImage ? null : colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: _hasImage
                  ? Border.all(color: greenColor, width: 2)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildImage(),
                  ),

                if (!_hasImage)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: compact ? 36 : 48,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 13 : 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toca para escanear',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                if (status == UploadStatus.picking)
                  const CircularProgressIndicator(),

                if (_hasImage)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle, color: greenColor, size: 24),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (kIsWeb && imageBytes != null) {
      return Image.memory(
        imageBytes!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }
    if (!kIsWeb && imageFile != null) {
      return Image.file(
        imageFile!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return const SizedBox.shrink();
  }
}
