/// Speech-to-text is only wired up for the web build (browser speech recognition).
class SpeechInput {
  static bool get supported => false;

  bool start({
    required void Function(String text, bool isFinal) onText,
    required void Function() onEnd,
    void Function(String error)? onError,
  }) =>
      false;

  void stop() {}
}
