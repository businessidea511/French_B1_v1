/// The system share sheet is only wired up for the web build.
class WebShare {
  static bool get supported => false;
  static Future<bool> share(String text) async => false;
}
