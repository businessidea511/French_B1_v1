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

  static ScrollController? get activeController {
    for (final controller in _controllers.reversed) {
      if (controller.hasClients) {
        return controller;
      }
    }
    return null;
  }
}
