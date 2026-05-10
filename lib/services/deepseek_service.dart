import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'gemini_service.dart';

class DeepSeekService {
  static const String baseUrl = 'https://api.deepseek.com/v1';
  static final Map<String, String> _memoryCache = {};

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
                  '3. FULL TRANSLATION: The question, the options, and the explanation MUST be in $targetLanguage. Only the French grammar subject being tested stays in French. \n'
                  '4. PEDAGOGICAL EXPLANATION: The explanation MUST be in $targetLanguage and explain why the answer is correct. \n'
                  '5. ACCURACY: Double-check conjugations and agreements. \n'
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

  // Generate AI Story / Novel
  static Future<Map<String, dynamic>> generateStory(
    List<String> grammar,
    List<String> lessons,
    String targetLanguage,
  ) async {
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
                  'You are an expert French B1 novelist and teacher. Create an engaging 5-page French story. '
                  'The story MUST be in French. '
                  'CRITICAL: Each page MUST have "learning_points" which are pedagogical explanations of the grammar or vocabulary used on that page. '
                  'The "learning_points" MUST be written in $targetLanguage (the user\'s native language). '
                  'Return ONLY valid JSON in this exact format: '
                  '{"title":"<French Title>","pages":[{"text":"<French text for this page>","learning_points":["<Explanation in $targetLanguage>"]}]}'
            },
            {
              'role': 'user',
              'content':
                  'Create a B1 level French story incorporating these grammar topics: ${grammar.join(", ")} and these lesson themes: ${lessons.join(", ")}. '
                  'The story should have 5 pages. Each page needs 2-3 learning points explained in $targetLanguage.'
            }
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        throw Exception('Failed to generate story: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating story: $e');
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
              'content':
                  'You are a French teacher explaining grammar to beginners. Use simple language, clear examples, and helpful metaphors. '
                      'Use Markdown to format your response (Headings, bold keywords, code blocks for conjugations, blockquotes for tips). '
                      'Your entire explanation MUST be in $targetLanguage.'
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
  // Synchronous check for memory cache
  static String? getCachedTranslation(String text, String targetLanguage) {
    final String cacheKey = 'trans_${targetLanguage}_${text.hashCode}';
    return _memoryCache[cacheKey];
  }

  // Translate text to a target language with Dual-Layer Cache (Memory + Disk)
  static Future<String> translateText(String text, String targetLanguage) async {
    if (text.trim().isEmpty) return text;
    
    final String cacheKey = 'trans_${targetLanguage}_${text.hashCode}';

    // 1. Check Memory Cache (Instant)
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 2. Check Disk Cache (Async)
      final String? cachedTranslation = prefs.getString(cacheKey);
      if (cachedTranslation != null) {
        _memoryCache[cacheKey] = cachedTranslation; // Hydrate memory cache
        return cachedTranslation;
      }

      // 3. Call API
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
                  'You are a professional translator and French language expert. '
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
              'content': 'Translate this lesson content to $targetLanguage: $text'
            }
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String translated = data['choices'][0]['message']['content'].toString().trim();
        
        // 4. Save to both caches
        _memoryCache[cacheKey] = translated;
        await prefs.setString(cacheKey, translated);
        
        return translated;
      }
      return text;
    } catch (e) {
      debugPrint('Translation error: $e');
      return text;
    }
  }

  // Ask a specific grammar question
  static Future<String> askGrammarQuestion(
      String question, String topic, String targetLanguage) async {
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
                  'You are a French grammar expert. You explain things simply and clearly for "dummies" (beginner to intermediate levels). '
                      'Your answer should be professional but very easy to understand. '
                      'Use Markdown to format your response: \n'
                      '- Use **bold** for French keywords. \n'
                      '- Use `code blocks` for conjugations or specific rules. \n'
                      '- Use ## Headings for different sections. \n'
                      '- Use > Blockquotes for important tips. \n'
                      '- Use bullet points for lists. \n'
                      'Use examples in French followed by their translation in $targetLanguage. '
                      'Keep the response concise and pedagogical. '
                      'The user is currently studying the topic: $topic. '
                      'The user\'s preferred language for explanations is $targetLanguage.'
            },
            {
              'role': 'user',
              'content': 'Question about $topic: $question'
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in askGrammarQuestion: $e');
      rethrow;
    }
  }

  // Generate a full lesson from a topic or PDF text
  static Future<Map<String, dynamic>> generateFullLesson(
      String topic, String targetLanguage,
      {String? pdfText}) async {
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
                  'You are a French B1 teacher. Generate a comprehensive lesson in JSON format. '
                      'The lesson must be "for dummies" (simple, clear, engaging). '
                      'CRITICAL RULE: ALL explanations, descriptions, and section content MUST be written in $targetLanguage. '
                      'French examples and vocabulary MUST stay in French but ALWAYS include translations in $targetLanguage. '
                      'Do NOT use English if $targetLanguage is different from English. '
                      'Return a JSON object with: '
                      '"title" (String), "subtitle" (String), "icon" (String emoji), '
                      '"sections" (Array of objects with "title" (in $targetLanguage) and "content" (Markdown string in $targetLanguage)).'
            },
            {
              'role': 'user',
              'content': pdfText != null
                  ? 'Generate a French B1 lesson based on this PDF text: \n\n $pdfText \n\n Focus on the main topic: $topic. Explanation language: $targetLanguage.'
                  : 'Generate a French B1 lesson about: $topic. Explanation language: $targetLanguage.'
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['choices'][0]['message']['content']);
      } else {
        throw Exception('Failed to generate lesson: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating lesson: $e');
      rethrow;
    }
  }

  // Generate a full grammar guide from a topic or PDF text
  static Future<Map<String, dynamic>> generateFullGrammar(
      String topic, String targetLanguage,
      {String? pdfText}) async {
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
                  'You are a French Grammar expert. Generate a comprehensive B1 grammar guide in JSON format. '
                      'The guide must be "for dummies" (simple, clear, logical). '
                      'CRITICAL RULE: ALL explanations, descriptions, and section content MUST be written in $targetLanguage. '
                      'French examples, conjugations, and grammar rules MUST stay in French but ALWAYS include translations in $targetLanguage. '
                      'Return a JSON object with: '
                      '"title" (String - e.g. "Le Subjonctif"), "subtitle" (String - e.g. "Wishes and Doubts"), "icon" (String emoji), '
                      '"sections" (Array of objects with "title" (in $targetLanguage) and "content" (Markdown string in $targetLanguage)).'
            },
            {
              'role': 'user',
              'content': pdfText != null
                  ? 'Generate a French B1 grammar guide based on this PDF text: \n\n $pdfText \n\n Focus on the topic: $topic. Explanation language: $targetLanguage.'
                  : 'Generate a French B1 grammar guide about: $topic. Explanation language: $targetLanguage.'
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['choices'][0]['message']['content']);
      } else {
        throw Exception('Failed to generate grammar: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating grammar: $e');
      rethrow;
    }
  }

  // Generate a full AI Book (story) combining grammar and lessons
  static Future<Map<String, dynamic>> generateAIBook(
      List<String> grammarTopics, List<String> lessonTopics, String targetLanguage) async {
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
                  'You are a professional French novelist and pedagogical expert. Generate a RICH, engaging, and detailed B1-level story in JSON format. '
                      'The story MUST be long and immersive (at least 300-400 words total), divided into 4-6 pages. '
                      'CRITICAL RULES: \n'
                      '1. STORYTELLING: Write a real story with a beginning, middle, and end. Use descriptive language. \n'
                      '2. INTEGRATION: Naturally weave the provided grammar points and vocabulary into the narrative. \n'
                      '3. FORMATTING: Each page must have substantial text (70-100 words). Return as a list of "pages". \n'
                      '4. ANNOTATIONS: Highlight at least 3-5 interesting grammar/vocab uses per page. \n'
                      '5. LANGUAGE ENFORCEMENT: The story text MUST be in French. ALL annotations and explanations MUST be written in $targetLanguage. '
                      'It is FORBIDDEN to use English if $targetLanguage is not English. \n'
                      'Return a JSON object with: "title", "pages" (Array of {text, annotations}).'
            },
            {
              'role': 'user',
              'content': 'Write a B1 story using: \n'
                  'Grammar: ${grammarTopics.join(', ')} \n'
                  'Vocabulary/Lessons: ${lessonTopics.join(', ')} \n'
                  'CRITICAL: ALL annotations and explanations MUST be in $targetLanguage.'
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['choices'][0]['message']['content']);
      } else {
        throw Exception('Failed to generate AI Book: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating AI Book: $e');
      rethrow;
    }
  }

  // ── Generate lesson from multiple photos (Vision via Proxy) ────────────────
  static Future<Map<String, dynamic>> generateLessonFromImages(
    List<String> base64Images,
    String mimeType,
    String targetLanguage,
  ) async {
    try {
      // 1. Get description of ALL images using Gemini
      final description = await GeminiService.describeImages(base64Images, mimeType);
      
      if (description.startsWith('ERROR') || description.startsWith('EXCEPTION')) {
        throw Exception(description);
      }

      debugPrint('📸 Multi-Image Description for Lesson: $description');

      // 2. Ask DeepSeek to generate lesson based on description
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
                  'You are an expert French B1 teacher. Based on this multi-page lesson description: "$description", create a comprehensive French B1 lesson. '
                  'The lesson explanation must be in $targetLanguage. '
                  'Return ONLY valid JSON in this exact format: '
                  '{"id":"img_lesson_<timestamp>","title":"<French topic title>","subtitle":"<subtitle in $targetLanguage>","icon":"📚","content":{'
                  '"introduction":"<introduction in $targetLanguage>","vocabulary":[{"french":"","translation":"","example":""}],'
                  '"grammar":{"title":"","explanation":"","examples":[""]},'
                  '"exercises":[{"question":"","answer":""}],'
                  '"cultural_note":""}}'
            },
            {
              'role': 'user',
              'content': 'Create a cohesive B1 French lesson combining all concepts from the described pages: "$description".'
            }
          ],
          'max_tokens': 4000,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final lesson = jsonDecode(content);
        lesson['id'] = 'img_${DateTime.now().millisecondsSinceEpoch}';
        return lesson;
      } else {
        throw Exception('DeepSeek API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating lesson from multi-image proxy: $e');
      rethrow;
    }
  }

  // ── Ask a question about multiple images (Vision via Proxy) ────────────────
  static Future<String> askQuestionWithImages(
    String question,
    List<String> base64Images,
    String mimeType,
    String targetLanguage,
  ) async {
    try {
      // 1. Get description of ALL images using Gemini
      final description = await GeminiService.describeImages(base64Images, mimeType);
      
      if (description.startsWith('ERROR') || description.startsWith('EXCEPTION')) {
        throw Exception(description);
      }

      debugPrint('📸 Multi-Image Description: $description');

      // 2. Ask DeepSeek to explain based on description
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
                  'You are an expert French B1 teacher. The user has provided multiple images (pages) described as: "$description". '
                  'Answer the user\'s question about this content. '
                  'The explanation MUST be in $targetLanguage. Use markdown for formatting.'
            },
            {
              'role': 'user',
              'content': question.isEmpty
                  ? 'Please explain the French vocabulary and grammar related to these pages: "$description".'
                  : question
            }
          ],
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('DeepSeek API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in multi-image vision-proxy: $e');
      return "Désolé, an error occurred: $e\n\nPlease try again with clearer photos.";
    }
  }
}


