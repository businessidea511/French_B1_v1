abstract class PWAService {
  static void setupInstallListener(void Function() onInstallable) {}

  /// true: installed. false: the browser showed nothing (show the steps).
  static Future<bool?> installPWA() async => false;
  static bool isStandalone() => false;
}
