import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareBytesImpl(Uint8List? bytes, String text, String filename) async {
  if (bytes == null) {
    await Share.share(text);
    return;
  }

  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], text: text);
}
