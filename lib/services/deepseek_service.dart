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

  static Future<void> clearCache() async {
    _memoryCache.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('trans_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    debugPrint('🧹 Translation cache cleared');
  }

  static String get apiKey {
    const String dKey = String.fromEnvironment('DEEPSEEK_API_KEY');
    if (dKey.isNotEmpty) return dKey;
    try {
      return dotenv.env['DEEPSEEK_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Returns topic-specific AI guidance to ensure exercises are clear, complete, and unambiguous.
  static String _buildTopicGuidance(String topic, String targetLanguage) {
    final t = topic.toLowerCase();

    // ── L'Impératif ───────────────────────────────────────────────────────────
    if (t.contains('impératif') || t.contains('imperatif')) {
      return '''FOR IMPÉRATIF:
A. The sentence MUST imply an instruction, advice, order, or prohibition.
B. Do NOT include subject pronouns (tu, nous, vous) in the prompt sentence unless it is a reflexive verb (e.g., "Lave-toi").
C. For regular -er verbs (and "aller"), ensure the "tu" form drops the final 's' (e.g., "Parle !" instead of "Parles !").
D. Test irregular imperatives: être (sois, soyons, soyez), avoir (aie, ayons, ayez), aller (va, allons, allez), savoir (sache, sachons, sachez).
E. Distractors should include: present tense form with 's' (e.g. "parles" for tu form), wrong conjugation person, or infinitive.
F. Provide clear context/clues in the sentence or prompt header so the student knows which form (tu, nous, vous) to use.''';
    }

    // ── COD / COI / Object Pronouns ───────────────────────────────────────────
    if (t.contains('cod') || t.contains('coi') || t.contains('direct') ||
        t.contains('indirect') || t.contains('objet') || t.contains('pronoun')) {
      return '''FOR COD / COI PRONOUNS — CRITICAL RULES:
A. The sentence MUST identify the object noun with its gender and number BEFORE asking for the pronoun.
   ✅ GOOD: "Marie parle à son professeur. Elle ___ téléphone souvent." (COI → lui)
   ❌ BAD:  "Elle ___ téléphone." (student does not know who/what is being referred to)
B. The sentence should show the original full form first (with the noun), then ask what pronoun replaces it.
C. Options MUST test plausible pronoun confusions:
   - COD singular masculine: le / lui / les / leur
   - COD singular feminine: la / lui / les / leur  
   - COD plural: les / leur / le / en
   - COI singular (lui): lui / le / la / leur
   - COI plural (leur): leur / lui / les / en
D. NEVER mix COD and COI pronouns in the same question's options without a clear sentence that disambiguates.
E. For each question, state in parentheses in the sentence or question header whether it is a COD or COI sentence (e.g., "Remplacez le COD par le bon pronom:").''';
    }

    // ── Passé Composé ─────────────────────────────────────────────────────────
    if (t.contains('passé composé') || t.contains('passe compose')) {
      return '''FOR PASSÉ COMPOSÉ:
A. The sentence MUST include a time marker that forces passé composé (e.g., "hier", "la semaine dernière", "en 2020", "ce matin").
B. Options must test: correct auxiliary (être vs avoir), correct past participle, and agreement when needed.
   Example options for "Elle ___ au marché hier.": "est allée / a allé / est allé / a été allée"
C. If the verb uses être, the sentence subject gender MUST be visible (use a name or explicit pronoun like "elle", "ils").
D. Distractors should include: wrong auxiliary, wrong past participle ending, wrong agreement.''';
    }

    // ── Imparfait ─────────────────────────────────────────────────────────────
    if (t.contains('imparfait')) {
      return '''FOR IMPARFAIT:
A. The sentence MUST give a clear context that requires imparfait (habitual past, background description, ongoing action interrupted).
   Examples: "Quand j'étais enfant, je ___ souvent au parc.", "Il ___ la télé quand le téléphone a sonné."
B. Options must test plausible imparfait conjugations vs passé composé or présent.
C. Include the subject pronoun visibly in the sentence (je, tu, il/elle, nous, vous, ils/elles) so the student knows which conjugation to pick.
D. Distractors: correct verb but wrong person, passé composé form, présent form, plus-que-parfait form.''';
    }

    // ── Plus-que-parfait ──────────────────────────────────────────────────────
    if (t.contains('plus') && t.contains('parfait')) {
      return '''FOR PLUS-QUE-PARFAIT:
A. The sentence MUST show two past events where one happened BEFORE the other.
   Example: "Quand nous sommes arrivés, il ___ déjà parti."
B. The "before" event = plus-que-parfait; the "after" event = passé composé (show both in the sentence).
C. Options must test: correct auxiliary in imparfait (avait/était), correct past participle, correct agreement.
D. Distractors: imparfait form, passé composé form, wrong auxiliary.''';
    }

    // ── Futur Simple ──────────────────────────────────────────────────────────
    if (t.contains('futur simple')) {
      return '''FOR FUTUR SIMPLE:
A. The sentence MUST include a future time marker (e.g., "demain", "la semaine prochaine", "dans deux ans", "un jour").
B. Each question should test a specific conjugation (focus on irregular stems: être → ser-, avoir → aur-, aller → ir-).
C. Options must test: correct futur simple form vs futur proche (aller + infinitif) vs présent vs conditionnel.
D. Include the subject pronoun clearly in the sentence.''';
    }

    // ── Futur Proche ─────────────────────────────────────────────────────────
    if (t.contains('futur proche')) {
      return '''FOR FUTUR PROCHE (aller + infinitif):
A. The sentence MUST show an imminent or planned action with a time clue (e.g., "ce soir", "dans cinq minutes", "bientôt").
B. The blank should test the conjugated form of "aller" OR the infinitive placement.
   Example: "Nous ___ visiter le musée ce week-end." (allons)
C. Options: correct "aller" conjugation vs wrong person, futur simple form, présent form, passé composé.''';
    }

    // ── Conditionnel ──────────────────────────────────────────────────────────
    if (t.contains('conditionnel')) {
      return '''FOR CONDITIONNEL:
A. Always provide a clear hypothetical context with "si" + imparfait or a polite request context.
   Examples: "Si j'avais de l'argent, j'___ un appartement.", "Je ___ un café, s'il vous plaît."
B. Options must test: correct conditionnel form vs futur simple, imparfait, présent.
C. Distractors should use the same verb but in wrong tense (e.g., "achèterai" vs "achèterais").''';
    }

    // ── Subjonctif ────────────────────────────────────────────────────────────
    if (t.contains('subjonctif')) {
      return '''FOR SUBJONCTIF:
A. The sentence MUST include a trigger phrase that requires subjonctif (e.g., "Il faut que", "Je veux que", "Bien que", "Pour que", "à condition que").
   Example: "Il faut que tu ___ tes devoirs avant ce soir." (fasses)
B. The trigger phrase MUST be visible in the question sentence — never ask for subjonctif without showing the trigger.
C. Options must contrast: correct subjonctif vs présent indicatif vs infinitif vs imparfait.
D. For irregular subjonctifs, focus on common verbs: être, avoir, aller, faire, pouvoir, vouloir.''';
    }

    // ── Voix Passive ─────────────────────────────────────────────────────────
    if (t.contains('passive') || t.contains('passif') || t.contains('voix')) {
      return '''FOR VOIX PASSIVE:
A. Show the active sentence first, then ask for the passive transformation, OR provide a passive sentence with the blank.
   Example: "Le gâteau ___ par Marie." — options: "a été mangé / est mangé / était mangé / sera mangé"
B. The sentence MUST indicate the tense clearly (past marker, present context, future marker) so the student knows which auxiliary tense to use.
C. Options test: correct auxiliary tense + past participle vs wrong tense, wrong agreement of participle.
D. Include the agent ("par + noun") in the sentence when relevant.''';
    }

    // ── Négation (Negative Complex) ───────────────────────────────────────────
    if (t.contains('négat') || t.contains('negat') || t.contains('negative')) {
      return '''FOR NÉGATION:
A. Provide a positive sentence and ask for the correct negative form, OR provide a sentence with a gap for the negative word.
   Example: "Je ne mange ___ de viande." — options: "jamais / pas / plus / rien"
B. Always show both parts of the negation (ne ... ?) and let the student choose the second part.
C. Options must be all negative adverbs/pronouns: pas, plus, jamais, rien, personne, nulle part, ni...ni.
D. Distractors: other negative words that are grammatically possible but semantically wrong in the given context.''';
    }

    // ── Comparatif / Superlatif ───────────────────────────────────────────────
    if (t.contains('comparatif') || t.contains('superlatif')) {
      return '''FOR COMPARATIF / SUPERLATIF:
A. The sentence MUST clearly provide two items being compared OR the superlative context.
   Example: "Paris est ___ grande que Lyon." or "C'est ___ beau monument de Bruxelles."
B. Options must test: plus / moins / aussi for comparatif; le plus / le moins / le meilleur for superlatif.
C. Distractors: confuse plus/moins/aussi, wrong article agreement (le/la/les), or confuse bon→meilleur / bien→mieux.''';
    }

    // ── Adverbes en -ment ─────────────────────────────────────────────────────
    if (t.contains('adverbe') || t.contains('adverb') || t.contains('ment')) {
      return '''FOR ADVERBES EN -MENT:
A. The sentence MUST show an action and ask for the correct adverb.
   Example: "Elle parle ___ en classe." — options: "lentement / lente / lent / lents"
B. Options must test: correct adverb form vs the adjective (masculine/feminine), misspelled form, another adverb.
C. Include at least 2 questions on irregular adverbs: bien, mal, vite, beaucoup, peu, vraiment, gentiment.''';
    }

    // ── Si Seulement / Hypothèse ──────────────────────────────────────────────
    if (t.contains('si seulement') || t.contains('hypothèse') || t.contains('condition')) {
      return '''FOR SI + HYPOTHÈSE:
A. Always show the complete "si" clause structure. The blank goes in the result clause or the si-clause.
   Example: "Si elle ___ (étudier) davantage, elle réussirait ses examens."
B. Clearly signal which part of the si-structure the blank belongs to:
   - Si + imparfait → conditionnel présent (unreal present)
   - Si + plus-que-parfait → conditionnel passé (unreal past)
C. Options must test: correct tense pairing vs wrong tense combination (common mistakes like si + conditionnel).''';
    }

    // ── Durée / Prepositions of Time ──────────────────────────────────────────
    if (t.contains('durée') || t.contains('duration') || t.contains('préposition') || t.contains('preposition')) {
      return '''FOR PREPOSITIONS OF TIME / DURATION:
A. The sentence MUST clearly show the context (ongoing action, completed action, future timeframe).
   Example: "J'habite à Bruxelles ___ cinq ans." — options: "depuis / pendant / pour / il y a"
B. Options must test: depuis / pendant / pour / il y a / dans — all with distinct meanings.
C. Distractors: confuse depuis (ongoing) vs pendant (completed), or pour (future duration) vs il y a (past point).''';
    }

    // ── Connectors / Articulateurs ────────────────────────────────────────────
    if (t.contains('connector') || t.contains('connecteur') || t.contains('articulateur')) {
      return '''FOR CONNECTORS (Articulateurs logiques):
A. The sentence MUST show a clear logical relationship (cause, consequence, opposition, addition, concession).
   Example: "Il n'a pas pu venir ___ il était malade." — options: "parce que / donc / cependant / de plus"
B. Options must test connectors of different types: cause (parce que, car), conséquence (donc, alors), opposition (mais, cependant, pourtant), addition (de plus, en outre).
C. Distractors: plausible but semantically wrong connectors for that specific sentence.''';
    }

    // ── Présent de l'indicatif ────────────────────────────────────────────────
    if (t.contains('présent') || t.contains('present')) {
      return '''FOR PRÉSENT DE L'INDICATIF:
A. The sentence MUST clearly show a habitual or current action (no time markers that force another tense).
B. Options must test correct conjugation for the subject in the sentence.
   Example: "Ils ___ souvent au restaurant le week-end." — options: "vont / va / allons / allez"
C. Distractors: wrong person (il/elle vs ils/elles), irregular vs regular pattern confusion.
D. Mix regular (-er, -ir, -re) and irregular verbs (être, avoir, aller, faire, prendre, vouloir, pouvoir).''';
    }

    // ── Default fallback ──────────────────────────────────────────────────────
    return '''GENERAL RULES:
A. Every question MUST be a COMPLETE sentence with "___" showing exactly where the answer goes.
B. Provide enough sentence context so only ONE answer is grammatically/logically correct.
C. Options must be plausible distractors of the same grammatical category (all verbs, all pronouns, all adverbs, etc.) — NEVER mix unrelated word types.
D. The explanation in $targetLanguage must clearly state the grammar rule and why each distractor is wrong.''';
  }

  // Generate multiple AI-powered exercises
  static Future<List<Map<String, dynamic>>> generateExercises(
      String topic, String difficulty, String targetLanguage,
      {int count = 10}) async {
    // Build topic-specific guidance so the AI generates unambiguous, complete questions
    final String topicGuidance = _buildTopicGuidance(topic, targetLanguage);

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
                  'You are Professeur AI, an expert French B1 teacher creating crystal-clear multiple-choice exercises. '
                  'ABSOLUTE RULES — violation of any rule makes the exercise useless:\n\n'

                  '── QUESTION FORMAT ──\n'
                  '1. Every question MUST be a COMPLETE French sentence with a visible blank marked as "___".\n'
                  '   ✅ GOOD: "Je ___ mes devoirs hier soir." (fill in passé composé of "faire")\n'
                  '   ❌ BAD:  "Conjugate faire." or "Which tense?" (no sentence = confusing)\n'
                  '2. The "question" field MUST always contain the full sentence with "___" clearly showing WHERE the answer goes.\n'
                  '3. NEVER write a question that is just a word, a verb infinitive, or a short phrase without a sentence context.\n\n'

                  '── OPTIONS FORMAT ──\n'
                  '4. All 4 options MUST be in the same grammatical form (all conjugated verbs, all pronouns, all prepositions — never mix forms).\n'
                  '5. Options MUST be plausible distractors — wrong answers should be believable mistakes (e.g., wrong gender, wrong tense, wrong person), not random words.\n'
                  '6. All 4 options MUST be unique (no duplicates, no near-duplicates).\n\n'

                  '── TOPIC-SPECIFIC RULES ──\n'
                  '$topicGuidance\n\n'

                  '── LANGUAGE RULES ──\n'
                  '7. The "question" sentence and all "options" MUST BE IN FRENCH.\n'
                  '8. The "translation" field: provide the full question sentence translated to $targetLanguage (translate the blank as "___" too).\n'
                  '9. The "explanation" MUST be written entirely in $targetLanguage and must explain WHY the correct answer is right AND why the other options are wrong.\n\n'

                  '── JSON OUTPUT ──\n'
                  'Return a valid JSON object: {"exercises": [ {"question": "...", "translation": "...", "options": ["...", "...", "...", "..."], "correct": 0, "explanation": "..."} ]}'
            },
            {
              'role': 'user',
              'content': topic == 'mixed_review'
                  ? 'Generate $count fill-in-the-blank multiple choice exercises for a comprehensive French B1 General Review covering: Présent, Passé Composé, Imparfait, Futur Simple, Conditionnel, Subjonctif, COD/COI pronouns, Voix Passive, Négation, and L\'Impératif. Each question MUST be a complete French sentence with "___". Difficulty: $difficulty.'
                  : 'Generate $count fill-in-the-blank multiple choice exercises for French B1 topic: "$topic". Each question MUST be a complete French sentence containing "___" where the student fills in the answer. Difficulty: $difficulty. Apply ALL topic-specific rules from the system prompt.'
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
                  'You are Professeur AI, an expert French B1 novelist and teacher. Create an engaging 5-page French story. '
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
                  'Conjugate the French verb "$verb" in the following tenses: Présent, Passé Composé, Imparfait, Plus-que-parfait, Conditionnel, Futur Proche, Futur Simple, Subjonctif.'
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
                  'You are Professeur AI, a French teacher explaining grammar to beginners. Use simple language, clear examples, and helpful metaphors. '
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
                  ? 'You are Professeur AI, a French B1 teacher. Generate a listening dialogue in JSON format. Return a JSON object with keys "text" and "questions" (an array of 5 objects). The "text" MUST be a dialogue script between "Client" and "Agence", where every line starts with "Client:" or "Agence:". Example: "Client: Bonjour...". Each question object must have: "question", "options" (4 strings), "answer" (the correct string from options) which tests comprehension.'
                  : 'You are Professeur AI, a French B1 teacher. Generate a listening exercise in JSON format. Return a JSON object with keys "text" (a ~100 word French story/article) and "questions" (an array of 5 objects). Each question object must have: "question", "options" (4 strings), "answer" (the correct string from options). The text should be suitable for B1 level students.'
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
                  'You are a high-speed translation engine. '
                  'Translate the following text into $targetLanguage. '
                  'STRICT RULES:\n'
                  '1. NO META-TALK: Do NOT say "Here is the translation", "Sure", or "I have translated".\n'
                  '2. NO PREAMBLE: Start immediately with the translated text.\n'
                  '3. PRESERVE FRENCH: Keep French words, conjugations, and examples EXACTLY in French. Only translate the explanations.\n'
                  '4. RAW OUTPUT ONLY: Your response will be used directly in a UI. Any extra text will break the app.\n'
                  '5. Keep symbols (✅, ❌, ♂️, ♀️) exactly as they are.'
            },
            {
              'role': 'user',
              'content': 'TEXT TO TRANSLATE:\n$text'
            }
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String translated = (data['choices']?[0]?['message']?['content'] ?? text).toString().trim();
        
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
                      'THE USER IS CURRENTLY STUDYING THE TOPIC: $topic. \n'
                      'STRICT TOPIC RESTRICTION: \n'
                      '1. You MUST ONLY answer questions related to the current topic ($topic). \n'
                      '2. If the user asks about something completely unrelated (e.g., math, history, or a totally different French grammar point like "Futur Simple" when the topic is "Pronoms Relatifs"), you must politely explain in $targetLanguage that you can only assist with the current lesson topic. \n'
                      '3. If the user asks for more detail or "depth" about the current topic ($topic) that isn\'t explicitly in the lesson, you SHOULD answer it fully. \n'
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

  // Ask a general French language question focusing on B1 grammar/lessons
  static Future<String> askGeneralFrenchQuestion(
      String question, String targetLanguage) async {
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
                  'You are Professeur AI, a helpful French linguistics and pedagogy expert. '
                      'The user is studying French (typically B1 level). '
                      'Answer their question accurately and professionally. '
                      'Focus on explaining French grammar, vocabulary, rules, and conjugations. '
                      'Your entire explanation/answer MUST be written in the requested language: $targetLanguage. '
                      'Use Markdown to format your response (bold keywords, lists, headers, etc.). '
                      'Always include helpful examples in French, along with their translation in $targetLanguage. '
                      'Keep the tone supportive, clear, and pedagogical.'
            },
            {
              'role': 'user',
              'content': question
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in askGeneralFrenchQuestion: $e');
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
              'content': '''ROLE: You are an expert, Professional Belgian French Professor teaching B1 French to $targetLanguage speakers who are COMPLETE BEGINNERS. Think of your students as people who know NOTHING — explain every concept from scratch, step by step, as simply as possible.
GOAL: Write a COMPLETE, EXHAUSTIVE, TEXTBOOK-QUALITY B1 French lesson. This must read like a real chapter from a professional French language textbook — not a quick summary.
AUDIENCE: Total beginners ("dummies") who need everything spelled out clearly. Use simple words, relatable analogies, and real-life situations from Belgium.

══════════════════════════════════════════
  RULE 1 — DEPTH & COMPLETENESS (CRITICAL)
══════════════════════════════════════════
The "widgets" array MUST contain between 15 and 25 widgets. A short lesson is a FAILED lesson.
Before finishing, mentally check this COMPLETENESS CHECKLIST:
✅ Did I explain WHAT this topic is (introduction in simple words)?
✅ Did I explain WHY it is used (purpose/context)?
✅ Did I explain HOW to use it (step-by-step rules or formation)?
✅ Did I give a full vocabulary or phrase list (french_tipbox or table)?
✅ Did I give at least 5 real sentence examples (example widgets)?
✅ Did I cover the most common mistakes / pitfalls?
✅ Did I give a memory tip or learning trick?
If ANY of these are missing, ADD more widgets until all are covered.

══════════════════════════════════════════
  RULE 2 — WIDGET VARIETY (MANDATORY)
══════════════════════════════════════════
- "section_title": Use at least 4 section titles to break up the lesson.
- "text": Use for explanations — write at least 2-3 sentences per text widget, not one-liners.
- "tipbox": Use for key rules, formulas, warnings (colors: purple=rule, yellow=tip, red=warning, blue=info, green=positive).
- "french_tipbox": Use for vocabulary lists, conjugation blocks, or phrase lists ("word -> translation" format).
- "example": MINIMUM 5 example widgets. Each must be a real, natural French sentence with accurate translation.
- "table": Use for any structured data (conjugation tables, comparison tables, vocabulary grids).

══════════════════════════════════════════
  RULE 3 — BELGIAN CONTEXT (STRICT)
══════════════════════════════════════════
Belgian references are ONLY allowed when they are DIRECTLY RELEVANT to the lesson topic.

🚫 FORBIDDEN — Do NOT include Belgian notes for:
   - Verb conjugations (présent, passé composé, imparfait, subjonctif, etc.)
   - Grammar rules (COD, COI, relative pronouns, négation, etc.)
   - Adjective agreement, articles, prepositions
   - Any topic where septante/nonante/soixante-dix is NOT the subject being taught
   The phrase "En Belgique, on dit septante au lieu de soixante-dix" is BANNED unless the lesson topic is specifically about NUMBERS or COUNTING.

✅ ALLOWED — Include a Belgian note ONLY when the topic is:
   - Numbers and counting (septante, nonante, etc. are directly relevant)
   - Meals and food vocabulary (déjeuner/dîner/souper Belgian variants)
   - Belgian institutions (mutualité, CPAS, commune, STIB, TEC) when teaching administrative vocab
   - Geography/travel vocabulary when Belgium is genuinely the topic
   - Belgian cultural customs when teaching social/politeness expressions

When a Belgian note IS included, it must add real learning value — not just say "Belgium is different from France".
All practical examples and sentences must reference Belgium (Bruxelles, Liège, Gand, Namur, etc.) — not Paris or France.

══════════════════════════════════════════
  RULE 4 — CLARITY FOR DUMMIES
══════════════════════════════════════════
- Explain every new term as if the student has never heard it.
- Use analogies and comparisons to their native language ($targetLanguage) where helpful.
- Avoid academic jargon. If you must use a grammar term, explain it immediately in plain language.
- Every rule must be followed by an example. No rule without an example.

══════════════════════════════════════════
  JSON FORMAT
══════════════════════════════════════════
Return ONLY a valid JSON object. NO meta-talk. NO markdown outside JSON.
{
  "title": "Lesson Topic in French",
  "subtitle": "Direct Translation in $targetLanguage",
  "icon": "relevant emoji",
  "widgets": [
    {"type": "section_title", "emoji": "🎯", "title": "Introduction"},
    {"type": "text", "content": "Clear, simple introduction to the topic..."},
    {"type": "tipbox", "title": "Why is this important?", "content": "...", "color": "blue"},
    {"type": "section_title", "emoji": "📚", "title": "Core Vocabulary"},
    {"type": "french_tipbox", "title": "Key Words", "frenchText": "mot -> translation", "color": "green"},
    {"type": "table", "headers": ["French", "English", "Example"], "rows": [["...", "...", "..."]]},
    {"type": "section_title", "emoji": "💬", "title": "How to Use It"},
    {"type": "tipbox", "title": "The Formula", "content": "Structure: ...", "color": "purple"},
    {"type": "example", "french": "...", "translation": "..."},
    {"type": "example", "french": "...", "translation": "..."},
    {"type": "example", "french": "...", "translation": "..."},
    {"type": "section_title", "emoji": "⚠️", "title": "Common Mistakes"},
    {"type": "tipbox", "title": "Attention!", "content": "...", "color": "red"},
    {"type": "example", "french": "...", "translation": "..."},
    {"type": "section_title", "emoji": "💡", "title": "Memory Tip"},
    {"type": "tipbox", "title": "Easy way to remember", "content": "...", "color": "yellow"}
  ]
}
EXPLANATIONS in $targetLanguage. French terms stay in French.'''            },
            {
              'role': 'user',
              'content': pdfText != null
                  ? 'Generate a detailed French B1 lesson based on this PDF: \n\n$pdfText\n\nTopic: $topic. Language: $targetLanguage.'
                  : 'Generate a detailed French B1 lesson about: $topic. Language: $targetLanguage.'
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
              'content': '''ROLE: You are an expert, Professional Belgian French Grammar Professor teaching B1 French to $targetLanguage speakers who are COMPLETE BEGINNERS. Think of your students as "dummies" who know NOTHING — explain every grammar concept from absolute zero, as clearly and simply as possible.
GOAL: Write a COMPLETE, EXHAUSTIVE, TEXTBOOK-QUALITY grammar guide. This must read like a full chapter from a professional French grammar textbook — not a quick overview.
AUDIENCE: Total beginners who need everything explained step by step, with analogies, examples for every rule, and zero assumptions.

══════════════════════════════════════════
  RULE 1 — DEPTH & COMPLETENESS (CRITICAL)
══════════════════════════════════════════
The "widgets" array MUST contain between 15 and 25 widgets. A short guide is a FAILED guide.
Before finishing, mentally check this COMPLETENESS CHECKLIST:
✅ Did I explain WHAT this grammar concept is (introduction with analogy)?
✅ Did I explain WHEN to use it (context and triggers)?
✅ Did I explain HOW to form it (step-by-step formation with formula)?
✅ Did I provide a FULL conjugation table (for verb-based topics)?
✅ Did I cover ALL irregular forms or exceptions?
✅ Did I give at least 6 real sentence examples (example widgets)?
✅ Did I explain the most common mistakes learners make?
✅ Did I give a memory trick or mnemonic to help recall the rule?
✅ Did I contrast this concept with a similar/confusable one if relevant?
If ANY of these are missing, ADD more widgets until all are covered.

══════════════════════════════════════════
  RULE 2 — WIDGET VARIETY (MANDATORY)
══════════════════════════════════════════
- "section_title": Use at least 5 section titles to organize the guide.
- "text": Minimum 2 sentences per text widget. Use simple, clear language with analogies.
- "tipbox" (purple): For core grammar formulas — write the full structure clearly (e.g., "Subject + avoir/être + past participle").
- "tipbox" (yellow): For learning tips and memory tricks.
- "tipbox" (red): For common errors and what NOT to do.
- "french_tipbox" (green): For conjugation groups, verb lists, or step-by-step formation.
- "french_tipbox" (red): For irregular verbs or exception lists.
- "table": MANDATORY for verb conjugations — show ALL 6 pronouns (je, tu, il/elle, nous, vous, ils/elles) with full conjugated forms.
- "example": MINIMUM 6 example widgets. Each must be a real, natural French sentence with a clear translation.

══════════════════════════════════════════
  RULE 3 — BELGIAN CONTEXT (STRICT)
══════════════════════════════════════════
Belgian references are ONLY allowed when they are DIRECTLY RELEVANT to the grammar topic being taught.

🚫 FORBIDDEN — Do NOT add Belgian notes for these grammar topics:
   - Verb tenses (présent, passé composé, imparfait, plus-que-parfait, futur, conditionnel, subjonctif)
   - Object pronouns (COD, COI, en, y)
   - Relative pronouns (qui, que, dont, où)
   - Negation forms (ne...pas, ne...jamais, etc.)
   - Passive voice, adjective agreement, articles, prepositions (général)
   - Any grammar topic where Belgian vocabulary is NOT the subject being taught
   The phrase "En Belgique, on dit septante" is STRICTLY BANNED unless the grammar guide is specifically and ONLY about NUMBERS.
   Do NOT end grammar guides with a generic Belgian cultural note just to seem relevant.

✅ ALLOWED — Add a Belgian note ONLY when the grammar topic explicitly involves:
   - Numbers (septante/nonante are genuinely part of the lesson)
   - Meals/food vocabulary (déjeuner vs dîner vs souper Belgian distinction)
   - Belgian institutions or administrative procedures (when that IS the topic)
   - Politeness registers specific to Belgian culture (when teaching formal/informal speech)

All sentence examples must use Belgian cities and contexts (Bruxelles, Liège, Gand, Namur, Bruges) — never Paris.

══════════════════════════════════════════
  RULE 4 — EXPLAIN LIKE FOR DUMMIES
══════════════════════════════════════════
- Start with a simple real-life analogy before introducing grammar terms.
- Define every grammar term the moment you use it (e.g., "auxiliary verb = the helper verb").
- Never assume the student knows anything. Build from zero.
- Every single rule MUST be immediately followed by a French sentence example.
- After showing the rule, show a common WRONG version too, so students know what to avoid.

══════════════════════════════════════════
  JSON FORMAT
══════════════════════════════════════════
Return ONLY a valid JSON object. NO meta-talk. NO markdown.
{
  "title": "Grammar Topic in French",
  "subtitle": "Translation in $targetLanguage",
  "icon": "relevant emoji",
  "widgets": [
    {"type": "section_title", "emoji": "🎯", "title": "What Is It?"},
    {"type": "text", "content": "Simple analogy + plain-language explanation..."},
    {"type": "section_title", "emoji": "🕰️", "title": "When to Use It"},
    {"type": "tipbox", "title": "Use it when...", "content": "...", "color": "blue"},
    {"type": "example", "french": "...", "translation": "..."},
    {"type": "section_title", "emoji": "📝", "title": "How to Form It"},
    {"type": "tipbox", "title": "La Formule", "content": "Full step-by-step formation", "color": "purple"},
    {"type": "table", "headers": ["Pronom", "Conjugaison", "Exemple"], "rows": [["je", "...", "..."],["tu","...","..."],["il/elle","...","..."],["nous","...","..."],["vous","...","..."],["ils/elles","...","..."]]},
    {"type": "section_title", "emoji": "⚠️", "title": "Irregular Forms & Exceptions"},
    {"type": "french_tipbox", "title": "Irregular Verbs", "frenchText": "verb -> irregular form", "color": "red"},
    {"type": "example", "french": "...", "translation": "..."},
    {"type": "section_title", "emoji": "❌", "title": "Common Mistakes"},
    {"type": "tipbox", "title": "Do NOT say...", "content": "Wrong form -> Correct form + explanation", "color": "red"},
    {"type": "section_title", "emoji": "💡", "title": "Memory Trick"},
    {"type": "tipbox", "title": "Easy way to remember", "content": "...", "color": "yellow"}
  ]
}
EXPLANATIONS in $targetLanguage. French terms stay in French.'''            },
            {
              'role': 'user',
              'content': pdfText != null
                  ? 'Generate a detailed French B1 grammar guide based on this PDF: \n\n$pdfText\n\nTopic: $topic. Language: $targetLanguage.'
                  : 'Generate a detailed French B1 grammar guide about: $topic. Language: $targetLanguage.'
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
                  'You are Professeur AI, a professional French novelist and pedagogical expert. Generate a RICH, engaging, and detailed B1-level story in JSON format. '
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
              'content': '''ROLE: You are an expert, Professional Belgian French Professor teaching B1 French to $targetLanguage speakers who are COMPLETE BEGINNERS. Think of your students as "dummies" who know NOTHING — explain every concept from scratch, step by step, as simply as possible.
GOAL: Based on this multi-page lesson description: "$description", write a COMPLETE, EXHAUSTIVE, TEXTBOOK-QUALITY B1 French lesson. This must read like a real chapter from a professional French language textbook — not a quick summary.
AUDIENCE: Total beginners who need everything spelled out clearly. Use simple words, relatable analogies, and real-life situations from Belgium.

══════════════════════════════════════════
  RULE 1 — DEPTH & COMPLETENESS (CRITICAL)
══════════════════════════════════════════
The "widgets" array MUST contain between 15 and 25 widgets. A short lesson is a FAILED lesson.
Before finishing, mentally check this COMPLETENESS CHECKLIST:
✅ Did I explain WHAT this topic is (introduction in simple words)?
✅ Did I explain WHY it is used (purpose/context)?
✅ Did I explain HOW to use it (rules or formation)?
✅ Did I give a full vocabulary or phrase list (french_tipbox or table)?
✅ Did I give at least 5 real sentence examples (example widgets)?
✅ Did I cover the most common mistakes / pitfalls?
✅ Did I give a memory tip or learning trick?
If ANY of these are missing, ADD more widgets until all are covered.

══════════════════════════════════════════
  RULE 2 — WIDGET VARIETY (MANDATORY)
══════════════════════════════════════════
- "section_title": Use at least 4 section titles to break up the lesson.
- "text": Use for explanations — write at least 2-3 sentences per text widget, not one-liners.
- "tipbox": Use for key rules, formulas, warnings (colors: purple=rule, yellow=tip, red=warning, blue=info, green=positive).
- "french_tipbox": Use for vocabulary lists, conjugation blocks, or phrase lists ("word -> translation" format).
- "example": MINIMUM 5 example widgets. Each must be a real, natural French sentence with accurate translation.
- "table": Use for any structured data (conjugation tables, comparison tables, vocabulary grids).

══════════════════════════════════════════
  RULE 3 — BELGIAN CONTEXT (STRICT)
══════════════════════════════════════════
Belgian references are ONLY allowed when they are DIRECTLY RELEVANT to the lesson topic.

🚫 FORBIDDEN — Do NOT include Belgian notes for:
   - Verb conjugations (présent, passé composé, imparfait, subjonctif, etc.)
   - Grammar rules (COD, COI, relative pronouns, négation, etc.)
   - Adjective agreement, articles, prepositions
   - Any topic where septante/nonante/soixante-dix is NOT the subject being taught
   The phrase "En Belgique, on dit septante au lieu de soixante-dix" is BANNED unless the lesson topic is specifically about NUMBERS or COUNTING.

✅ ALLOWED — Include a Belgian note ONLY when the topic is:
   - Numbers and counting (septante, nonante, etc. are directly relevant)
   - Meals and food vocabulary (déjeuner/dîner/souper Belgian variants)
   - Belgian institutions (mutualité, CPAS, commune, STIB, TEC) when teaching administrative vocab
   - Geography/travel vocabulary when Belgium is genuinely the topic
   - Belgian cultural customs when teaching social/politeness expressions

When a Belgian note IS included, it must add real learning value — not just say "Belgium is different from France".
All practical examples and sentences must reference Belgium (Bruxelles, Liège, Gand, Namur, etc.) — not Paris or France.

══════════════════════════════════════════
  RULE 4 — CLARITY FOR DUMMIES
══════════════════════════════════════════
- Explain every new term as if the student has never heard it.
- Use analogies and comparisons to their native language ($targetLanguage) where helpful.
- Avoid academic jargon. If you must use a grammar term, explain it immediately in plain language.
- Every rule must be followed by an example. No rule without an example.

══════════════════════════════════════════
  JSON FORMAT
══════════════════════════════════════════
Return ONLY a valid JSON object. NO meta-talk. NO markdown outside JSON.
{
  "title": "Lesson Topic in French",
  "subtitle": "Direct Translation in $targetLanguage",
  "icon": "relevant emoji",
  "widgets": [
    {"type": "section_title", "emoji": "🎯", "title": "Introduction"},
    {"type": "text", "content": "Clear, simple introduction to the topic..."},
    {"type": "tipbox", "title": "Why is this important?", "content": "...", "color": "blue"},
    {"type": "section_title", "emoji": "📚", "title": "Core Vocabulary"},
    {"type": "french_tipbox", "title": "Key Words", "frenchText": "mot -> translation", "color": "green"},
    {"type": "table", "headers": ["French", "English", "Example"], "rows": [["...", "...", "..."]]},
    {"type": "section_title", "emoji": "💬", "title": "How to Use It"},
    {"type": "tipbox", "title": "The Formula", "content": "Structure: ...", "color": "purple"},
    {"type": "example", "french": "...", "translation": "..."},
    {"type": "example", "french": "...", "translation": "..."},
    {"type": "example", "french": "...", "translation": "..."},
    {"type": "section_title", "emoji": "⚠️", "title": "Common Mistakes"},
    {"type": "tipbox", "title": "Attention!", "content": "...", "color": "red"},
    {"type": "example", "french": "...", "translation": "..."},
    {"type": "section_title", "emoji": "💡", "title": "Memory Tip"},
    {"type": "tipbox", "title": "Easy way to remember", "content": "...", "color": "yellow"}
  ]
}
EXPLANATIONS in $targetLanguage. French terms stay in French.'''
            },
            {
              'role': 'user',
              'content': 'Based on this multi-page lesson description: "$description", create a cohesive, detailed French B1 lesson. Apply all rules.'
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
    String topic,
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
                  'You are an expert French B1 teacher. The user has provided multiple images (pages) described as: "$description". \n'
                  'THE USER IS CURRENTLY STUDYING THE TOPIC: $topic. \n'
                  'STRICT TOPIC RESTRICTION: \n'
                  '1. You MUST ONLY answer the user\'s question if it is related to the current topic ($topic) or the content of the provided images. \n'
                  '2. If the user asks about something completely unrelated to the images or the topic $topic, politely inform them in $targetLanguage that you can only help with this specific lesson. \n'
                  '3. If the question is about the topic/images but seeks deeper understanding or more examples, please answer thoroughly. \n'
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

  // ── Helper: Build a summary of existing content to give AI context ────────

  /// Builds a compact text summary of existing widgets so AI knows context without needing raw JSON
  static String _buildContentSummary(List<dynamic> widgets) {
    if (widgets.isEmpty) return '(Empty lesson - no existing content)';
    final buffer = StringBuffer();
    int i = 0;
    for (final w in widgets) {
      if (w is! Map) continue;
      i++;
      final type = w['type'] ?? 'unknown';
      switch (type) {
        case 'section_title':
          buffer.writeln('- Section: ${w['title'] ?? ''}');
          break;
        case 'text':
          final content = (w['content'] ?? '').toString();
          buffer.writeln('- Text: ${content.length > 60 ? '${content.substring(0, 60)}...' : content}');
          break;
        case 'example':
          buffer.writeln('- Example: ${w['french'] ?? ''}');
          break;
        case 'tipbox':
          buffer.writeln('- Tip: ${w['title'] ?? ''}');
          break;
        case 'french_tipbox':
          buffer.writeln('- French Tip: ${w['title'] ?? ''}');
          break;
        case 'table':
          buffer.writeln('- Table: ${(w['headers'] as List?)?.join(', ') ?? ''}');
          break;
        default:
          buffer.writeln('- [$type]');
      }
      if (i >= 30) {
        buffer.writeln('... and ${widgets.length - 30} more widgets');
        break;
      }
    }
    return buffer.toString();
  }

  static Future<Map<String, dynamic>> updateLessonFromImages(
    Map<String, dynamic> existingLesson,
    List<String> newBase64Images,
    String mimeType,
    String targetLanguage,
    String? userInstructions,
  ) async {
    try {
      final newDescription = await GeminiService.describeImages(newBase64Images, mimeType);
      if (newDescription.startsWith('ERROR') || newDescription.startsWith('EXCEPTION')) {
        throw Exception(newDescription);
      }

      final existingWidgets = existingLesson['widgets'] ?? existingLesson['content'] ?? [];
      final String existingSummary = _buildContentSummary(existingWidgets is List ? existingWidgets : []);

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
              'content': '''You are Professeur AI, an expert teacher for BELGIUM. Generate ONLY NEW widgets from photos to ADD to an existing lesson.
STRICT RULES:
1. BELGIAN FOCUS: Use Belgian context (Bruxelles, Liège) and Belgian French vocabulary ONLY when relevant to the content being taught. Do NOT force these terms if they do not fit (e.g. verb tenses, object pronouns, negation, passive voice). The phrase 'En Belgique, on dit septante' is BANNED unless numbers or meals are the subject. All practical examples must reference Belgium (Bruxelles, Liège, Namur, Gand) — never Paris.
2. JSON FORMAT: Return ONLY a valid JSON object.
3. CRITICAL: Return ONLY new content. Do NOT reproduce existing content.

The lesson "${existingLesson['title']}" already contains:
$existingSummary

RETURN FORMAT: {"new_widgets": [<only new widgets here>]}
WIDGET TYPES: section_title, text, french_tipbox, tipbox, example, table.
RULES: IGNORE handwritten Arabic notes. NO META-TALK. Explanations in $targetLanguage.'''
            },
            {
              'role': 'user',
              'content': 'NEW TEXTBOOK CONTENT:\n$newDescription${userInstructions != null ? '\n\nUSER INSTRUCTIONS: $userInstructions' : ''}'
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final result = jsonDecode(content);
        result['id'] = existingLesson['id'];
        result['title'] = existingLesson['title'];
        result['subtitle'] = existingLesson['subtitle'];
        result['icon'] = existingLesson['icon'];
        return result;
      } else {
        debugPrint('❌ DeepSeek update error ${response.statusCode}');
        throw Exception('DeepSeek update error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating lesson: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateLessonWithPdf(
    Map<String, dynamic> existingLesson,
    String newPdfText,
    String targetLanguage,
    String? userInstructions,
  ) async {
    try {
      final existingWidgets = existingLesson['widgets'] ?? existingLesson['content'] ?? [];
      final String existingSummary = _buildContentSummary(existingWidgets is List ? existingWidgets : []);

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
              'content': '''You are Professeur AI, an expert teacher for BELGIUM. Generate ONLY NEW widgets from PDF text to ADD to an existing lesson.
STRICT RULES:
1. BELGIAN FOCUS: Use Belgian context (Bruxelles, Liège) and Belgian French vocabulary ONLY when relevant to the content being taught. Do NOT force these terms if they do not fit (e.g. verb tenses, object pronouns, negation, passive voice). The phrase 'En Belgique, on dit septante' is BANNED unless numbers or meals are the subject. All practical examples must reference Belgium (Bruxelles, Liège, Namur, Gand) — never Paris.
2. JSON FORMAT: Return ONLY a valid JSON object.
3. CRITICAL: Return ONLY new content. Do NOT reproduce existing content.

The lesson "${existingLesson['title']}" already contains:
$existingSummary

RETURN FORMAT: {"new_widgets": [<only new widgets here>]}
WIDGET TYPES: section_title, text, french_tipbox, example, tipbox, table.
RULES: NO META-TALK. French stays French. Explanations in $targetLanguage.'''
            },
            {
              'role': 'user',
              'content': 'NEW PDF TEXT:\n$newPdfText${userInstructions != null ? '\n\nUSER INSTRUCTIONS: $userInstructions' : ''}'
            }
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final result = jsonDecode(content);
        result['id'] = existingLesson['id'];
        result['title'] = existingLesson['title'];
        result['subtitle'] = existingLesson['subtitle'];
        result['icon'] = existingLesson['icon'];
        return result;
      } else {
        throw Exception('DeepSeek PDF update error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating lesson with PDF: $e');
      rethrow;
    }
  }

  // ── Update an existing grammar guide with new photos ─────────────────────
  static Future<Map<String, dynamic>> updateGrammarFromImages(
    Map<String, dynamic> existingGrammar,
    List<String> newBase64Images,
    String mimeType,
    String targetLanguage,
    String? userInstructions,
  ) async {
    try {
      final newDescription = await GeminiService.describeImages(newBase64Images, mimeType);
      if (newDescription.startsWith('ERROR')) throw Exception(newDescription);

      final existingWidgets = existingGrammar['widgets'] ?? existingGrammar['content'] ?? [];
      final String existingSummary = _buildContentSummary(existingWidgets is List ? existingWidgets : []);

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
              'content': '''You are Professeur AI, an expert teacher for BELGIUM. Generate ONLY NEW widgets from photos to ADD to an existing grammar guide.
STRICT RULES:
1. BELGIAN FOCUS: Use Belgian context (Bruxelles, Liège) and Belgian French vocabulary ONLY when relevant to the content being taught. Do NOT force these terms if they do not fit (e.g. verb tenses, object pronouns, negation, passive voice). The phrase 'En Belgique, on dit septante' is BANNED unless numbers or meals are the subject. All practical examples must reference Belgium (Bruxelles, Liège, Namur, Gand) — never Paris.
2. JSON FORMAT: Return ONLY a valid JSON object.
3. CRITICAL: Return ONLY new content. Do NOT reproduce existing content.

The grammar guide "${existingGrammar['title']}" already contains:
$existingSummary

RETURN FORMAT: {"new_widgets": [<only new widgets here>]}
PREMIUM STYLE: TipBox (purple) for Formulas. FrenchTipBox (green) for Conjugations. TipBox (yellow) for Tips. FrenchTipBox (red) for Irregulars.
RULES: IGNORE handwritten Arabic notes. NO META-TALK. Explanations in $targetLanguage.'''
            },
            {
              'role': 'user',
              'content': 'NEW TEXTBOOK CONTENT:\n$newDescription${userInstructions != null ? '\n\nUSER INSTRUCTIONS: $userInstructions' : ''}'
            }
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final result = jsonDecode(content);
        result['id'] = existingGrammar['id'];
        result['title'] = existingGrammar['title'];
        result['subtitle'] = existingGrammar['subtitle'];
        result['icon'] = existingGrammar['icon'];
        return result;
      } else {
        throw Exception('DeepSeek Image update error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating grammar: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateGrammarWithPdf(
    Map<String, dynamic> existingGrammar,
    String newPdfText,
    String targetLanguage,
    String? userInstructions,
  ) async {
    try {
      final existingWidgets = existingGrammar['widgets'] ?? existingGrammar['content'] ?? [];
      final String existingSummary = _buildContentSummary(existingWidgets is List ? existingWidgets : []);

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
              'content': '''You are Professeur AI, an expert teacher for BELGIUM. Generate ONLY NEW widgets from PDF text to ADD to an existing grammar guide.
STRICT RULES:
1. BELGIAN FOCUS: Use Belgian context (Bruxelles, Liège) and Belgian French vocabulary ONLY when relevant to the content being taught. Do NOT force these terms if they do not fit (e.g. verb tenses, object pronouns, negation, passive voice). The phrase 'En Belgique, on dit septante' is BANNED unless numbers or meals are the subject. All practical examples must reference Belgium (Bruxelles, Liège, Namur, Gand) — never Paris.
2. JSON FORMAT: Return ONLY a valid JSON object.
3. CRITICAL: Return ONLY new content. Do NOT reproduce existing content.

The grammar guide "${existingGrammar['title']}" already contains:
$existingSummary

RETURN FORMAT: {"new_widgets": [<only new widgets here>]}
RULES: NO META-TALK. French stays French. Explanations in $targetLanguage.'''
            },
            {
              'role': 'user',
              'content': 'NEW PDF TEXT:\n$newPdfText${userInstructions != null ? '\n\nUSER INSTRUCTIONS: $userInstructions' : ''}'
            }
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final result = jsonDecode(content);
        result['id'] = existingGrammar['id'];
        result['title'] = existingGrammar['title'];
        result['subtitle'] = existingGrammar['subtitle'];
        result['icon'] = existingGrammar['icon'];
        return result;
      } else {
        throw Exception('DeepSeek Grammar update error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating grammar with PDF: $e');
      rethrow;
    }
  }

  // ── Update an existing lesson with user instructions (AI Update) ────────
  static Future<Map<String, dynamic>> updateLessonWithAI(
    Map<String, dynamic> existingLesson,
    String userInstructions,
    String targetLanguage,
  ) async {
    try {
      // Send only a SUMMARY of existing content (titles/types) to avoid reproduction
      final existingWidgets = existingLesson['widgets'] ?? existingLesson['content'] ?? [];
      final String existingSummary = _buildContentSummary(existingWidgets is List ? existingWidgets : []);

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
              'content': '''You are Professeur AI, an expert French teacher specialized in the BELGIAN context.
TARGET AUDIENCE: Students living in or moving to BELGIUM.

STRICT RULES:
1. FOCUS: BELGIUM. Use examples from Bruxelles, Liège, Namur, etc. ONLY when relevant.
2. LEGAL/CULTURE: Use Belgian labor laws, social systems, and cultural norms (e.g. Actiris, Forem, CPAS) ONLY if directly relevant to the topic. Do NOT force them if unrelated.
3. VOCABULARY: Use Belgian French (e.g., 'septante', 'nonante', 'déjeuner/dîner/souper' logic) ONLY when directly relevant to the content. Do NOT force these terms if they do not fit the context (e.g. verb tenses, object pronouns, negation, passive voice). The phrase 'En Belgique, on dit septante' is BANNED unless numbers or meals are the subject.
4. NO FRANCE: Never use 'In France' or Paris-based examples. All practical examples must reference Belgium — never Paris.

CRITICAL: You must ONLY return NEW content. Do NOT reproduce any existing content.

The lesson "${existingLesson['title']}" already contains:
$existingSummary

RETURN FORMAT:
{"new_widgets": [<only new widgets here>]}

WIDGET TYPES:
1. {"type": "section_title", "emoji": "...", "title": "..."}
2. {"type": "text", "content": "... in $targetLanguage"}
3. {"type": "french_tipbox", "title": "...", "frenchText": "word → translation", "color": "blue"}
4. {"type": "tipbox", "title": "...", "content": "...", "color": "blue|green|yellow|red|purple"}
5. {"type": "example", "french": "...", "translation": "... in $targetLanguage"}
6. {"type": "table", "headers": [...], "rows": [[...]]}

RULES:
- NO META-TALK (apologies, intros, or explanations) inside JSON values. 
- Return ONLY the JSON object.
- Explanations in $targetLanguage.
- French terms stay in French.
- Do NOT repeat any existing content.
- If you cannot perform the task, return an empty new_widgets list. NEVER return an apology string.'''
            },
            {
              'role': 'user',
              'content': 'ADD the following to the lesson:\n$userInstructions'
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final result = jsonDecode(content);
        // Preserve metadata
        result['id'] = existingLesson['id'];
        result['title'] = existingLesson['title'];
        result['subtitle'] = existingLesson['subtitle'];
        result['icon'] = existingLesson['icon'];
        return result;
      } else {
        throw Exception('DeepSeek AI update error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating lesson with AI: $e');
      rethrow;
    }
  }

  // ── Update an existing grammar guide with user instructions (AI Update) ──
  static Future<Map<String, dynamic>> updateGrammarWithAI(
    Map<String, dynamic> existingGrammar,
    String userInstructions,
    String targetLanguage,
  ) async {
    try {
      final existingWidgets = existingGrammar['widgets'] ?? existingGrammar['content'] ?? [];
      final String existingSummary = _buildContentSummary(existingWidgets is List ? existingWidgets : []);

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
              'content': '''You are Professeur AI, an expert French teacher specialized in the BELGIAN context. 
Generate ONLY NEW widgets to ADD to an existing grammar guide for students in BELGIUM.
 
STRICT RULES:
1. FOCUS: BELGIUM. Use Belgian French vocabulary (e.g. septante, nonante, déjeuner/dîner/souper) and context (Bruxelles, Liège) ONLY when relevant to the grammar topic. Do NOT force these terms if they do not fit the context (e.g. verb tenses, object pronouns, negation, passive voice). The phrase 'En Belgique, on dit septante' is BANNED unless numbers or meals are the subject.
2. CULTURE: Use Belgian cities (Bruxelles, Liège, Namur, Gand) and norms ONLY if they naturally fit the context. Never use Paris or French-based examples.
3. JSON FORMAT: Return ONLY a valid JSON object.
4. CRITICAL: Return ONLY new content. Do NOT reproduce existing content.
 
The grammar guide "${existingGrammar['title']}" already contains:
$existingSummary
 
RETURN FORMAT:
{"new_widgets": [<only new widgets here>]}

WIDGET TYPES:
1. {"type": "section_title", "emoji": "...", "title": "..."}
2. {"type": "text", "content": "... in $targetLanguage"}
3. {"type": "french_tipbox", "title": "...", "frenchText": "word → translation", "color": "blue|green|yellow|red|purple"}
4. {"type": "tipbox", "title": "...", "content": "...", "color": "blue|green|yellow|red|purple"}
5. {"type": "example", "french": "...", "translation": "... in $targetLanguage"}
6. {"type": "table", "headers": ["Header1", "Header2"], "rows": [["cell1", "cell2"]]}

PREMIUM STYLE:
- TipBox (purple) for Formulas. FrenchTipBox (green) for Step-by-step.
- TipBox (yellow) for Tips. FrenchTipBox (red) for Irregulars.
- Use table type for conjugation/grammar tables.
 
Explanations in $targetLanguage. NO META-TALK.'''
            },
            {
              'role': 'user',
              'content': 'ADD the following to the grammar guide:\n$userInstructions'
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final result = jsonDecode(content);
        result['id'] = existingGrammar['id'];
        result['title'] = existingGrammar['title'];
        result['subtitle'] = existingGrammar['subtitle'];
        result['icon'] = existingGrammar['icon'];
        return result;
      } else {
        throw Exception('DeepSeek Grammar AI update error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating grammar with AI: $e');
      rethrow;
    }
  }

  // ── Generate a complete FLE Exam covering Listening, Grammar, Reading, and Writing ──
  static Future<Map<String, dynamic>> generateExam(String targetLanguage) async {
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
              'content': '''ROLE: You are an expert Belgian French FLE Examiner constructing a premium French B1/A2 exam for B1 level students.
GOAL: Generate a complete evaluation exam in JSON format.

The exam MUST consist of the following sections:

1. LISTENING SECTION (Compréhension Orale) — 3 EXERCISES:

EXERCISE A (Vrai / Faux / On ne sait pas):
   - Choose randomly between the theme "la santé" or "le travail".
   - Generate a main audio scenario (realistic spoken French, A2 level, ~100-140 words) a student would listen to.
   - Create exactly 6 statements about this scenario:
     - At least 2 must be TRUE (answer: "vrai").
     - At least 2 must be FALSE (answer: "faux").
     - At least 1 must be CANNOT BE DETERMINED from the audio (answer: "on ne sait pas").
   - Each "vrai" or "faux" answer must be clearly provable from the script. "on ne sait pas" must be genuinely ambiguous.

EXERCISE B (Choix Multiple a/b/c):
   - Based on the SAME audio scenario from Exercise A — do NOT write a new audio script.
   - Create exactly 5 multiple-choice questions, each with exactly 3 options (a, b, c — NOT 4 options).
   - Test specific comprehension details. "correct" index: 0=option a, 1=option b, 2=option c.
   - Include an "explanation" field in $targetLanguage for each question.

EXERCISE C (Association Dialogues → Situations):
   - Generate 4 short, separate French mini-dialogues (2-4 lines each, between speakers labeled "A:" and "B:").
   - The dialogues must be different from the Exercise A audio.
   - Generate exactly 6 situation labels (e.g., "A. Annuler un rendez-vous", "B. Commander quelque chose", etc.).
   - Only 4 of the 6 situations correspond to a dialogue. The other 2 are unused distractors.
   - "answers" is an array of 4 integers: for each dialogue index 0→3, the index 0→5 of its correct situation.
   - All 4 answer values MUST be different (each situation used at most once). The 2 unused indices must NOT appear in answers.


2. GRAMMAR SECTION (Grammaire):
   - Create exactly 8 multiple-choice questions testing the following:
     - 2 questions on Conditionnel (Conditionnel présent)
     - 2 questions on La voix passive (Passive voice transformations/agreement)
     - 2 questions on COD / COI (Direct/Indirect object pronouns: le, la, les, lui, leur, etc.)
     - 2 questions on L'Impératif (Imperative mood: orders, advice, prohibition — tu/nous/vous forms, irregular imperatives: être→sois, avoir→aie, aller→va, savoir→sache)
   - COD/COI pronoun questions MUST identify the object noun's gender and number in the preceding sentence context before asking for the pronoun.
     ✅ GOOD: "Marie parle à son professeur. Elle ___ téléphone souvent." (COI -> lui)
     ❌ BAD: "Elle ___ téléphone." (unclear reference)
   - Impératif questions MUST provide a clear context (order, advice, instruction) and test plausible confusions:
     ✅ GOOD: "Tu veux donner un conseil. ___ attention à ta santé !" — options: "Fais / Fait / Faire / Faites"
     - Test tu/nous/vous forms and irregular imperatives (va, sois, aie, sache).
     - Distractors: wrong person (tu vs vous form), présent indicatif form confused with impératif, infinitif.
   - Questions and options must be in French. Explication in $targetLanguage.

3. READING SECTION (Compréhension Écrite):
   - Generate a reading comprehension text (B1 level, ~120-180 words) in French.
   - Create exactly 3 multiple-choice comprehension questions about this text in French.
   - Options in French. Explication in $targetLanguage.

4. WRITING SECTION (Expression Écrite):
   - Choose exactly ONE of these three prompts randomly:
     - Option A (health): "Écrivez des conseils à un ami pour prendre soin de sa santé." (Write advice to a friend to take care of their health)
     - Option B (interview): "Écrivez des conseils pour réussir un entretien d'embauche." (Write advice about a job interview)
     - Option C (career_shift): "Rédigez un essai sur une reconversion professionnelle. Présentez-vous avec votre carrière actuelle, la carrière vers laquelle vous souhaitez vous orienter et pourquoi, ainsi que vos projets d'avenir." (Write an essay about shifting careers: current career, target career, why, and future plans)
   - Provide a "topic_id" (health, interview, or career_shift), a "topic_title" (in French), and a detailed "prompt" instruction in French and $targetLanguage.

STRICT FORMATTING AND QUALITY RULES:
- Grammar, Reading MCQ questions must have exactly 4 unique options. Listening Exercise B has exactly 3 options.
- The "correct" index for 4-option questions must be 0, 1, 2, or 3. For 3-option listening B questions, 0, 1, or 2.
- No markdown or meta-talk. Return ONLY a valid JSON object.
- The output JSON structure MUST match this schema:
{
  "listening": {
    "theme": "sante" or "travail",
    "exercise1": {
      "audio_script": "Main audio scenario text (used for both Exercise A and Exercise B)...",
      "statements": [
        {"statement": "...", "answer": "vrai"},
        {"statement": "...", "answer": "faux"},
        {"statement": "...", "answer": "on ne sait pas"},
        {"statement": "...", "answer": "vrai"},
        {"statement": "...", "answer": "faux"},
        {"statement": "...", "answer": "faux"}
      ]
    },
    "exercise2": {
      "questions": [
        {"question": "...", "options": ["a. ...", "b. ...", "c. ..."], "correct": 1, "explanation": "..."},
        {"question": "...", "options": ["a. ...", "b. ...", "c. ..."], "correct": 0, "explanation": "..."},
        {"question": "...", "options": ["a. ...", "b. ...", "c. ..."], "correct": 2, "explanation": "..."},
        {"question": "...", "options": ["a. ...", "b. ...", "c. ..."], "correct": 1, "explanation": "..."},
        {"question": "...", "options": ["a. ...", "b. ...", "c. ..."], "correct": 0, "explanation": "..."}
      ]
    },
    "exercise3": {
      "dialogues": [
        {"id": 1, "script": "A: ...\nB: ..."},
        {"id": 2, "script": "A: ...\nB: ...\nA: ..."},
        {"id": 3, "script": "A: ...\nB: ..."},
        {"id": 4, "script": "A: ...\nB: ...\nA: ..."}
      ],
      "situations": ["A. ...", "B. ...", "C. ...", "D. ...", "E. ...", "F. ..."],
      "answers": [5, 4, 0, 2]
    }
  },
  "grammar": [
    {
      "question": "...",
      "options": ["...", "...", "...", "..."],
      "correct": 0,
      "explanation": "..."
    }
  ],
  "reading": {
    "text": "The reading passage...",
    "questions": [
      {
        "question": "...",
        "options": ["...", "...", "...", "..."],
        "correct": 0,
        "explanation": "..."
      }
    ]
  },
  "writing": {
    "topic_id": "health" or "interview" or "career_shift",
    "topic_title": "...",
    "prompt": "..."
  }
}'''
            },
            {
              'role': 'user',
              'content': 'Generate a complete French evaluation exam. Target language for explanations is $targetLanguage.'
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['choices'][0]['message']['content']);
      } else {
        throw Exception('Failed to generate exam: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating exam: $e');
      rethrow;
    }
  }

  // ── Grade and evaluate the student's B1 essay ──
  static Future<Map<String, dynamic>> gradeEssay(
      String topic, String essayText, String targetLanguage) async {
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
              'content': '''ROLE: You are an expert French FLE evaluator. Evaluate the student's B1-level essay.
Evaluate based on:
1. Relevance to the topic: "$topic"
2. Grammatical correctness (conjugation, agreement, word order)
3. Vocabulary rich and appropriate to B1 level
4. Structure and flow

Provide constructive feedback and correction of errors.
Your feedback and explanations MUST be written in $targetLanguage.
Return ONLY valid JSON in this format:
{
  "score": 85, // out of 100
  "feedback": "Encouraging evaluation and feedback in $targetLanguage...",
  "corrections": [
    {
      "original": "error phrase in student essay",
      "corrected": "corrected phrase in French",
      "explanation": "Why this correction was made, in $targetLanguage"
    }
  ]
}'''
            },
            {
              'role': 'user',
              'content': 'Essay Topic: $topic\nStudent Essay:\n$essayText'
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['choices'][0]['message']['content']);
      } else {
        throw Exception('Failed to grade essay: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error grading essay: $e');
      rethrow;
    }
  }
}
