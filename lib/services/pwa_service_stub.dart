abstract class PWAService {
  static void setupInstallListener(void Function() onInstallable) {}
  static Future<bool> installPWA() async => false;
  static bool isStandalone() => false;
}
