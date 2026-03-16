// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

typedef FileDropCallback = void Function(Uint8List bytes, String filename);

/// Flutter Web drop zone. Renders a dashed rectangle that accepts native
/// OS file drops and calls [onDrop] with the file bytes + filename.
///
/// The HtmlElementView only covers this widget's area, so Flutter widgets
/// outside (e.g. buttons above this widget) are not affected.
class FileDropZone extends StatefulWidget {
  const FileDropZone({super.key, required this.onDrop});
  final FileDropCallback onDrop;

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  static int _counter = 0;
  late final String _viewId;
  bool _isDragOver = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'post-venta-drop-${_counter++}';

    final div = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.cursor = 'copy';

    div.addEventListener('dragenter', (event) {
      event.preventDefault();
      if (mounted) setState(() => _isDragOver = true);
    });
    div.addEventListener('dragover', (event) {
      event.preventDefault();
    });
    div.addEventListener('dragleave', (event) {
      if (mounted) setState(() => _isDragOver = false);
    });
    div.addEventListener('drop', (event) {
      event.preventDefault();
      if (mounted) setState(() => _isDragOver = false);
      final files = (event as html.MouseEvent).dataTransfer.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoad.listen((_) {
        if (mounted) {
          widget.onDrop(
            Uint8List.fromList(reader.result as List<int>),
            file.name,
          );
        }
      });
    });

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => div);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF2563EB);
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _isDragOver
            ? accent.withValues(alpha: 0.08)
            : accent.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isDragOver ? accent : accent.withValues(alpha: 0.3),
          width: _isDragOver ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Visual hint — rendered below the HTML overlay
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.upload_outlined,
                  size: 15,
                  color: accent.withValues(alpha: _isDragOver ? 1.0 : 0.45),
                ),
                const SizedBox(width: 6),
                Text(
                  _isDragOver
                      ? 'Suelta el archivo aqui'
                      : 'Arrastra un archivo aqui  (PDF, JPG, PNG)',
                  style: TextStyle(
                    fontSize: 12,
                    color: accent.withValues(alpha: _isDragOver ? 1.0 : 0.45),
                  ),
                ),
              ],
            ),
          ),
          // Transparent HTML element that captures native file-drag events
          Positioned.fill(child: HtmlElementView(viewType: _viewId)),
        ],
      ),
    );
  }
}
