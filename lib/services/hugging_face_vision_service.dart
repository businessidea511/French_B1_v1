import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HuggingFaceVisionService {
  static const String modelUrl = 'https://api-inference.huggingface.co/models/Salesforce/blip-image-captioning-large';

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
    try {
      final token = _token;
      if (token.isEmpty) {
        debugPrint('❌ Vision Error: HF_TOKEN is missing');
        return null;
      }

      debugPrint('📸 Sending image bytes to Hugging Face...');
      
      // Convert base64 back to raw bytes for the Inference API
      final bytes = base64Decode(base64Image);

      final response = await http.post(
        Uri.parse(modelUrl),
        headers: {
          'Authorization': 'Bearer $token',
          // Note: Content-Type is NOT json here, it's the raw image data
        },
        body: bytes,
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final text = data[0]['generated_text'] as String;
          debugPrint('✅ Vision Success: $text');
          return text;
        }
      }
      
      debugPrint('❌ Vision API Error ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ Vision Exception: $e');
      return null;
    }
  }
}
