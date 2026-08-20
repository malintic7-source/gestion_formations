import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> shareBytesImpl(Uint8List? bytes, String text, String filename) async {
  await Share.share(text);
}
