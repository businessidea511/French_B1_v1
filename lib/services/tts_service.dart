import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts flutterTts = FlutterTts();

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("fr-FR");
    await flutterTts.setSpeechRate(0.9); // Normal conversation speed
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> setRate(double rate) async {
    await flutterTts.setSpeechRate(rate);
  }

  Future<void> speak(String text) async {
    await flutterTts.stop(); // Stop any previous speech
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await flutterTts.stop();
  }

  Future<void> pause() async {
    await flutterTts.pause();
  }
}
