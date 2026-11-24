import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'deepseek_service.dart';
import 'language_provider.dart';

/// One answered item of a homework sheet.
class HomeworkAnswer {
  final String exercise; // "Exercice 2", as printed
  final String n; // "a", "3", as printed
  final String question;
  final String studentAnswer; // what the learner wrote on the sheet, or ''
  final String answer; // what goes in the blank / the answer
  final String sentence; // the whole correct sentence in French
  final String why; // the rule, in the learner's language
  final String student; // 'correct', 'wrong' or 'none'

  const HomeworkAnswer({
    required this.exercise,
    required this.n,
    required this.question,
    required this.studentAnswer,
    required this.answer,
    required this.sentence,
    required this.why,
    required this.student,
  });

  factory HomeworkAnswer.fromJson(Map<String, dynamic> j) => HomeworkAnswer(
        exercise: '${j['exercise'] ?? ''}'.trim(),
        n: '${j['n'] ?? ''}'.trim(),
        question: '${j['question'] ?? ''}'.trim(),
        studentAnswer: '${j['student_answer'] ?? ''}'.trim(),
        answer: '${j['answer'] ?? ''}'.trim(),
        sentence: '${j['sentence'] ?? ''}'.trim(),
        why: '${j['why'] ?? ''}'.trim(),
        student: switch ('${j['student'] ?? ''}'.trim().toLowerCase()) { 'correct' => 'correct', 'wrong' => 'wrong', _ => 'none' },
      );

  Map<String, dynamic> toJson() => {
        'exercise': exercise,
        'n': n,
        'question': question,
        'student_answer': studentAnswer,
        'answer': answer,
        'sentence': sentence,
        'why': why,
        'student': student,
      };
}

/// A photographed homework sheet: what was read, its translation, the hard
/// words and the checked answers.
class Homework {
  final String id;
  final DateTime date;
  final String title;
  final String text; // reading texts on the sheet, in French
  final List<Map<String, dynamic>> exercises; // as read: label, instruction, items
  final String translation; // in the learner's language
  final List<Map<String, String>> words; // fr, meaning, example
  final List<HomeworkAnswer> answers;
  final List<String> unreadable;

  const Homework({
    required this.id,
    required this.date,
    required this.title,
    required this.text,
    required this.exercises,
    required this.translation,
    required this.words,
    required this.answers,
    this.unreadable = const [],
  });

  /// Answers grouped by exercise, in the order of the sheet.
  Map<String, List<HomeworkAnswer>> get byExercise {
    final groups = <String, List<HomeworkAnswer>>{};
    for (final a in answers) {
      (groups[a.exercise] ??= []).add(a);
    }
    return groups;
  }

  /// The printed instruction of an exercise.
  String instructionOf(String label) =>
      '${exercises.where((e) => '${e['label']}'.trim() == label).firstOrNull?['instruction'] ?? ''}'.trim();

  factory Homework.fromJson(Map<String, dynamic> j) => Homework(
        id: '${j['id']}',
        date: DateTime.tryParse('${j['date']}') ?? DateTime.now(),
        title: '${j['title'] ?? ''}',
        text: '${j['text'] ?? ''}',
        exercises: [for (final e in (j['exercises'] as List? ?? const [])) if (e is Map) Map<String, dynamic>.from(e)],
        translation: '${j['translation'] ?? ''}',
        words: [
          for (final w in (j['words'] as List? ?? const []))
            if (w is Map) {for (final k in ['fr', 'meaning', 'example']) k: '${w[k] ?? ''}'.trim()},
        ],
        answers: [for (final a in (j['answers'] as List? ?? const [])) if (a is Map) HomeworkAnswer.fromJson(Map<String, dynamic>.from(a))],
        unreadable: [for (final u in (j['unreadable'] as List? ?? const [])) '$u'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'text': text,
        'exercises': exercises,
        'translation': translation,
        'words': words,
        'answers': [for (final a in answers) a.toJson()],
        'unreadable': unreadable,
      };
}

/// Steps shown while a homework is being solved.
enum HomeworkStep { reading, solving, checking }

/// Homework help: photos of a class sheet → what it says, a translation, the
/// hard words, and answers that are solved and then checked a second time.
class HomeworkService extends ChangeNotifier {
  HomeworkService._();
  static final instance = HomeworkService._();

  static const _key = 'homework_history';
  static const _keep = 15;

  /// The AI call. Tests replace it with a fake.
  @visibleForTesting
  static Future<Map<String, dynamic>> Function(
    List<Map<String, dynamic>> messages, {
    bool thinking,
    double? temperature,
    int? maxTokens,
  }) chat = DeepSeekService.chatJson;

  List<Homework> history = []; // newest first
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        history = [for (final h in jsonDecode(raw) as List) Homework.fromJson(Map<String, dynamic>.from(h as Map))];
      }
    } catch (e) {
      debugPrint('Homework history unreadable: $e');
    }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode([for (final h in history) h.toJson()]));
    } catch (_) {}
  }

  void remove(String id) {
    history.removeWhere((h) => h.id == id);
    notifyListeners();
    _save();
  }

  @visibleForTesting
  void reset() {
    history = [];
    _loaded = false;
  }

  /// Reads, translates, solves and checks the sheet. [onStep] follows the progress.
  Future<Homework> solve(
    List<String> base64Images,
    String mimeType,
    AppLanguage language, {
    String? instructions,
    void Function(HomeworkStep step)? onStep,
  }) async {
    onStep?.call(HomeworkStep.reading);
    final sheet = await _read(base64Images, mimeType);
    final exercises = [for (final e in (sheet['exercises'] as List? ?? const [])) if (e is Map) Map<String, dynamic>.from(e)];
    final text = '${sheet['text'] ?? ''}'.trim();
    if (exercises.isEmpty && text.isEmpty) throw const HomeworkNotFound();

    // Only what the learner asked for ("only exercise 3"), when they said so.
    final note = (instructions ?? '').trim();
    final target = language == AppLanguage.french ? 'simple French' : language.englishName;
    final sheetJson = jsonEncode({'text': text, 'exercises': exercises});

    onStep?.call(HomeworkStep.solving);
    final results = await Future.wait([
      _translate(sheetJson, target, translate: language != AppLanguage.french),
      _solve(sheetJson, target, note),
    ]);
    final help = results[0];
    var answers = results[1]['answers'] as List? ?? const [];

    onStep?.call(HomeworkStep.checking);
    if (answers.isNotEmpty) {
      try {
        final checked = await _check(sheetJson, jsonEncode({'answers': answers}), target);
        final list = checked['answers'] as List?;
        // A check that lost items is not trusted: keep the first answers.
        if (list != null && list.length >= answers.length) answers = list;
      } catch (e) {
        debugPrint('Homework check failed, keeping the first answers: $e');
      }
    }

    final homework = Homework.fromJson({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'date': DateTime.now().toIso8601String(),
      'title': '${sheet['title'] ?? ''}'.trim().isEmpty ? 'Devoir' : '${sheet['title']}'.trim(),
      'text': text,
      'exercises': exercises,
      'translation': '${help['translation'] ?? ''}'.trim(),
      'words': help['words'] ?? const [],
      'answers': answers,
      'unreadable': sheet['unreadable'] ?? const [],
    });
    history.insert(0, homework);
    if (history.length > _keep) history = history.sublist(0, _keep);
    notifyListeners();
    await _save();
    return homework;
  }

  /// Step 1: copy the sheet exactly, with what the learner already wrote.
  Future<Map<String, dynamic>> _read(List<String> images, String mimeType) => chat([
        {
          'role': 'system',
          'content': '''These photos are a French homework sheet from a class (A2–B1, Belgium), page by page, in order.
Copy it EXACTLY. Do NOT answer the exercises.
- "title": a short French title for the sheet (2–5 words).
- "text": every reading text, dialogue or document on the sheet, copied word for word in French (blank line between paragraphs); "" if there is none.
- "exercises": EVERY exercise, in order:
  - "label": its number or name as printed (e.g. "Exercice 2", "B");
  - "instruction": the printed instruction, word for word;
  - "items": EVERY item, never skip or summarise:
    - "n": the item number or letter as printed ("1", "a"); number them yourself if the sheet does not;
    - "question": the full sentence or question; write each blank as ___ and keep any word, verb or hint given in brackets;
    - "options": the printed choices (multiple choice, words to place), or [];
    - "student_answer": what the student already wrote in pen or pencil for this item, copied exactly with its mistakes, or "".
- "unreadable": the places you could not read clearly, or [].
Printed text matters most. Ignore handwritten notes in other languages (e.g. Arabic translations). If a word cannot be read, write [?].
Return JSON: {"title": "", "text": "", "exercises": [{"label": "", "instruction": "", "items": [{"n": "", "question": "", "options": [], "student_answer": ""}]}], "unreadable": []}''',
        },
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': 'Copy my homework sheet (${images.length} photo(s)).'},
            for (final b in images)
              {
                'type': 'image_url',
                'image_url': {'url': 'data:$mimeType;base64,$b'},
              },
          ],
        },
      ], temperature: 0.0, maxTokens: 8000);

  /// Translation of the whole sheet and its hard words.
  Future<Map<String, dynamic>> _translate(String sheetJson, String target, {required bool translate}) => chat([
        {
          'role': 'system',
          'content': '''A learner of French (B1) photographed this homework sheet. Help them understand it, in $target.
${translate ? '- "translation": translate the whole sheet into $target: the reading texts, then each exercise with its instruction and items (keep the numbers; keep each blank as ___). Natural, faithful translation.' : '- "translation": "" (the learner reads French).'}
- Grammar terms (passé composé, imparfait, subjonctif, conditionnel, COD, pronom relatif…) stay in French, in brackets, with a correct short explanation if needed. Never give them a wrong name: the subjonctif is NOT the conditional, the imparfait is NOT the passé composé.
- "words": the 8 to 20 words or expressions of the sheet a B1 learner may not know (no very basic words like "le", "et", "maison"). For each:
  "fr": the word as a dictionary entry (nouns with their article, e.g. "la facture"; verbs in the infinitive),
  "meaning": its meaning here, in $target,
  "example": the sentence of the sheet where it appears, or a short French example.
Return JSON: {"translation": "", "words": [{"fr": "", "meaning": "", "example": ""}]}''',
        },
        {'role': 'user', 'content': sheetJson},
      ], temperature: 0.2, maxTokens: 8000);

  /// Step 2: solve every item, with care for grammar.
  Future<Map<String, dynamic>> _solve(String sheetJson, String target, String note) => chat([
        {
          'role': 'system',
          'content': '''You are an expert French teacher (FLE, B1). Solve this homework sheet so that every answer is 100% correct.
Before answering each item, think: what exactly does the instruction ask (tense, mood, form, pronoun, number of words, which word from a list)? Which grammar rule applies?
Check: conjugation and tense, subjunctive after the right expressions, agreement of adjectives and past participles (être / avoir with a direct object before), gender and number, articles and partitives, prepositions (à / de / en / au / chez…), pronouns (y, en, le, lui, leur, relative qui / que / dont / où), negation, word order, accents and spelling.
If several answers are correct, give the most natural one in standard French.
For questions about the reading text, answer from the text, in a correct complete French sentence.
For free questions (answer a personal question, write a sentence), write a simple, correct B1 answer.
${note.isEmpty ? '' : 'The learner says: "$note". Follow it (e.g. only solve the exercises they name).\n'}For EVERY item, return:
- "exercise": the exercise label exactly as given; "n": the item number exactly as given; "question": the item;
- "answer": only what goes in the blank, or the short answer;
- "sentence": the whole correct sentence in French, with the answer in it;
- "why": the rule in one or two short sentences, in $target; keep grammar terms in French (e.g. "subjonctif", "passé composé");
- "student_answer": copy the student_answer given for this item ("" if none);
- "student": "correct" if the student_answer is right (an equivalent correct answer counts), "wrong" if it is not, "none" if there is no student_answer.
If an item cannot be solved because the sheet was not readable, write "?" as the answer and say why.
Return JSON: {"answers": [{"exercise": "", "n": "", "question": "", "answer": "", "sentence": "", "why": "", "student_answer": "", "student": "none"}]}''',
        },
        {'role': 'user', 'content': sheetJson},
      ], thinking: true, temperature: 0.0, maxTokens: 16000);

  /// Step 3: a second teacher checks every answer and fixes mistakes.
  Future<Map<String, dynamic>> _check(String sheetJson, String answersJson, String target) => chat([
        {
          'role': 'system',
          'content': '''You are a second French teacher. A colleague solved this homework sheet; a student will hand it in, so it must have NO mistakes.
Check EVERY answer, one by one, against its instruction and the reading text:
the tense and mood asked, conjugation, agreement (gender, number, past participle), articles, prepositions, pronouns, negation, word order, accents and spelling, and that "sentence" really contains "answer".
Check the "student" verdict too: "correct" only if the student_answer is really right.
Fix anything wrong; keep what is right. "why" stays in $target.
Return JSON with the COMPLETE list, every item, in the same format: {"answers": [{"exercise": "", "n": "", "question": "", "answer": "", "sentence": "", "why": "", "student_answer": "", "student": "none"}]}''',
        },
        {'role': 'user', 'content': 'THE SHEET:\n$sheetJson\n\nTHE ANSWERS TO CHECK:\n$answersJson'},
      ], thinking: true, temperature: 0.0, maxTokens: 16000);
}

/// The photos do not show a homework sheet that could be read.
class HomeworkNotFound implements Exception {
  const HomeworkNotFound();
}
