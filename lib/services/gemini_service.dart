import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  // Rotate through multiple keys to bypass free tier limits
  static List<String> get _keys {
    List<String> keys = [];
    // Try to get from environment (Vercel)
    for (int i = 1; i <= 5; i++) {
      final key = String.fromEnvironment('GEMINI_KEY_$i');
      if (key.isNotEmpty) keys.add(key);
    }
    
    // Fallback to .env (Local)
    if (keys.isEmpty) {
      try {
        if (dotenv.env['GEMINI_KEY_1'] != null) keys.add(dotenv.env['GEMINI_KEY_1']!);
        if (dotenv.env['GEMINI_KEY_2'] != null) keys.add(dotenv.env['GEMINI_KEY_2']!);
      } catch (_) {}
    }
    
    // Last fallback: single GEMINI_KEY
    final singleKey = String.fromEnvironment('GEMINI_KEY');
    if (singleKey.isNotEmpty && !keys.contains(singleKey)) keys.add(singleKey);
    
    return keys;
  }

  // Use a random starting index to distribute load across sessions
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

  static Future<String?> describeImage(String base64Image, String mimeType) async {
    final key = _getNextKey();
    if (key.isEmpty) {
      debugPrint('❌ Gemini Error: No API keys found');
      return null;
    }

    try {
      debugPrint('💎 Analyzing image with Gemini 1.5 Flash...');
      
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [
              {"text": "Describe this image in detail, focus on any French text, vocabulary, or objects visible. If there is French text, transcribe it exactly."},
              {
                "inline_data": {
                  "mime_type": mimeType,
                  "data": base64Image
                }
              }
            ]
          }],
          "generationConfig": {
            "temperature": 0.4,
            "topK": 32,
            "topP": 1,
            "maxOutputTokens": 1024,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        debugPrint('✅ Gemini Success: ${text.substring(0, text.length.clamp(0, 100))}...');
        return text;
      }
      
      debugPrint('❌ Gemini API Error ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ Gemini Exception: $e');
      return null;
    }
  }
}
