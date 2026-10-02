import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/vocabulary_data.dart';
import 'deepseek_service.dart';
import 'practice_logic.dart';

/// One duel question: tap the right option among 2–4.
class DuelQuestion {
  final String prompt; // French or English (translated on screen)
  final bool promptIsEnglish;
  final String hint;
  final List<String> options;
  final int correct;
  final int level; // 1 easy, 2 medium, 3 hard

  const DuelQuestion(this.prompt, this.promptIsEnglish, this.hint, this.options, this.correct, {this.level = 2});

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'english': promptIsEnglish,
        'hint': hint,
        'options': options,
        'correct': correct,
        'level': level,
      };

  /// Null when the stored question is not usable.
  static DuelQuestion? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final options = [for (final o in (raw['options'] as List? ?? const [])) '$o'.trim()];
    final correct = raw['correct'];
    final prompt = '${raw['prompt'] ?? ''}'.trim();
    if (prompt.isEmpty || options.length < 2 || correct is! num || correct < 0 || correct >= options.length) {
      return null;
    }
    if (options.toSet().length != options.length || options.any((o) => o.isEmpty)) return null;
    final level = raw['level'];
    return DuelQuestion(prompt, raw['english'] == true, '${raw['hint'] ?? ''}'.trim(), options, correct.toInt(),
        level: level is num ? level.toInt().clamp(1, 3) : 2);
  }
}

/// What a duel covers: conjugation, vocabulary and/or grammar topics (by title).
class DuelTopics {
  static const conjugation = 'Conjugaison';
  static const vocabulary = 'Vocabulaire';

  final bool withConjugation;
  final bool withVocabulary;
  final List<String> grammar;

  const DuelTopics({this.withConjugation = true, this.withVocabulary = true, this.grammar = const []});

  bool get isEmpty => !withConjugation && !withVocabulary && grammar.isEmpty;

  /// Names shown to the players, e.g. "Conjugaison · Le Subjonctif".
  List<String> get names => [if (withConjugation) conjugation, if (withVocabulary) vocabulary, ...grammar];
}

/// Builds the questions of a new duel, easy first, then medium, then hard.
class DuelBuilder {
  /// Number of questions the creator can choose.
  static const counts = [5, 10, 15, 20];

  /// The AI call. Tests replace it with a fake.
  @visibleForTesting
  static Future<Map<String, dynamic>> Function(
    List<Map<String, dynamic>> messages, {
    bool thinking,
    double? temperature,
    int? maxTokens,
  }) chat = DeepSeekService.chatJson;

  /// [grammarRules] gives, per chosen grammar topic, the rules its lesson
  /// teaches (section titles), so the questions match what was studied.
  static Future<List<DuelQuestion>> build(
    DuelTopics topics, {
    int count = 10,
    Map<String, List<String>> grammarRules = const {},
    Random? random,
  }) async {
    final r = random ?? Random();
    final questions = <DuelQuestion>[];
    var local = count;
    if (topics.grammar.isNotEmpty) {
      // Grammar gets most questions; conjugation and vocabulary a fifth each when also chosen.
      final side = max(1, (count * 0.2).round());
      final grammarCount = count - (topics.withConjugation ? side : 0) - (topics.withVocabulary ? side : 0);
      final grammar = await _grammarQuestions(topics.grammar, grammarRules, grammarCount);
      questions.addAll(grammar.take(grammarCount));
      local = count - questions.length;
    }
    if (local > 0) {
      final conj = topics.withConjugation ? (topics.withVocabulary ? (local * 0.6).round() : local) : 0;
      final vocab = topics.withVocabulary ? local - conj : 0;
      questions.addAll(conjugationQuestions(r, conj));
      questions.addAll(vocabularyQuestions(r, vocab));
      // Grammar only, but the AI gave too few: complete with conjugation.
      if (questions.length < count) questions.addAll(conjugationQuestions(r, count - questions.length));
    }
    return sortByLevel(questions, r);
  }

  /// Easy questions first, then medium, then hard (shuffled inside each level).
  static List<DuelQuestion> sortByLevel(List<DuelQuestion> questions, Random random) {
    final shuffled = List.of(questions)..shuffle(random);
    return [for (final level in [1, 2, 3]) ...shuffled.where((q) => q.level == level)];
  }

  /// Conjugation questions rising in difficulty: easy, medium and hard tenses.
  static List<DuelQuestion> conjugationQuestions(Random random, int n) {
    final out = <DuelQuestion>[];
    for (var i = 0; i < n; i++) {
      final level = n < 3 ? 2 : (i < n * 0.3 ? 1 : (i < n * 0.7 ? 2 : 3));
      final q = ConjugationQuiz.make(random, const {1: 'Facile', 2: 'Moyen', 3: 'Difficile'}[level]!);
      final options = [q.answer, ...ConjugationQuiz.distractors(q, random)]..shuffle(random);
      if (options.toSet().length != options.length) {
        i--;
        continue;
      }
      out.add(DuelQuestion('${q.prefix} ___', false, '${q.verb} · ${q.tenseLabel}', options, options.indexOf(q.answer),
          level: level));
    }
    return out;
  }

  /// "Which French word means …?" questions (easy).
  static List<DuelQuestion> vocabularyQuestions(Random random, int n) {
    final categories = vocabularySection.categories.where((c) => !c.cognate && c.id != 'faux_amis').toList();
    return [
      for (var i = 0; i < n; i++)
        () {
          final category = categories[random.nextInt(categories.length)];
          final words = List.of(category.items)..shuffle(random);
          final answer = words.first;
          final options = [for (final w in words.take(4)) w.fr]..shuffle(random);
          return DuelQuestion(answer.en, true, category.title, options, options.indexOf(answer.fr), level: 1);
        }(),
    ];
  }

  static Future<List<DuelQuestion>> _grammarQuestions(
      List<String> topics, Map<String, List<String>> rules, int n) async {
    final described = [
      for (final t in topics)
        '- $t${(rules[t] ?? const []).isEmpty ? '' : ': ${(rules[t]!).take(14).join(' | ')}'}',
    ].join('\n');
    final result = await chat([
      {
        'role': 'system',
        'content': '''You write the questions of a classroom quiz duel for B1 learners of French living in Belgium.
TOPICS (with the rules their lessons teach):
$described

Write ${n + 2} multiple-choice questions, spread evenly over the topics.
- Each question is ONE short French sentence with a blank "___" (or a very short French task) that tests the topic.
- 4 short French options. Exactly ONE is correct; the other three must be clearly wrong for this sentence
  (never a second acceptable answer). No English anywhere in prompt or options.
- Everyday Belgian life (Bruxelles, Liège, Namur, Gand…), natural sentences.
- "level": 1 = easy (the most basic use), 2 = medium, 3 = hard (exceptions, irregular forms, tricky cases).
  About a third of each level.
- "topic": the topic name exactly as given.
- Double-check that every "correct" index points to the right answer.
JSON: {"questions": [{"topic": "Le Subjonctif", "level": 1, "prompt": "Il faut que tu ___ à l'heure.", "options": ["sois", "es", "seras", "étais"], "correct": 0}]}'''
      },
      {'role': 'user', 'content': 'Write the ${n + 2} questions.'},
    ], thinking: true, temperature: 0.5);
    return [
      for (final raw in (result['questions'] as List? ?? const []))
        if (raw is Map) DuelQuestion.fromJson({...raw, 'english': false, 'hint': raw['topic'] ?? ''}),
    ].whereType<DuelQuestion>().toList();
  }
}

/// The questions of a duel created before topics could be chosen (or when the
/// duel server cannot store questions): they come from the code alone, so every
/// player gets the same ones.
List<DuelQuestion> duelQuestions(String code) {
  final seed = code.codeUnits.fold<int>(17, (h, c) => (h * 31 + c) & 0x7fffffff);
  final random = Random(seed);
  final questions = <DuelQuestion>[];
  for (var i = 0; i < 6; i++) {
    final q = ConjugationQuiz.make(random, 'Moyen');
    final options = [q.answer, ...ConjugationQuiz.distractors(q, random)]..shuffle(random);
    questions.add(DuelQuestion('${q.prefix} ___', false, '${q.verb} · ${q.tenseLabel}', options, options.indexOf(q.answer)));
  }
  final categories = vocabularySection.categories.where((c) => !c.cognate && c.id != 'faux_amis').toList();
  for (var i = 0; i < 4; i++) {
    final category = categories[random.nextInt(categories.length)];
    final words = List.of(category.items)..shuffle(random);
    final answer = words.first;
    final options = [for (final w in words.take(4)) w.fr]..shuffle(random);
    questions.add(DuelQuestion(answer.en, true, category.title, options, options.indexOf(answer.fr)));
  }
  return questions..shuffle(random);
}
