import 'dart:js_interop';

@JS('malinticActivateTabSession')
external void _activateTabSession();

@JS('malinticDeactivateTabSession')
external void _deactivateTabSession();

class TabSessionLifecycle {
  static void activate() {
    _activateTabSession();
  }

  static void deactivate() {
    _deactivateTabSession();
  }
}
