import 'package:flutter/widgets.dart';

class GlobalScrollManager {
  static final List<ScrollController> _controllers = [];

  static void register(ScrollController controller) {
    if (!_controllers.contains(controller)) {
      _controllers.add(controller);
    }
  }

  static void unregister(ScrollController controller) {
    _controllers.remove(controller);
  }

  /// The page on screen. Tabs that are kept but hidden have their tickers off,
  /// so they are skipped.
  static ScrollController? get activeController {
    for (final controller in _controllers.reversed) {
      if (!controller.hasClients) continue;
      final context = controller.position.context.storageContext;
      if (!context.mounted || !TickerMode.getValuesNotifier(context).value.enabled) continue;
      return controller;
    }
    return null;
  }
}
