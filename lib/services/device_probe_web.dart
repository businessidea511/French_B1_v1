import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// What the browser says about the device.
class DeviceProbe {
  /// Signs of an older or weaker phone, or a user who asked for less motion.
  static List<String> weakSigns() {
    final signs = <String>[];
    try {
      final nav = globalContext['navigator'] as JSObject;
      final cores = (nav['hardwareConcurrency'] as JSNumber?)?.toDartInt ?? 0;
      // Chrome only: memory in GB, rounded down (0.25 … 8); 0 when unknown (Safari).
      final memory = (nav['deviceMemory'] as JSNumber?)?.toDartDouble ?? 0;
      final screen = globalContext['screen'] as JSObject;
      final shortSide = [
        (screen['width'] as JSNumber?)?.toDartInt ?? 0,
        (screen['height'] as JSNumber?)?.toDartInt ?? 0,
      ].reduce((a, b) => a < b ? a : b);
      final touch = ((nav['maxTouchPoints'] as JSNumber?)?.toDartInt ?? 0) > 0;
      final phone = touch && shortSide > 0 && shortSide < 600;
      if (memory > 0 && memory <= 3) signs.add('${memory}GB memory');
      // Few cores is a sign of an older phone; a 4-core computer with enough memory is fine.
      if (cores > 0 && cores <= 4 && (phone || (memory > 0 && memory <= 4))) signs.add('$cores cores');
      final connection = nav['connection'] as JSObject?;
      if ((connection?['saveData'] as JSBoolean?)?.toDart ?? false) signs.add('data saver');
      final media = globalContext.callMethod<JSObject>('matchMedia'.toJS, '(prefers-reduced-motion: reduce)'.toJS);
      if ((media['matches'] as JSBoolean?)?.toDart ?? false) signs.add('reduced motion');
    } catch (_) {}
    return signs;
  }
}
