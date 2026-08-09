import 'dart:typed_data';
import 'package:gal/gal.dart';

Future<String?> saveFilePlatform(Uint8List bytes, String filename) async {
  try {
    await Gal.putImageBytes(bytes, name: filename);
    return filename;
  } catch (_) {
    return null;
  }
}
