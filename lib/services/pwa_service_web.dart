import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

/// Installing the web app on the phone (index.html keeps the browser's
/// install prompt in window.deferredPrompt).
class PWAService {
  static void setupInstallListener(void Function() onInstallable) {
    try {
      if (globalContext['deferredPrompt'] != null) onInstallable();
      globalContext['onAppInstallable'] = onInstallable.toJS;
    } catch (e) {
      debugPrint('PWA listener error: $e');
    }
  }

  /// true: installed. null: the learner said no. false: the browser has no
  /// install prompt to show (some browsers, or not ready yet): show the steps.
  static Future<bool?> installPWA() async {
    try {
      if (globalContext['deferredPrompt'] == null) return false;
      final result = await globalContext.callMethod<JSPromise<JSBoolean>>('installPWA'.toJS).toDart;
      return result.toDart ? true : null;
    } catch (e) {
      debugPrint('PWA install error: $e');
      return false;
    }
  }

  /// Already opened as an installed app (from the home screen).
  static bool isStandalone() {
    try {
      final media = globalContext.callMethod<JSObject>('matchMedia'.toJS, '(display-mode: standalone)'.toJS);
      if ((media['matches'] as JSBoolean?)?.toDart ?? false) return true;
      final nav = globalContext['navigator'] as JSObject;
      return (nav['standalone'] as JSBoolean?)?.toDart ?? false; // iPhone
    } catch (_) {
      return false;
    }
  }
}
