import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light design, the default for everyone: a still background, flat cards and
/// no 3D effects, so the screen is only redrawn when something changes.
/// "Full" brings back the moving background and 3D effects for strong phones.
class PerfMode extends ChangeNotifier {
  PerfMode._();
  static final instance = PerfMode._();

  static const _prefKey = 'perf_mode';
  static const on = 'on', off = 'off';

  String choice = on;

  /// Read everywhere an effect is drawn.
  static bool get light => instance.isLight;

  bool get isLight => choice != off;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only an explicit "full" keeps the effects; the old "auto" becomes light.
      choice = prefs.getString(_prefKey) == off ? off : on;
    } catch (_) {}
    debugPrint('⚡ Light mode: $isLight');
  }

  Future<void> set(String value) async {
    choice = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, value);
    } catch (_) {}
  }

  @visibleForTesting
  void reset() => choice = on;
}
