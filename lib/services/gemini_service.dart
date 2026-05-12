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

  /// Describes images from French textbook pages with detailed extraction
  static Future<String> describeImages(List<String> base64Images, String mimeType) async {
    final allKeys = _keys;
    if (allKeys.isEmpty) return "ERROR: No Gemini API keys found.";

    debugPrint('🔑 Found ${allKeys.length} Gemini API keys');

    // Correct 2026 Google AI API model IDs (from Google AI Studio Rate Limit page)
    // Note: API uses "gemini-2.0-flash" NOT "gemini-2-flash"
    final models = [
      {'ver': 'v1beta', 'model': 'gemini-2.5-flash'},
      {'ver': 'v1beta', 'model': 'gemini-2.0-flash'},
      {'ver': 'v1beta', 'model': 'gemini-2.5-flash-lite'},
      {'ver': 'v1beta', 'model': 'gemini-1.5-flash'},
    ];

    const prompt = '''You are an expert French language teacher analyzing textbook pages.
TASK: Extract ALL French learning content from these images with extreme precision.

CRITICAL INSTRUCTION FOR HANDWRITTEN NOTES:
- The images may contain HANDWRITTEN ARABIC NOTES added by the student.
- You MUST IGNORE these Arabic notes when extracting the core lesson content.
- Do NOT let handwritten Arabic interfere with the French transcription.
- Only extract the original PRINTED textbook content (French) and its intended translations/exercises.
- If there are handwritten French corrections, you may note them as "User Correction" but do NOT confuse them with the main text.

For EACH image, extract:
1. **Vocabulary Lists**: Every French word/phrase with its category (e.g., "les symptômes", "les médicaments", "les parties du corps", "les accessoires")
2. **Medical/Health Items**: If health-related, list ALL items with their French names (e.g., "un thermomètre", "des pansements", "un masque", "des ciseaux")
3. **Grammar Points**: Any grammar rules, conjugations, or structures shown
4. **Exercises**: Questions, fill-in-the-blank, comprehension questions
5. **Mind Maps**: If there's a vocabulary mind map, list ALL categories and their items

FORMAT your response as a structured extraction:
---VOCABULARY---
Category: [category name]
- French word/phrase (with article if noun)
...

---EXERCISES---
- Exercise description and content
...

---NOTES---
- Any additional context, tips, or cultural notes (IGNORE ARABIC NOTES HERE)

Be EXHAUSTIVE for printed content. Transcribe French text EXACTLY as written.''';

    for (var modelInfo in models) {
      final version = modelInfo['ver'];
      final modelId = modelInfo['model'];
      
      // For each model, try ALL keys if we get rate limited
      int keyAttempts = allKeys.length;
      
      for (int i = 0; i < keyAttempts; i++) {
        final key = _getNextKey();
        final keyIdx = allKeys.indexOf(key) + 1;
        
        try {
          debugPrint('💎 Trying $modelId ($version) with Key #$keyIdx for ${base64Images.length} image(s)...');

          final url = 'https://generativelanguage.googleapis.com/$version/models/$modelId:generateContent';
          
          final imageParts = base64Images.map((img) => {
            "inline_data": {"mime_type": mimeType, "data": img}
          }).toList();
          
          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': key,
            },
            body: jsonEncode({
              "contents": [{
                "parts": [
                  {"text": prompt},
                  ...imageParts,
                ]
              }],
              "generationConfig": {
                "maxOutputTokens": 4096,
                "temperature": 0.2,
              }
            }),
          ).timeout(const Duration(seconds: 60)); // 60s for multi-image

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
            if (text != null && text.toString().isNotEmpty) {
              debugPrint('✅ Success with $modelId using Key #$keyIdx! (${text.toString().length} chars)');
              return text.toString();
            }
            debugPrint('⚠️ $modelId returned empty response');
          } else if (response.statusCode == 404) {
            debugPrint('❌ $modelId NOT FOUND (404). Trying next model...');
            break; // Model doesn't exist, try next
          } else if (response.statusCode == 429 || response.statusCode == 503) {
            debugPrint('⚠️ $modelId RATE LIMITED/BUSY (${response.statusCode}) with Key #$keyIdx. Switching key...');
            await Future.delayed(const Duration(milliseconds: 500)); // Brief pause before retry
            continue; // Try different key for SAME model
          } else {
            debugPrint('❌ $modelId failed (${response.statusCode}): ${response.body.substring(0, (response.body.length > 200) ? 200 : response.body.length)}');
            break; // Unknown error, try next model
          }
        } catch (e) {
          debugPrint('❌ Exception for $modelId with Key #$keyIdx: $e');
          if (e.toString().contains('TimeoutException')) {
            debugPrint('⏰ Timeout - trying next key...');
            continue;
          }
        }
      }
    }

    return "EXCEPTION: All Gemini models and all ${allKeys.length} keys failed. Check your API keys in Vercel and ensure at least one model is available.";
  }
}
