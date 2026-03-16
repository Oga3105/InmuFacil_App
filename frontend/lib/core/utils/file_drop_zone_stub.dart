import 'dart:typed_data';

import 'package:flutter/material.dart';

typedef FileDropCallback = void Function(Uint8List bytes, String filename);

/// Non-web stub — renders nothing (mobile/desktop use the file picker instead).
class FileDropZone extends StatelessWidget {
  const FileDropZone({super.key, required this.onDrop});
  final FileDropCallback onDrop;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
