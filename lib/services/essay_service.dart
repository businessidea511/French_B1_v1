import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/exam_kit.dart';
import 'deepseek_service.dart';

/// A grammar point used in a model essay, to notice and learn.
class EssayGrammarNote {
  final String french; // the words in the essay
  final String point; // English: the rule
  const EssayGrammarNote(this.french, this.point);
}

/// A model essay written by the AI for a subject, to read and learn.
class ModelEssay {
  final String essay; // French
  final List<EssayGrammarNote> notes;
  final String country; // the learner's country it was written for ('' = none)
  const ModelEssay(this.essay, this.notes, {this.country = ''});

  Map<String, dynamic> toJson() => {
        'essay': essay,
        'notes': [for (final n in notes) {'fr': n.french, 'point': n.point}],
        if (country.isNotEmpty) 'country': country,
      };

  static ModelEssay? fromJson(Object? j) {
    if (j is! Map || '${j['essay'] ?? ''}'.trim().isEmpty) return null;
    return ModelEssay(
      '${j['essay']}'.trim(),
      [
        for (final n in (j['notes'] as List? ?? const []))
          if (n is Map && '${n['fr'] ?? ''}'.trim().isNotEmpty) EssayGrammarNote('${n['fr']}'.trim(), '${n['point'] ?? ''}'.trim()),
      ],
      country: '${j['country'] ?? ''}'.trim(),
    );
  }
}

/// An essay question from class (photographed or typed).
class EssayQuestion {
  final String id;
  String title; // short French title
  String question; // the full instruction, in French
  int minWords;
  int maxWords;

  EssayQuestion({
    required this.id,
    required this.title,
    required this.question,
    this.minWords = 80,
    this.maxWords = 150,
  });

  /// The question as an exam subject for the writing page (timer, correction).
  ExamSubject get subject =>
      ExamSubject('essay_$id', '📄', title, question, ExamFocus.any, minWords: minWords, maxWords: maxWords);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'question': question,
        'min': minWords,
        'max': maxWords,
      };

  static EssayQuestion fromJson(Map j) => EssayQuestion(
        id: '${j['id']}',
        title: '${j['title'] ?? ''}',
        question: '${j['question'] ?? ''}',
        minWords: (j['min'] as num?)?.toInt() ?? 80,
        maxWords: (j['max'] as num?)?.toInt() ?? 150,
      );
}

/// The class essay questions and the AI model essays, kept on this device.
class EssayService extends ChangeNotifier {
  EssayService._();
  static final instance = EssayService._();

  static const _prefKey = 'my_essays_v1';
  static const _modelsKey = 'model_essays_v1';
  static const _cultureKey = 'my_culture_v1';

  /// Countries of the learners in the class, in French (the essays are in French).
  static const countries = [
    'Palestine', 'Syrie', 'Ukraine', 'Afghanistan', 'Érythrée', 'Turquie', 'Maroc', 'Algérie', 'Tunisie',
    'Irak', 'Iran', 'Liban', 'Égypte', 'Somalie', 'Éthiopie', 'Soudan', 'Congo (RDC)', 'Guinée', 'Cameroun',
    'Italie', 'Espagne', 'Pologne', 'Roumanie', 'Albanie', 'Russie', 'Indonésie', 'Inde', 'Pakistan', 'Brésil',
  ];

  /// The learner's country and traditions, for essays about culture, fêtes, food…
  String country = '';
  String traditions = ''; // e.g. "musulman : l'Aïd el-Fitr et l'Aïd el-Adha"

  Future<void> setCulture(String newCountry, String newTraditions) async {
    country = newCountry.trim();
    traditions = newTraditions.trim();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cultureKey, jsonEncode({'country': country, 'traditions': traditions}));
    } catch (_) {}
  }

  /// The AI call. Tests replace it with a fake.
  @visibleForTesting
  static Future<Map<String, dynamic>> Function(
    List<Map<String, dynamic>> messages, {
    bool thinking,
    double? temperature,
    int? maxTokens,
  }) chat = DeepSeekService.chatJson;

  List<EssayQuestion> questions = [];
  Map<String, ModelEssay> models = {}; // subject id → model essay
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_prefKey);
      if (raw != null) {
        // Keep anything added while loading.
        final saved = [for (final q in jsonDecode(raw) as List) EssayQuestion.fromJson(q as Map)];
        questions = [...saved, ...questions.where((q) => !saved.any((s) => s.id == q.id))];
      }
      final rawCulture = (await SharedPreferences.getInstance()).getString(_cultureKey);
      if (rawCulture != null && country.isEmpty) {
        final c = jsonDecode(rawCulture) as Map;
        country = '${c['country'] ?? ''}';
        traditions = '${c['traditions'] ?? ''}';
      }
      final rawModels = (await SharedPreferences.getInstance()).getString(_modelsKey);
      if (rawModels != null) {
        models = {
          for (final e in (jsonDecode(rawModels) as Map).entries)
            if (ModelEssay.fromJson(e.value) case final m?) '${e.key}': m,
          ...models,
        };
      }
    } catch (e) {
      debugPrint('Could not load essays: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode([for (final q in questions) q.toJson()]));
      await prefs.setString(_modelsKey, jsonEncode({for (final e in models.entries) e.key: e.value.toJson()}));
    } catch (_) {}
  }

  EssayQuestion? byId(String id) {
    for (final q in questions) {
      if (q.id == id) return q;
    }
    return null;
  }

  static int _counter = 0;

  // Time + counter: two questions added in the same instant get different ids
  // (browsers give the time in whole milliseconds).
  static String _newId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_counter++).toRadixString(36)}';

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '');

  /// Adds questions, skipping ones already in the list. Returns how many were added.
  int addAll(Iterable<EssayQuestion> found) {
    var added = 0;
    for (final q in found) {
      if (q.question.trim().isEmpty) continue;
      if (questions.any((e) => _norm(e.question) == _norm(q.question))) continue;
      questions.add(q);
      added++;
    }
    if (added > 0) _save();
    return added;
  }

  EssayQuestion addTyped(String question) {
    final text = question.trim();
    final words = text.split(RegExp(r'\s+'));
    final title = words.length <= 6 ? text : '${words.take(6).join(' ')}…';
    // "(100 mots)" in the question sets the target: 80–120 words.
    final asked = int.tryParse(RegExp(r'(\d{2,3})\s*mots').firstMatch(text)?.group(1) ?? '');
    final q = asked == null
        ? EssayQuestion(id: _newId(), title: title, question: text)
        : EssayQuestion(id: _newId(), title: title, question: text, minWords: asked - 20, maxWords: asked + 20);
    addAll([q]);
    return byId(q.id) ?? q;
  }

  void remove(String id) {
    questions.removeWhere((q) => q.id == id);
    models.remove('essay_$id');
    _save();
  }

  /// Reads photos of class papers and returns the essay questions on them.
  Future<List<EssayQuestion>> readPapers(List<String> base64Images, String mimeType) async {
    final r = await chat([
      {
        'role': 'system',
        'content': '''These are photos of papers from a French class (B1, Belgium).
Find EVERY writing / essay question on them (rédaction, production écrite, "Racontez…", "Écrivez…", "Décrivez…", "Donnez votre avis…").
For each one:
- "question": the full instruction, copied exactly in French (fix only obvious photo-reading errors);
- "title": a short French title (2–5 words);
- "min_words" / "max_words": the number of words asked, if the paper says it (else 80 and 150).
Ignore grammar exercises, vocabulary lists and reading texts. If there is no essay question, return an empty list.
Return JSON: {"questions": [{"title": "", "question": "", "min_words": 80, "max_words": 150}]}''',
      },
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': 'Find the essay questions on these ${base64Images.length} photo(s).'},
          for (final b in base64Images)
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$b'},
            },
        ],
      },
    ], temperature: 0.1, maxTokens: 3000);
    return [
      for (final (i, q) in (r['questions'] as List? ?? const []).indexed)
        if (q is Map && '${q['question'] ?? ''}'.trim().isNotEmpty)
          EssayQuestion(
            id: '${_newId()}$i',
            title: '${q['title'] ?? ''}'.trim().isEmpty ? 'Rédaction ${i + 1}' : '${q['title']}'.trim(),
            question: '${q['question']}'.trim(),
            minWords: ((q['min_words'] as num?)?.toInt() ?? 80).clamp(30, 400),
            maxWords: ((q['max_words'] as num?)?.toInt() ?? 150).clamp(40, 500),
          ),
    ];
  }

  /// Reads photos of the learner's handwritten essay: copies the text
  /// exactly (mistakes included, for the correction) and finds its topic.
  /// Returns the topic as a saved question, and the text.
  Future<(EssayQuestion, String)> readHandwritten(List<String> base64Images, String mimeType) async {
    final r = await chat([
      {
        'role': 'system',
        'content': '''These photos are a learner's HANDWRITTEN French essay (B1), page by page, in order.
1. "text": copy the essay EXACTLY as written, word for word, with ALL its mistakes (spelling, accents, agreement, conjugation).
   Do NOT correct anything: a teacher will correct it later. Keep the paragraphs (blank line between them).
   Leave out crossed-out words. If one word cannot be read, write [?].
2. "question": if the essay question / instruction is written on the paper, copy it exactly in French.
   Otherwise write the most likely exam instruction for this essay in simple French (e.g. "Racontez un week-end avec votre famille.").
3. "title": a short French title (2–5 words). "words": the number of words of the text.
Return JSON: {"title": "", "question": "", "text": "", "words": 0}''',
      },
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': 'Copy my handwritten essay (${base64Images.length} photo(s)) and find its topic.'},
          for (final b in base64Images)
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$b'},
            },
        ],
      },
    ], temperature: 0.0, maxTokens: 4000);
    final text = '${r['text'] ?? ''}'.trim();
    final question = '${r['question'] ?? ''}'.trim();
    if (text.isEmpty) throw Exception('No text found');
    final title = '${r['title'] ?? ''}'.trim();
    final q = EssayQuestion(
      id: _newId(),
      title: title.isEmpty ? 'Ma rédaction' : title,
      question: question.isEmpty ? 'Écrivez un texte sur ce sujet : ${title.isEmpty ? 'ma rédaction' : title}.' : question,
    );
    // The same topic photographed again: keep the saved one.
    final existing = questions.where((e) => _norm(e.question) == _norm(q.question)).firstOrNull;
    if (existing != null) return (existing, text);
    addAll([q]);
    return (q, text);
  }

  /// The AI writes a B1 model essay for the subject, to read and learn.
  Future<ModelEssay> writeModel(ExamSubject q) async {
    final phrases = [for (final p in jokerPhrases) p.french].join('\n');
    final r = await chat([
      {
        'role': 'system',
        'content': '''You are a French teacher in Belgium. Write a MODEL answer to a B1 essay question, that a learner will read, listen to and learn by heart for the exam.
- ${q.minWords}–${q.maxWords} words, B1 level: clear, natural, correct French; short sentences; 3–4 short paragraphs.
- SIMPLE A2–B1 VOCABULARY ONLY: common everyday words a learner already knows (maison, travail, famille, ami, aider, content…); no rare, literary or formal words (not "néanmoins", "s'avérer", "épanouissement"…); short, clear sentences.
- Answer exactly what the question asks (type of text: story, email, letter, opinion…). Everyday life in Belgium.
${country.isEmpty ? '' : '''- The learner comes from $country${traditions.isEmpty ? '' : ' ($traditions)'}. If the question is about culture, a fête or celebration, food, traditions, customs, family life, a wedding, the home country or "your country": write about $country and its REAL traditions (correct names, dates, dishes, customs${traditions.isEmpty ? '' : ', especially: $traditions'}), told by someone from $country now living in Belgium. Never invent traditions. For other subjects: everyday life in Belgium.
'''}
- Show B1 grammar naturally: passé composé + imparfait in stories, the subjonctif (il faut que, bien que, je suis content que…), COD/COI pronouns (le, la, lui, leur, en, y), connectors.
- Use 2 or 3 of these ready-made phrases where they fit (adapt them):
$phrases
"notes": 4–6 grammar points used in the essay: "fr" = the exact words in the essay, "point" = the rule in simple English.
Return JSON: {"essay": "...", "notes": [{"fr": "...", "point": "..."}]}''',
      },
      {'role': 'user', 'content': 'Question: ${q.instruction}'},
    ], temperature: 0.7, maxTokens: 2500);
    final essay = '${r['essay'] ?? ''}'.trim();
    if (essay.isEmpty) throw Exception('No essay');
    final model = ModelEssay.fromJson({...r, 'essay': essay, 'country': country})!;
    models[q.id] = model;
    await _save();
    return model;
  }

  @visibleForTesting
  void reset() {
    questions = [];
    models = {};
    country = '';
    traditions = '';
    _loaded = false;
  }
}
