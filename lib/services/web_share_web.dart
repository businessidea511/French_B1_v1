import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// The phone's share sheet (WhatsApp, Messages…) through the browser's Web Share API.
class WebShare {
  static JSObject? get _navigator => globalContext['navigator'] as JSObject?;

  static bool get supported {
    try {
      return _navigator?.has('share') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// True when the share sheet opened (even if the user then closed it).
  static Future<bool> share(String text) async {
    try {
      final data = JSObject()..['text'] = text.toJS;
      await _navigator!.callMethod<JSPromise<JSAny?>>('share'.toJS, data).toDart;
      return true;
    } catch (e) {
      return '$e'.contains('AbortError');
    }
  }
}
