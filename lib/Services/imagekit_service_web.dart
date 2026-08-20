import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class ImageKitService {
  Future<String?> pickAndUploadImage({String folder = 'formations'}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final platformFile = result.files.first;
    if (platformFile.bytes == null) return null;
    return uploadImageFromBytes(platformFile.bytes!, folder: folder, fileName: platformFile.name);
  }

  String _getMimeType(String? name) {
    final ext = (name ?? '').split('.').last.toLowerCase();
    if (ext == 'png') return 'image/png';
    if (ext == 'jpg' || ext == 'jpeg') return 'image/jpeg';
    if (ext == 'webp') return 'image/webp';
    if (ext == 'gif') return 'image/gif';
    if (ext == 'svg') return 'image/svg+xml';
    return 'image/png';
  }

  Future<String?> uploadImageFromBytes(
    List<int> bytes, {
    String folder = 'formations',
    String? fileName,
  }) async {
    final mime = _getMimeType(fileName);
    final base64Str = base64Encode(bytes);
    return 'data:$mime;base64,$base64Str';
  }

  Future<String?> uploadImage(dynamic _) async {
    throw UnsupportedError('uploadImage(File) is not supported on web. Use uploadImageFromBytes.');
  }
}
