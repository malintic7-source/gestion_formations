// ignore_for_file: unused_import
import 'local_storage_stub.dart'
  if (dart.library.html) 'local_storage_web.dart';

/// Wrapper around browser localStorage when running on web.
/// On other platforms this becomes a no-op implementation.
class LocalStorage {
  String? getItem(String key) => _localStorage.getItem(key);

  void setItem(String key, String value) => _localStorage.setItem(key, value);

  void removeItem(String key) => _localStorage.removeItem(key);
}

final LocalStorage _localStorage = LocalStorage();
