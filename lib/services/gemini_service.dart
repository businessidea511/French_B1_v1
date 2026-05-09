import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  // Rotate through multiple keys to bypass free tier limits
  static List<String> get _keys {
    List<String> keys = [];
    
    // In Flutter, String.fromEnvironment MUST use a string literal and be const
    const k1 = String.fromEnvironment('GEMINI_KEY_1');
    if (k1.isNotEmpty) keys.add(k1);
    
    const k2 = String.fromEnvironment('GEMINI_KEY_2');
    if (k2.isNotEmpty) keys.add(k2);
    
    const k3 = String.fromEnvironment('GEMINI_KEY_3');
    if (k3.isNotEmpty) keys.add(k3);
    
    const k4 = String.fromEnvironment('GEMINI_KEY_4');
    if (k4.isNotEmpty) keys.add(k4);
    
    const k5 = String.fromEnvironment('GEMINI_KEY_5');
    if (k5.isNotEmpty) keys.add(k5);
    
    // Fallback to legacy single key
    const k0 = String.fromEnvironment('GEMINI_KEY');
    if (k0.isNotEmpty && !keys.contains(k0)) keys.add(k0);
    
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

  static Future<String> describeImage(String base64Image, String mimeType) async {
    final keys = _keys;
    if (keys.isEmpty) {
      return "ERROR: No Gemini API keys found. Please check your Vercel Environment Variables.";
    }
    
    final key = _getNextKey();

    try {
      debugPrint('💎 Analyzing image with Gemini 1.5 Flash...');
      
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [
              {"text": "Describe this image in detail for a French B1 student. Transcribe any text exactly."},
              {
                "inline_data": {
                  "mime_type": mimeType,
                  "data": base64Image
                }
              }
            ]
          }]
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      }
      
      return "ERROR: Gemini API returned ${response.statusCode}. Body: ${response.body}";
    } catch (e) {
      return "EXCEPTION: $e";
    }
  }
}
