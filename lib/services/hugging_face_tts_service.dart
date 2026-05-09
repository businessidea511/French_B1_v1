import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HuggingFaceTtsService {
  static final String _token = dotenv.env['HF_TOKEN'] ?? '';
  static const String _baseUrl =
      'https://innoai-edge-tts-text-to-speech.hf.space/gradio_api/call/tts_interface';

  static Future<String?> synthesizeAndSave(String text) async {
    if (_token.isEmpty) {
      debugPrint('HF Token is missing! Check your .env file.');
      return null;
    }

    try {
      debugPrint('Step 1: Triggering TTS generation...');

      // Step 1: Trigger generation — returns event_id
      final triggerResponse = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'data': [
            text,                                       // text input
            'fr-FR-DeniseNeural - fr-FR (Female)',      // voice (exact value from API)
            0,                                          // rate
            0,                                          // pitch
          ]
        }),
      ).timeout(const Duration(seconds: 20));

      if (triggerResponse.statusCode != 200) {
        debugPrint('Trigger failed ${triggerResponse.statusCode}: ${triggerResponse.body}');
        return null;
      }

      final eventId = jsonDecode(triggerResponse.body)['event_id'];
      debugPrint('Step 2: Polling for event_id: $eventId');

      // Step 2: Poll the result stream
      final resultResponse = await http.get(
        Uri.parse('$_baseUrl/$eventId'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 30));

      if (resultResponse.statusCode != 200) {
        debugPrint('Poll failed ${resultResponse.statusCode}: ${resultResponse.body}');
        return null;
      }

      // Parse the SSE stream — find the "complete" event with data
      final lines = resultResponse.body.split('\n');
      String? audioUrl;

      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim() == 'event: complete' && i + 1 < lines.length) {
          final dataLine = lines[i + 1];
          if (dataLine.startsWith('data: ')) {
            final jsonData = jsonDecode(dataLine.substring(6));
            if (jsonData is List && jsonData.isNotEmpty) {
              final fileData = jsonData[0];
              if (fileData is Map && fileData['url'] != null) {
                audioUrl = fileData['url'] as String;
              }
            }
          }
          break;
        }
      }

      if (audioUrl == null) {
        debugPrint('No audio URL found in response. Body: ${resultResponse.body.substring(0, resultResponse.body.length.clamp(0, 500))}');
        return null;
      }

      debugPrint('Step 3: Downloading audio from $audioUrl');

      // On Web: return the URL directly (no file system available)
      if (kIsWeb) {
        debugPrint('Web mode: returning URL directly for streaming.');
        return audioUrl;
      }

      // On Native (Android/iOS/Windows): download and save locally
      final audioResponse = await http.get(
        Uri.parse(audioUrl),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 30));

      if (audioResponse.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/tts_output.mp3');
        await file.writeAsBytes(audioResponse.bodyBytes);
        debugPrint('Audio saved successfully: ${file.path}');
        return file.path;
      } else {
        debugPrint('Download failed ${audioResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('HuggingFaceTtsService error: $e');
    }
    return null;
  }
}
