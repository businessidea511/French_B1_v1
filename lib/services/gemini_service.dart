import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
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
    if (key.isEmpty) {
      return "ERROR: No Gemini API keys found. Please check your Vercel Environment Variables.";
    }

    try {
      debugPrint('💎 Analyzing image with Official Gemini SDK...');
      
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
      );

      final content = [
        Content.multi([
          TextPart("Describe this image in detail for a French B1 student. Transcribe any French text exactly."),
          DataPart(mimeType, base64Decode(base64Image)),
        ])
      ];

      final response = await model.generateContent(content);
      
      if (response.text != null) {
        return response.text!;
      } else {
        return "ERROR: Gemini returned an empty response.";
      }
    } catch (e) {
      return "EXCEPTION: $e";
    }
  }
}
