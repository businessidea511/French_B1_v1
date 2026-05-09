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

  static String get _hfToken {
    const String dKey = String.fromEnvironment('HF_TOKEN');
    if (dKey.isNotEmpty) return dKey;
    try {
      return dotenv.env['HF_TOKEN'] ?? '';
    } catch (_) {
      return '';
    }
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
    
    // Strategy 1: Try Gemini with various endpoints
    final endpoints = [
      'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-001:generateContent',
    ];

    if (key.isNotEmpty) {
      for (var url in endpoints) {
        try {
          debugPrint('💎 Trying Gemini Endpoint: $url');
          final response = await http.post(
            Uri.parse('$url?key=$key'),
            headers: {'Content-Type': 'application/json'},
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
            return data['candidates'][0]['content']['parts'][0]['text'] as String;
          }
          debugPrint('❌ Gemini $url failed with ${response.statusCode}');
        } catch (e) {
          debugPrint('❌ Gemini $url error: $e');
        }
      }
    }

    // Strategy 2: Fallback to Hugging Face with a powerful Vision Model (Phi-3)
    final hfToken = _hfToken;
    if (hfToken.isNotEmpty) {
      try {
        debugPrint('🚀 Falling back to Hugging Face (Phi-3 Vision)...');
        final bytes = base64Decode(base64Image);
        final hfResponse = await http.post(
          Uri.parse('https://api-inference.huggingface.co/models/microsoft/phi-3-vision-128k-instruct'),
          headers: {'Authorization': 'Bearer $hfToken'},
          body: bytes,
        ).timeout(const Duration(seconds: 20));

        if (hfResponse.statusCode == 200) {
          final data = jsonDecode(hfResponse.body);
          if (data is List && data.isNotEmpty) {
            return data[0]['generated_text'] as String;
          }
        }
      } catch (e) {
        debugPrint('❌ HF Fallback error: $e');
      }
    }

    return "EXCEPTION: All vision systems failed. Please ensure your API keys are correct and active.";
  }
}
