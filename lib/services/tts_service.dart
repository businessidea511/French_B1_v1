import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'hugging_face_tts_service.dart';

class TtsService {
  /// Shared French voice for small "listen" buttons across the app.
  static final TtsService instance = TtsService();

  final FlutterTts flutterTts = FlutterTts();
  AudioPlayer? _neuralPlayer;

  /// The French voice picked on this device; null = not found (yet).
  static Map<String, String>? _frenchVoice;
  static bool _noFrenchVoice = false;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await flutterTts.setSpeechRate(0.9); // Normal conversation speed
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS not available: $e');
    }
  }

  Future<void> setRate(double rate) async {
    await flutterTts.setSpeechRate(rate);
  }

  /// The French to read aloud: drops explanations in brackets
  /// ("Je parle à mon ami. (COI : à qui ?)" → "Je parle à mon ami."),
  /// gender marks ("allé(e)s" → "allés") and arrows or emojis.
  static String speakableText(String text) => text
      .replaceAll(RegExp(r'\([^)]*\)'), '')
      .replaceAll(RegExp(r'\[[^\]]*\]'), '')
      .replaceAll('il/elle', 'il')
      .replaceAll('ils/elles', 'ils')
      .replaceAll(RegExp(r'[→←⇄✅❌💡*_]'), ' ')
      .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'\s+([.,!?;:])'), r'$1')
      .trim();

  /// Selects a French voice. Browsers load their voices a moment after the
  /// page opens, so this waits for them instead of falling back to the
  /// default (often English) voice.
  /// Returns false when the device has no French voice at all.
  static Future<bool> useFrenchVoice(FlutterTts tts) async {
    if (_noFrenchVoice) return false;
    if (_frenchVoice != null) {
      // setLanguage first: on the web it picks the first matching voice itself.
      await tts.setLanguage(_frenchVoice!['locale']!);
      await tts.setVoice(_frenchVoice!);
      return true;
    }
    for (var attempt = 0; attempt < 20; attempt++) {
      try {
        final voices = [
          for (final v in (await tts.getVoices as List? ?? const []))
            if (v is Map) Map<String, String>.from(v.map((k, val) => MapEntry('$k', '$val'))),
        ];
        if (voices.isNotEmpty) {
          final french = voices.where((v) => (v['locale'] ?? '').toLowerCase().startsWith('fr')).toList();
          if (french.isEmpty) {
            _noFrenchVoice = true;
            return false;
          }
          int score(Map<String, String> v) {
            final name = (v['name'] ?? '').toLowerCase();
            final locale = (v['locale'] ?? '').toLowerCase();
            return (locale == 'fr-fr' || locale == 'fr-be' ? 4 : 0) +
                (name.contains('natural') || name.contains('online') ? 2 : 0) +
                (name.contains('google') ? 1 : 0);
          }
          french.sort((a, b) => score(b) - score(a));
          _frenchVoice = {'name': french.first['name']!, 'locale': french.first['locale']!};
          await tts.setLanguage(_frenchVoice!['locale']!);
          await tts.setVoice(_frenchVoice!);
          return true;
        }
      } catch (e) {
        debugPrint('Could not list voices: $e');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }
    await tts.setLanguage('fr-FR');
    return true;
  }

  /// Reads [text] in French. [rate] 0.5 is slow (dictée), 0.9 is natural.
  Future<void> speak(String text, {double rate = 0.9}) async {
    await stop();
    final clean = speakableText(text);
    if (clean.isEmpty) return;
    try {
      if (await useFrenchVoice(flutterTts)) {
        await flutterTts.setSpeechRate(rate);
        await flutterTts.speak(clean);
      } else {
        await _speakNeural(clean);
      }
    } catch (e) {
      debugPrint('Could not speak: $e');
    }
  }

  /// Devices without any French voice use the server's neural French voice.
  Future<void> _speakNeural(String text) async {
    final source = await HuggingFaceTtsService.synthesizeAndSave(text);
    if (source == null) return;
    _neuralPlayer ??= AudioPlayer();
    await _neuralPlayer!.play(kIsWeb || source.startsWith('http') ? UrlSource(source) : DeviceFileSource(source));
  }

  Future<void> stop() async {
    try {
      await flutterTts.stop();
      await _neuralPlayer?.stop();
    } catch (e) {
      debugPrint('Could not stop speech: $e');
    }
  }

  Future<void> pause() async {
    await flutterTts.pause();
  }
}
