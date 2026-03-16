import 'dart:io';
import 'dart:typed_data';

/// Saves [bytes] to the system temp directory as [filename].
Future<void> downloadBytes(Uint8List bytes, String filename) async {
  final file = File('${Directory.systemTemp.path}/$filename');
  await file.writeAsBytes(bytes);
}
