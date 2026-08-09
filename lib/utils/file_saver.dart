import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'file_saver_stub.dart'
  if (dart.library.io) 'file_saver_io.dart'
  if (dart.library.html) 'file_saver_web.dart';

Future<String?> saveFile(Uint8List bytes, String filename) => saveFilePlatform(bytes, filename);
