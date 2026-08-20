import 'dart:typed_data';

import 'share_helper_io.dart' if (dart.library.html) 'share_helper_web.dart';

Future<void> shareBytes(Uint8List? bytes, String text, String filename) async {
  await shareBytesImpl(bytes, text, filename);
}
