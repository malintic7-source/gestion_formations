// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

class LocalStorage {
  String? getItem(String key) => html.window.localStorage[key];

  void setItem(String key, String value) => html.window.localStorage[key] = value;

  void removeItem(String key) => html.window.localStorage.remove(key);
}
