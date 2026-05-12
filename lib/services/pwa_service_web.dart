// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class PWAService {
  static void setupInstallListener(void Function() onInstallable) {
    try {
      // Direct global context access
      if (js.context.hasProperty('deferredPrompt') && js.context['deferredPrompt'] != null) {
        onInstallable();
      }
      
      js.context['onAppInstallable'] = () {
        onInstallable();
      };
    } catch (e) {
      debugPrint("🚀 PWA Web Listener Error: $e");
    }
  }

  static Future<bool> installPWA() async {
    try {
      final result = await js.context.callMethod('installPWA');
      return result == true;
    } catch (e) {
      debugPrint("🚀 PWA Web Install Error: $e");
      return false;
    }
  }

  static bool isStandalone() {
    try {
      final navigator = js.context['navigator'];
      if (navigator != null && js.JsObject.fromBrowserObject(navigator).hasProperty('standalone')) {
        return navigator['standalone'] == true;
      }
    } catch (e) {
      debugPrint("📱 PWA Standalone check error: $e");
    }
    return false;
  }
}
