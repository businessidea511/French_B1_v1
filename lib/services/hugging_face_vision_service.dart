import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HuggingFaceVisionService {
  static const List<String> modelUrls = [
    'https://api-inference.huggingface.co/models/Salesforce/blip-image-captioning-large',
    'https://api-inference.huggingface.co/models/nlpconnect/vit-gpt2-image-captioning',
    'https://api-inference.huggingface.co/models/Salesforce/blip-image-captioning-base',
  ];

  static String get _token {
    const String dKey = String.fromEnvironment('HF_TOKEN');
    if (dKey.isNotEmpty) return dKey;
    try {
      return dotenv.env['HF_TOKEN'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<String?> describeImage(String base64Image) async {
    final token = _token;
    if (token.isEmpty) {
      debugPrint('❌ Vision Error: HF_TOKEN is missing');
      return null;
    }

    final bytes = base64Decode(base64Image);

    // Try multiple models in a cascade
    for (String url in modelUrls) {
      int retries = 2; // Reduced to 2 for faster fallback
      while (retries > 0) {
        try {
          debugPrint('📸 Trying Vision Model: ${url.split('/').last} (Retries left: $retries)');
          final response = await http.post(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer $token'},
            body: bytes,
          ).timeout(const Duration(seconds: 20));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is List && data.isNotEmpty) {
              final result = data[0]['generated_text'] as String;
              debugPrint('✅ Vision Success from ${url.split('/').last}: $result');
              return result;
            }
          }
          
          // If model is loading (503), wait and retry
          if (response.statusCode == 503) {
            debugPrint('⏳ Model loading, waiting 2s...');
            await Future.delayed(const Duration(seconds: 2));
            retries--;
            continue; 
          }

          // If other error, try next model
          debugPrint('❌ Model ${url.split('/').last} failed with ${response.statusCode}');
          break; 
        } catch (e) {
          debugPrint('❌ Vision Exception on ${url.split('/').last}: $e');
          break;
        }
      }
    }
    return null;
  }
}
