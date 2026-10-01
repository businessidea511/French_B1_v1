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
  /// gender marks ("allé(e)s" → "allés"), arrows, emojis and every symbol a
  /// voice could read out loud (« ( », « / », « ? » on iPhone…).
  static String speakableText(String text, {bool plainPunctuation = false}) {
    var t = text
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .replaceAll(RegExp(r'\([^)]*$'), '') // a bracket that is never closed
        .replaceAll('il/elle', 'il')
        .replaceAll('ils/elles', 'ils')
        .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]', unicode: true), '')
        .replaceAll(RegExp(r'[→←⇄✅❌💡*_()\[\]{}«»"“”„<>=+#@&|~^•·]'), ' ')
        .replaceAll(RegExp(r'\s[-–—/]+\s|/'), ', ')
        .replaceAll('…', '.')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(RegExp(r'\s+([.,!?;:])'), (m) => m[1]!)
        .replaceAllMapped(RegExp(r'([.,!?;:])[.,;:]+'), (m) => m[1]!)
        .replaceAll(RegExp(r'^[\s.,!?;:]+'), '')
        .trim();
    // Safari on iPhone reads some marks aloud ("point d'interrogation"): keep only . and ,
    if (plainPunctuation) {
      t = t.replaceAll(RegExp(r'[!?;:]'), '.').replaceAll(RegExp(r'\.{2,}'), '.');
    }
    return t;
  }

  /// iPhone/iPad Safari: its novelty voices (Eddy, Flo, Grandma…) sound robotic,
  /// and it reads some punctuation aloud.
  static bool get _isApple =>
      defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

  /// Voice quality on Apple, Google and Microsoft devices: natural voices first,
  /// robotic or novelty voices last.
  static int voiceScore(String name, String locale) {
    final n = name.toLowerCase();
    final l = locale.toLowerCase().replaceAll('_', '-');
    var score = 0;
    if (l == 'fr-fr' || l == 'fr-be') score += 4;
    if (n.contains('natural') || n.contains('online') || n.contains('premium') || n.contains('enhanced') ||
        n.contains('neural')) {
      score += 6;
    }
    if (n.contains('google')) score += 2;
    // Apple's natural French voices
    if (RegExp(r'\b(thomas|audrey|aurélie|aurelie|amélie|amelie|marie|daniel)\b').hasMatch(n)) score += 5;
    // Apple's novelty / robotic voices
    if (RegExp(r'\b(eddy|flo|grandma|grandpa|grand-mère|grand-père|reed|rocko|sandy|shelley|jacques|albert|bahh|bells|boing|bubbles|cellos|jester|organ|superstar|trinoids|whisper|wobble|zarvox)\b')
        .hasMatch(n)) {
      score -= 10;
    }
    if (n.contains('compact')) score -= 2;
    return score;
  }

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
          int score(Map<String, String> v) => voiceScore(v['name'] ?? '', v['locale'] ?? '');
          french.sort((a, b) => score(b) - score(a));
          if (score(french.first) < 0) {
            // Only robotic voices on this device: use the server's natural French voice.
            _noFrenchVoice = true;
            return false;
          }
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
    final clean = speakableText(text, plainPunctuation: _isApple);
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
