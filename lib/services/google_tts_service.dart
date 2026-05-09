import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class GoogleTtsService {
  static final String _apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
  static const String _baseUrl = 'https://texttospeech.googleapis.com/v1/text:synthesize';

  static Future<String?> synthesizeAndSave(String text) async {
    if (_apiKey.isEmpty) {
      debugPrint('Google API Key is missing!');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'input': {'text': text},
          'voice': {
            'languageCode': 'fr-FR',
            'name': 'fr-FR-Neural2-B', // Premium Male Voice
            'ssmlGender': 'MALE'
          },
          'audioConfig': {
            'audioEncoding': 'MP3',
            'pitch': 0,
            'speakingRate': 0.92 // Natural but clear for B1
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audioContent = data['audioContent'];
        final bytes = base64Decode(audioContent);
        
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/tts_audio.mp3');
        await file.writeAsBytes(bytes);
        
        return file.path;
      } else {
        debugPrint('Google TTS Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error synthesizing speech: $e');
      return null;
    }
  }
}
