import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_client.dart';

/// Neural French voice (Edge-TTS on Hugging Face), generated via /api/tts so
/// the HF token stays on the server.
class HuggingFaceTtsService {
  static Future<String?> synthesizeAndSave(String text) async {
    try {
      final response = await ApiClient.post('/api/tts', {'text': text},
          timeout: const Duration(seconds: 50));

      if (response.statusCode != 200) {
        debugPrint('TTS failed: ${ApiClient.errorMessage(response)}');
        return null;
      }

      final audioUrl = jsonDecode(response.body)['url'] as String?;
      if (audioUrl == null) return null;

      // On Web: return the URL directly (no file system available)
      if (kIsWeb) return audioUrl;

      // On Native (Android/iOS/Windows): download and save locally
      final audioResponse =
          await http.get(Uri.parse(audioUrl)).timeout(const Duration(seconds: 30));
      if (audioResponse.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/tts_output.mp3');
        await file.writeAsBytes(audioResponse.bodyBytes);
        return file.path;
      }
      debugPrint('Download failed ${audioResponse.statusCode}');
    } catch (e) {
      debugPrint('HuggingFaceTtsService error: $e');
    }
    return null;
  }
}
