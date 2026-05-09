import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static List<String> get _keys {
    List<String> keys = [];
    const k1 = String.fromEnvironment('GEMINI_KEY_1');
    if (k1.isNotEmpty) keys.add(k1);
    const k2 = String.fromEnvironment('GEMINI_KEY_2');
    if (k2.isNotEmpty) keys.add(k2);
    const k0 = String.fromEnvironment('GEMINI_KEY');
    if (k0.isNotEmpty && !keys.contains(k0)) keys.add(k0);
    return keys;
  }

  static int _currentKeyIndex = -1;
  static String _getNextKey() {
    final keys = _keys;
    if (keys.isEmpty) return '';
    if (_currentKeyIndex == -1) {
      _currentKeyIndex = DateTime.now().millisecondsSinceEpoch % keys.length;
    }
    final key = keys[_currentKeyIndex];
    _currentKeyIndex = (_currentKeyIndex + 1) % keys.length;
    return key;
  }

  static Future<String> describeImage(String base64Image, String mimeType) async {
    final key = _getNextKey();
    if (key.isEmpty) return "ERROR: No Gemini API keys found.";

    // Try multiple model IDs and API versions
    final attempts = [
      {'ver': 'v1beta', 'model': 'gemini-1.5-flash-8b-latest'},
      {'ver': 'v1beta', 'model': 'gemini-1.5-flash'},
      {'ver': 'v1', 'model': 'gemini-1.5-flash'},
      {'ver': 'v1beta', 'model': 'gemini-1.5-pro'},
    ];

    for (var attempt in attempts) {
      try {
        final version = attempt['ver'];
        final modelId = attempt['model'];
        debugPrint('💎 Trying Gemini $modelId ($version) with Header Auth...');

        final url = 'https://generativelanguage.googleapis.com/$version/models/$modelId:generateContent';
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': key, // Passing key in header is more robust against some CORS/Proxy issues
          },
          body: jsonEncode({
            "contents": [{
              "parts": [
                {"text": "Describe this image in detail for a French B1 student. Transcribe any French text exactly."},
                {"inline_data": {"mime_type": mimeType, "data": base64Image}}
              ]
            }]
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          debugPrint('✅ Success with $modelId!');
          return data['candidates'][0]['content']['parts'][0]['text'] as String;
        }
        debugPrint('❌ $modelId failed (${response.statusCode}): ${response.body}');
      } catch (e) {
        debugPrint('❌ Attempt failed: $e');
      }
    }

    return "EXCEPTION: All vision attempts failed. This might be a regional API restriction or an issue with the API keys.";
  }
}
