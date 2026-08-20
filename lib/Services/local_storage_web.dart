// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

class LocalStorage {
  String? getItem(String key) => html.window.localStorage[key];

  void setItem(String key, String value) => html.window.localStorage[key] = value;

  void removeItem(String key) => html.window.localStorage.remove(key);

  // SessionStorage (effacé à la fermeture d'onglet, conservé au rafraîchissement F5)
  String? getSessionItem(String key) => html.window.sessionStorage[key];

  void setSessionItem(String key, String value) => html.window.sessionStorage[key] = value;

  void removeSessionItem(String key) => html.window.sessionStorage.remove(key);
}
