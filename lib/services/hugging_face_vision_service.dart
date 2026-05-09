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
      if (token.isEmpty) return null;

      debugPrint('📸 Describing image using Hugging Face...');
      
      final response = await http.post(
        Uri.parse(modelUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': base64Image,
          'parameters': {'wait_for_model': true}
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]['generated_text'];
        }
      }
      debugPrint('HF Vision Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('HF Vision Exception: $e');
      return null;
    }
  }
}
