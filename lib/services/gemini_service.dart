import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

  static Future<String> describeImages(List<String> base64Images, String mimeType) async {
    final key = _getNextKey();
    if (key.isEmpty) return "ERROR: No Gemini API keys found.";

    // 2026 Future Models from user's Google AI Studio screenshot
    final attempts = [
      {'ver': 'v1beta', 'model': 'gemini-2.5-flash'},
      {'ver': 'v1beta', 'model': 'gemini-3-flash'},
      {'ver': 'v1beta', 'model': 'nano-banana'},
      {'ver': 'v1beta', 'model': 'gemini-2-flash'},
      {'ver': 'v1beta', 'model': 'gemini-1.5-flash'}, // Legacy fallback
    ];

    for (var attempt in attempts) {
      try {
        final version = attempt['ver'];
        final modelId = attempt['model'];
        debugPrint('💎 Trying Future Gemini $modelId ($version) for ${base64Images.length} images...');

        final url = 'https://generativelanguage.googleapis.com/$version/models/$modelId:generateContent';
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': key,
          },
          body: jsonEncode({
            "contents": [{
              "parts": [
                {"text": "These are ${base64Images.length} images from a French grammar lesson. Describe them in detail for a French B1 student. Transcribe any French text exactly and maintain the order of the pages."},
                ...base64Images.map((img) => {
                  "inline_data": {"mime_type": mimeType, "data": img}
                })
              ]
            }]
          }),
        ).timeout(const Duration(seconds: 25)); // Increased timeout for multi-image

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          debugPrint('✅ Success with Multi-Image on: $modelId!');
          return (data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? "Error parsing response") as String;
        }
        debugPrint('❌ $modelId failed (${response.statusCode})');
      } catch (e) {
        debugPrint('❌ Attempt failed for $attempt: $e');
      }
    }

    return "EXCEPTION: Your 2026 Google AI Studio models returned 404/Error for multi-image.";
  }
}
