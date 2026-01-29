import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class DeepSeekService {
  static const String baseUrl = 'https://api.deepseek.com/v1';

  static String get apiKey {
    const String dKey = String.fromEnvironment('DEEPSEEK_API_KEY');
    if (dKey.isNotEmpty) return dKey;
    try {
      return dotenv.env['DEEPSEEK_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  // Generate multiple AI-powered exercises
  static Future<List<Map<String, dynamic>>> generateExercises(
      String topic, String difficulty, String targetLanguage,
      {int count = 10}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert Professeur de Français (Alliance Française level). Provide perfectly accurate B1 grammar exercises. '
                  'CRITICAL RULES: \n'
                  '1. LOGICAL CONSISTENCY: The "correct" index MUST point to the grammatically correct answer. \n'
                  '2. NO AMBIGUITY: Do not use distractors that could also be correct in the context. \n'
                  '3. PEDAGOGICAL EXPLANATION: The explanation MUST be in $targetLanguage and explain why the answer is correct. \n'
                  '4. ACCURACY: Double-check conjugations and agreements. \n'
                  'Return JSON with "exercises" array.'
            },
            {
              'role': 'user',
              'content': topic == 'mixed_review'
                  ? 'Generate $count multiple choice exercises for a comprehensive French B1 General Review. The 10 questions MUST be a balanced mix of tenses. Difficulty: $difficulty. Each exercise must have: "question", "options" (array of 4 unique strings), "correct" (index 0-3), "explanation" (in $targetLanguage).'
                  : 'Generate $count multiple choice exercises for French B1 topic: $topic. Difficulty: $difficulty. Each exercise must have: "question", "options" (array of 4 unique strings), "correct" (index 0-3), "explanation" (in $targetLanguage).'
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final Map<String, dynamic> parsed = jsonDecode(content);
        return List<Map<String, dynamic>>.from(parsed['exercises']);
      } else {
        throw Exception('Failed to generate exercises: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating exercises: $e');
      rethrow;
    }
  }

  // Generate AI flashcards
  static Future<List<Map<String, String>>> generateFlashcards(String topic,
      {int count = 10}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a French B1 teacher. Generate flashcards in JSON format. Return a JSON object with a key "flashcards" containing an array of objects.'
            },
            {
              'role': 'user',
              'content':
                  'Generate $count flashcards for French B1 topic: $topic. Each flashcard must have "front" (question/term) and "back" (answer/explanation).'
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final Map<String, dynamic> parsed = jsonDecode(content);
        return (parsed['flashcards'] as List)
            .map((item) => {
                  'front': item['front'].toString(),
                  'back': item['back'].toString(),
                })
            .toList();
      } else {
        throw Exception(
            'Failed to generate flashcards: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating flashcards: $e');
      rethrow;
    }
  }

  // Get full conjugation for any verb
  static Future<Map<String, List<String>>> conjugateVerb(String verb) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a French linguistics expert. Provide verb conjugations in JSON format. Return a JSON object where keys are tenses and values are lists of 6 conjugated forms. IMPORTANT: Each form MUST include the pronoun (je, tu, il/elle, nous, vous, ils/elles). Example: ["je parle", "tu parles", ...].'
            },
            {
              'role': 'user',
              'content':
                  'Conjugate the French verb "$verb" in the following tenses: Présent, Passé Composé, Imparfait, Plus-que-parfait, Conditionnel, Futur Proche, Futur Simple.'
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final Map<String, dynamic> parsed = jsonDecode(content);

        Map<String, List<String>> result = {};
        parsed.forEach((key, value) {
          result[key] = List<String>.from(value);
        });
        return result;
      } else {
        throw Exception('Failed to conjugate verb: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error conjugating verb: $e');
      rethrow;
    }
  }

  // Get AI explanation for a grammar topic
  static Future<String> getGrammarExplanation(
      String topic, String targetLanguage) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a French teacher explaining grammar to beginners. Use simple language, clear examples, and helpful metaphors. Your entire explanation MUST be in $targetLanguage.'
            },
            {
              'role': 'user',
              'content':
                  'Explain French B1 topic: $topic in a simple way for dummies. Include examples and common mistakes. Write the response in $targetLanguage.'
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get explanation: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting explanation: $e');
      rethrow;
    }
  }

  // Check answer and provide feedback
  static Future<String> checkAnswer(String question, String userAnswer,
      String correctAnswer, String targetLanguage) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a supportive French teacher providing feedback on student answers. Your feedback MUST be in $targetLanguage.'
            },
            {
              'role': 'user',
              'content':
                  'Question: $question\nStudent answer: $userAnswer\nCorrect answer: $correctAnswer\n\nProvide encouraging feedback in $targetLanguage explaining why the correct answer is right.'
            }
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'Unable to provide feedback at this time.';
      }
    } catch (e) {
      debugPrint('Error checking answer: $e');
      return 'Unable to provide feedback at this time.';
    }
  }

  // Generate listening exercise (Text + Questions)
  // Generate listening exercise (Text + Questions)
  static Future<Map<String, dynamic>> generateListeningExercise(String topic,
      {String? city}) async {
    try {
      final bool isDialogue = topic.startsWith('Dialogue');
      String userPrompt;

      if (isDialogue) {
        final targetCity = city ?? 'Paris';

        // Explicit Randomization to force variety
        final Map<String, List<String>> cityNeighborhoods = {
          'Paris': [
            'Montmartre',
            'Le Marais',
            'Quartier Latin',
            'Bastille',
            'Saint-Germain-des-Prés',
            'Belleville',
            'Opéra'
          ],
          'Bruxelles': [
            'Ixelles',
            'Uccle',
            'Saint-Gilles',
            'Centre-ville',
            'Etterbeek',
            'Schaerbeek',
            'Anderlecht'
          ],
          'Liège': [
            'Outremeuse',
            'Le Carré',
            'Guillemins',
            'Saint-Léonard',
            'Cointe',
            'Pierreuse',
            'Longdoz'
          ],
        };

        final neighborhoods = cityNeighborhoods[targetCity] ?? ['Centre-ville'];
        final randomNeighborhood =
            neighborhoods[Random().nextInt(neighborhoods.length)];

        final List<String> roomTypes = [
          'Studio',
          'T2 (1 bedroom)',
          'T3 (2 bedrooms)',
          'T4 (3 bedrooms)'
        ];
        final randomRoom = roomTypes[Random().nextInt(roomTypes.length)];

        // Random budget between 600 and 2000
        final randomBudget =
            (Random().nextInt(15) + 6) * 100; // 600, 700... 2000

        userPrompt =
            'Generate a listening dialogue regarding renting an apartment in $targetCity. '
            'STRICT CONSTRAINTS: '
            '1. Location: The apartment MUST be in the "$randomNeighborhood" neighborhood. '
            '2. Size: It must be a $randomRoom. '
            '3. Budget: Around $randomBudget€/month. '
            '4. Scenario: Vary the client constraints (e.g., pets, floor, elevator). '
            'Make this specific scenario unique.';
      } else {
        userPrompt =
            'Generate a listening exercise about: $topic. Variation: ${Random().nextInt(10000)}. Make this story unique and different from previous versions.';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': isDialogue
                  ? 'You are a French B1 teacher. Generate a listening dialogue in JSON format. Return a JSON object with keys "text" and "questions" (an array of 5 objects). The "text" MUST be a dialogue script between "Client" and "Agence", where every line starts with "Client:" or "Agence:". Example: "Client: Bonjour...". Each question object must have: "question", "options" (4 strings), "answer" (the correct string from options) which tests comprehension.'
                  : 'You are a French B1 teacher. Generate a listening exercise in JSON format. Return a JSON object with keys "text" (a ~100 word French story/article) and "questions" (an array of 5 objects). Each question object must have: "question", "options" (4 strings), "answer" (the correct string from options). The text should be suitable for B1 level students.'
            },
            {'role': 'user', 'content': userPrompt}
          ],
          'response_format': {'type': 'json_object'},
          'temperature': isDialogue
              ? 0.7
              : 0.9, // Higher temp for variety in both cases, relying on system prompt for structure
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        throw Exception(
            'Failed to generate listening exercise: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating listening exercise: $e');
      rethrow;
    }
  }

  // Translate text to a target language
  static Future<String> translateText(
      String text, String targetLanguage) async {
    // We now allow translation for French to localize English-only descriptions,
    // relying on our system prompt to preserve existing French examples.

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional translator and French language expert. '
                  'Translate the given text into $targetLanguage. '
                  'CRITICAL RULE: This text is from a French grammar lesson. '
                  'DO NOT translate French words, phrases, conjugations, or examples used for teaching. '
                  'Keep any text that looks like a French grammar example, a conjugation (e.g., -er, -ir, -re endings), or a specific French phrase EXACTLY as it is. '
                  'Only translate the surrounding explanations, instructions, and descriptions. '
                  'Even if the text contains symbols like ❌ or ✅ followed by French, KEEP the French part. '
                  'Provide ONLY the localized translation, no extra comments.'
            },
            {
              'role': 'user',
              'content':
                  'Translate this lesson content to $targetLanguage: $text'
            }
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      }
      return text;
    } catch (e) {
      debugPrint('Translation error: $e');
      return text;
    }
  }
}
