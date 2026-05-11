import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static List<String> get _keys {
    List<String> keys = [];
    
    // Each key MUST be a const declaration (Dart requirement)
    const k1 = String.fromEnvironment('GEMINI_KEY_1');
    const k2 = String.fromEnvironment('GEMINI_KEY_2');
    const k3 = String.fromEnvironment('GEMINI_KEY_3');
    const k4 = String.fromEnvironment('GEMINI_KEY_4');
    const k5 = String.fromEnvironment('GEMINI_KEY_5');
    const k0 = String.fromEnvironment('GEMINI_KEY');

    for (final k in [k1, k2, k3, k4, k5, k0]) {
      if (k.isNotEmpty && !keys.contains(k)) keys.add(k);
    }

    // Also check dotenv for local dev
    for (final name in ['GEMINI_KEY_1', 'GEMINI_KEY_2', 'GEMINI_KEY_3', 'GEMINI_KEY_4', 'GEMINI_KEY_5', 'GEMINI_KEY']) {
      try {
        final dk = dotenv.env[name] ?? '';
        if (dk.isNotEmpty && !keys.contains(dk)) keys.add(dk);
      } catch (_) {}
    }

    return keys;
  }

  static int _currentKeyIndex = -1;
  static String _getNextKey() {
    final keys = _keys;
    if (keys.isEmpty) return '';
    if (_currentKeyIndex == -1) {
      _currentKeyIndex = DateTime.now().millisecondsSinceEpoch % keys.length;
    } else {
      _currentKeyIndex = (_currentKeyIndex + 1) % keys.length;
    }
    return keys[_currentKeyIndex];
  }

  static Future<String> describeImages(List<String> base64Images, String mimeType) async {
    final allKeys = _keys;
    if (allKeys.isEmpty) return "ERROR: No Gemini API keys found.";

    // 2026 Future Models from user's Google AI Studio screenshot
    final models = [
      {'ver': 'v1beta', 'model': 'gemini-2.5-flash'},
      {'ver': 'v1beta', 'model': 'gemini-3-flash'},
      {'ver': 'v1beta', 'model': 'gemini-3.1-flash'},
      {'ver': 'v1beta', 'model': 'gemini-2-flash'},
      {'ver': 'v1', 'model': 'gemini-2.5-flash'}, // Try v1 endpoint as fallback
      {'ver': 'v1beta', 'model': 'gemini-1.5-flash'}, // Final legacy fallback
    ];

    for (var modelInfo in models) {
      final version = modelInfo['ver'];
      final modelId = modelInfo['model'];
      
      // For each model, try up to 3 different keys if we get rate limited or service busy
      int keyAttempts = allKeys.length > 3 ? 3 : allKeys.length;
      
      for (int i = 0; i < keyAttempts; i++) {
        final key = _getNextKey();
        final keyDisplay = key.length > 8 ? "${key.substring(0, 4)}...${key.substring(key.length - 4)}" : "Key";
        
        try {
          debugPrint('💎 Trying Gemini $modelId ($version) with Key $keyDisplay...');

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
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            debugPrint('✅ Success with Model: $modelId using Key $keyDisplay!');
            return (data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? "Error parsing response") as String;
          }
          
          if (response.statusCode == 404) {
            debugPrint('❌ $modelId NOT FOUND (404) on $version. Trying next model...');
            break; // Move to next model if this one doesn't exist
          } else if (response.statusCode == 429 || response.statusCode == 503) {
            debugPrint('⚠️ $modelId BUSY/LIMIT (${response.statusCode}) with $keyDisplay. Retrying with different key...');
            continue; // Try different key for SAME model
          } else {
            debugPrint('❌ $modelId failed (${response.statusCode})');
          }
        } catch (e) {
          debugPrint('❌ Exception for $modelId: $e');
        }
      }
    }

    return "EXCEPTION: All Gemini models ($models) and keys failed. Possible reasons: API limit, incorrect model names for your region, or network issues.";
  }
}
