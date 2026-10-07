import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_probe.dart';

/// Light mode for older phones: a still background, no 3D effects and no
/// entrance animations. "Auto" turns it on when the device looks weak.
class PerfMode extends ChangeNotifier {
  PerfMode._();
  static final instance = PerfMode._();

  static const _prefKey = 'perf_mode';
  static const auto = 'auto', on = 'on', off = 'off';

  String choice = auto;
  List<String> weakSigns = const [];

  /// Read everywhere an effect is drawn.
  static bool get light => instance.isLight;

  bool get isLight => choice == on || (choice == auto && weakSigns.isNotEmpty);

  Future<void> load() async {
    weakSigns = DeviceProbe.weakSigns();
    try {
      final prefs = await SharedPreferences.getInstance();
      choice = prefs.getString(_prefKey) ?? auto;
    } catch (_) {}
    debugPrint('⚡ Light mode: $isLight ($choice; ${weakSigns.join(', ')})');
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
  void reset() {
    choice = auto;
    weakSigns = const [];
  }
}
