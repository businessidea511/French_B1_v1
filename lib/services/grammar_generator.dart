import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'deepseek_service.dart';

/// Builds complete grammar topics in several AI steps:
///   1. plan  – list EVERY rule of the topic at B1 (thinking mode),
///   2. write – explain the rules in parallel batches,
///   3. check – re-write any rule the writer skipped,
///   4. wrap  – intro, street expressions, summary, memory trick, quiz,
///   5. review – an examiner pass (thinking mode) fixes or removes wrong
///      examples, mistake cards and quiz answers.
///
/// Stored content is always French + ENGLISH explanations; the app translates
/// the explanations into the learner's language on screen (TranslatedText),
/// so switching language works for every topic.
class GrammarGenerator {
  static const String _explanationLanguage = 'English';
  static const int _rulesPerBatch = 3;
  static const int _maxSourceChars = 60000;

  /// The AI call. Tests replace it with a fake.
  @visibleForTesting
  static Future<Map<String, dynamic>> Function(
    List<Map<String, dynamic>> messages, {
    bool thinking,
    double? temperature,
    int? maxTokens,
  }) chat = DeepSeekService.chatJson;

  /// Finds the grammar topics taught on photographed/PDF pages.
  /// Returns up to 3 entries: {"title", "subtitle", "why"}.
  static Future<List<Map<String, dynamic>>> detectTopics(String sourceText) async {
    final result = await chat([
      {
        'role': 'system',
        'content': '''You identify which FRENCH GRAMMAR topics a textbook extract teaches.
Return 1 to 3 topics. Merge closely linked points into one topic (e.g. "le comparatif et le superlatif" if taught together).
Ignore vocabulary-only content. Use standard French topic names a teacher would use.
JSON: {"topics": [{"title": "French topic name, e.g. Le Passé Composé", "subtitle": "English name", "why": "one short English sentence: what on the pages shows it"}]}'''
      },
      {'role': 'user', 'content': 'TEXTBOOK EXTRACT:\n${_trim(sourceText)}'},
    ], temperature: 0.1);
    final topics = (result['topics'] as List? ?? const [])
        .whereType<Map>()
        .map((t) => Map<String, dynamic>.from(t))
        .where((t) => (t['title'] ?? '').toString().trim().isNotEmpty)
        .take(3)
        .toList();
    if (topics.isEmpty) throw Exception('No grammar topic was found on these pages.');
    return topics;
  }

  /// Generates a complete topic. [sourceText] is the extraction of photos or a
  /// PDF; the topic then follows the book and is completed with missing rules.
  /// Returns {"title", "subtitle", "icon", "widgets"}.
  static Future<Map<String, dynamic>> generate(
    String topic, {
    String? sourceText,
    void Function(String step)? onProgress,
  }) async {
    final source = sourceText == null ? null : _trim(sourceText);

    onProgress?.call('Planning every rule of "$topic"…');
    final plan = await _plan(topic, source);
    final title = (plan['title'] ?? topic).toString();
    final rules = (plan['rules'] as List? ?? const [])
        .whereType<Map>()
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
    if (rules.isEmpty) throw Exception('The AI could not plan this topic. Try a clearer topic name.');
    for (var i = 0; i < rules.length; i++) {
      rules[i]['id'] = 'r${i + 1}';
    }
    final expressions = (plan['expressions'] as List? ?? const []).whereType<Map>().toList();

    onProgress?.call('Writing ${rules.length} rules…');
    final batches = <List<Map<String, dynamic>>>[
      for (var i = 0; i < rules.length; i += _rulesPerBatch)
        rules.sublist(i, i + _rulesPerBatch > rules.length ? rules.length : i + _rulesPerBatch),
    ];
    final results = await Future.wait([
      for (final batch in batches) _writeRulesSafe(title, batch, source),
      _wrapUpSafe(title, rules, expressions),
      if (source != null) _bookExercisesSafe(title, source),
    ]);

    // Collect rule sections in plan order and see which rules were covered.
    final ruleWidgets = <String, List<dynamic>>{};
    for (final r in results.take(batches.length)) {
      ruleWidgets.addAll(Map<String, List<dynamic>>.from(r['by_rule'] as Map));
    }
    final missing = rules.where((r) => (ruleWidgets[r['id']] ?? const []).isEmpty).toList();
    if (missing.isNotEmpty) {
      onProgress?.call('Completing ${missing.length} missing rule(s)…');
      // One rule per request this time: the smallest possible answers.
      final retries = await Future.wait([for (final r in missing) _writeRulesSafe(title, [r], source)]);
      for (final retry in retries) {
        ruleWidgets.addAll(Map<String, List<dynamic>>.from(retry['by_rule'] as Map));
      }
    }
    final written = rules.where((r) => (ruleWidgets[r['id']] ?? const []).isNotEmpty).length;
    if (written < (rules.length + 1) ~/ 2) {
      throw Exception('Only $written of ${rules.length} rules could be written. Please try again.');
    }

    final wrap = results[batches.length];
    final bookExercises = source != null ? results[batches.length + 1]['widgets'] as List : const [];

    final widgets = <dynamic>[
      ...(wrap['intro'] as List? ?? const []),
      for (final r in rules) ...(ruleWidgets[r['id']] ?? const []),
      ...(wrap['expressions'] as List? ?? const []),
      ...(wrap['summary'] as List? ?? const []),
      ...bookExercises,
      ...(wrap['quiz'] as List? ?? const []),
    ];

    onProgress?.call('Checking every example and answer…');
    final checked = await _review(title, widgets);

    final stillMissing = rules.where((r) => (ruleWidgets[r['id']] ?? const []).isEmpty).length;
    debugPrint('📘 "$title": ${rules.length} rules, ${checked.length} widgets, $stillMissing missing');

    return {
      'title': title,
      'subtitle': (plan['subtitle'] ?? '').toString(),
      'icon': (plan['icon'] ?? '📘').toString(),
      'description': (plan['summary'] ?? plan['subtitle'] ?? '').toString(),
      'widgets': checked,
    };
  }

  // ── Step 1: plan ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _plan(String topic, String? source) {
    final sourcePart = source == null
        ? ''
        : '''
The learner gave these TEXTBOOK PAGES for this topic:
<<<
$source
>>>
Include EVERYTHING these pages teach about the topic, then ADD every other rule of the topic a B1 learner
needs, so the topic is complete even if the pages are not.''';

    return chat([
      {
        'role': 'system',
        'content': '''You are a senior FLE teacher designing the COMPLETE syllabus of one French grammar topic for B1 learners
(CEFR B1, as taught in Belgian French courses). Missing a rule is the worst possible mistake.
$sourcePart
List EVERY rule the learner must know to understand and use this topic correctly. Go through this checklist
and add a rule for each item that applies to the topic:
- EACH distinct use / situation
- formation for EACH verb group (-er, -ir, -re) and the needed stem
- spelling changes (manger → mangeons, commencer → commençons, appeler → appelle, acheter → achète, …)
- auxiliary choice and agreement (être/avoir, past participle agreement, gender/number agreement)
- the essential irregular forms at B1 (list them)
- negative form, question form, word order, position of pronouns
- trigger words / time markers / conjunctions that require it
- how it differs from the topics learners confuse it with
- exceptions and special cases
Complete but NOT repetitive:
- Group points that are the same idea into ONE rule (e.g. describing people, places and weather = one "description" rule;
  habits and repeated actions = one rule; all "si" uses of this tense = one rule). Each rule must be clearly different from the others.
- Formation for the regular groups usually fits in ONE rule with one table; spelling changes and irregular forms get their own rules.
- Do NOT add a rule for "what it is" — the introduction covers it.
- Aim for 8 to 14 rules; never more than 16. Order them from basic to advanced.

Also list 0 to 5 REAL everyday expressions or idioms that use this grammar and that people actually say in
Belgium or France (street / daily-life language). Only include genuine, common ones; [] if none really fit.

JSON:
{"title": "French topic name", "subtitle": "English name", "icon": "one emoji",
 "summary": "one simple English sentence describing the topic",
 "rules": [{"name": "short French rule name", "teach": "English: exactly which points, forms, examples and exceptions to explain"}],
 "expressions": [{"expression": "French expression", "meaning": "English meaning", "example": "short French sentence using it",
                  "region": "belgium | france | both", "register": "familier | courant"}]}'''
      },
      {'role': 'user', 'content': 'Topic: $topic'},
    ], thinking: true);
  }

  // ── Step 2: write rules ────────────────────────────────────────────────────

  static const String _languageRules = '''
LANGUAGE (critical):
- Everything FRENCH stays French: section titles (rule names), formulas, conjugations, tables, examples.
- Every EXPLANATION is in simple $_explanationLanguage. The app translates explanations into the learner's language automatically, so never write explanations in French or any other language.
- Write for complete beginners ("for dummies"): short sentences, everyday words, one idea per sentence.
  The first time you use a grammar word, explain it in brackets, e.g. "auxiliary (the helper verb)".''';

  static const String _widgetFormats = '''
WIDGETS you may use:
{"type": "section_title", "emoji": "…", "title": "French rule name"}
{"type": "text", "content": "English explanation"}
{"type": "tipbox", "title": "…", "content": "…", "color": "purple"}   (purple = formula, yellow = tip, red = warning, blue = info, green = good to know)
{"type": "table", "headers": ["…"], "rows": [["…"]]}                   (French content; use all 6 persons for conjugations: je, tu, il/elle/on, nous, vous, ils/elles)
{"type": "example", "french": "French sentence", "translation": "English translation"}
{"type": "mistake", "wrong": "French sentence learners wrongly say", "right": "correct French sentence", "why": "English: why"}''';

  /// [_writeRules], but a batch whose answer is too long (or fails) is split in
  /// two and retried, down to one rule; a rule that still fails is left out
  /// (and retried once more at the end of [generate]).
  static Future<Map<String, dynamic>> _writeRulesSafe(
      String title, List<Map<String, dynamic>> rules, String? source) async {
    try {
      return await _writeRules(title, rules, source);
    } catch (e) {
      if (rules.length == 1) {
        debugPrint('Rule "${rules.first['name']}" failed: $e');
        return {'by_rule': <String, List<dynamic>>{}};
      }
      debugPrint('Rule batch of ${rules.length} failed ($e); splitting it');
      final half = rules.length ~/ 2;
      final parts = await Future.wait([
        _writeRulesSafe(title, rules.sublist(0, half), source),
        _writeRulesSafe(title, rules.sublist(half), source),
      ]);
      return {
        'by_rule': {
          for (final part in parts) ...Map<String, List<dynamic>>.from(part['by_rule'] as Map),
        },
      };
    }
  }

  /// Returns {"by_rule": {"r1": [widgets], ...}}.
  static Future<Map<String, dynamic>> _writeRules(
      String title, List<Map<String, dynamic>> rules, String? source) async {
    final rulesJson = jsonEncode([
      for (final r in rules) {'id': r['id'], 'name': r['name'], 'teach': r['teach']}
    ]);
    final result = await chat([
      {
        'role': 'system',
        'content': '''You are Professeur AI, a patient Belgian French teacher, writing part of the grammar lesson "$title" for B1 learners.
$_languageRules
$_widgetFormats

For EACH rule you are given, write its section in this order:
1. section_title with the French rule name and a fitting emoji.
2. text: what it is / when to use it, in 2–4 short sentences; use an everyday analogy if it helps.
3. tipbox purple with the formula if the rule has a structure (e.g. "Sujet + avoir/être + participe passé").
4. table when forms change by person, gender or number.
5. 2–3 example widgets from everyday life. When a place is needed, use Belgian places (Bruxelles, Liège, Namur, Gand) — never Paris.
6. ONE mistake widget only when learners really get this rule wrong; "wrong" must be a genuinely incorrect sentence, different from "right".
Cover EVERY point listed in "teach". Do not skip any rule. Do not write intro, summary or quiz.
${source == null ? '' : 'Use the explanations and example sentences of the textbook extract below where they fit:\n<<<\n$source\n>>>'}
JSON: {"by_rule": {"<rule id>": [widgets for that rule], ...}}'''
      },
      {'role': 'user', 'content': 'RULES TO WRITE:\n$rulesJson'},
    ], temperature: 0.4);

    // Keep only well-formed widget lists for the requested rule ids.
    final byRule = <String, List<dynamic>>{};
    final raw = result['by_rule'];
    if (raw is Map) {
      for (final r in rules) {
        final list = raw[r['id']];
        if (list is List && list.isNotEmpty) {
          byRule[r['id'] as String] = list.whereType<Map>().where((w) => !_isBrokenMistake(w)).toList();
        }
      }
    }
    return {'by_rule': byRule};
  }

  // ── Step 4: intro, expressions, summary, quiz ─────────────────────────────

  /// [_wrapUp] in one request, or in two smaller ones when the answer is too long.
  static Future<Map<String, dynamic>> _wrapUpSafe(
      String title, List<Map<String, dynamic>> rules, List<Map> expressions) async {
    try {
      return await _wrapUp(title, rules, expressions);
    } catch (e) {
      debugPrint('Intro/summary/quiz in one request failed ($e); writing them in two');
      final parts = await Future.wait([
        _wrapUp(title, rules, expressions, parts: const {'intro', 'expressions'})
            .catchError((_) => <String, dynamic>{}),
        _wrapUp(title, rules, expressions, parts: const {'summary', 'quiz'})
            .catchError((_) => <String, dynamic>{}),
      ]);
      return {for (final part in parts) ...part};
    }
  }

  static const _allWrapUpParts = {'intro', 'expressions', 'summary', 'quiz'};

  static Future<Map<String, dynamic>> _wrapUp(
      String title, List<Map<String, dynamic>> rules, List<Map> expressions,
      {Set<String> parts = _allWrapUpParts}) {
    final ruleNames = rules.map((r) => '- ${r['id']}: ${r['name']} — ${r['teach']}').join('\n');
    final wanted = [for (final k in ['intro', 'expressions', 'summary', 'quiz']) if (parts.contains(k)) k];
    return chat([
      {
        'role': 'system',
        'content': '''You are Professeur AI writing the opening and closing parts of the grammar lesson "$title" for B1 learners.
$_languageRules
$_widgetFormats
{"type": "expression", "expression": "French expression", "meaning": "English meaning", "example": "French sentence",
 "region": "belgium | france | both", "register": "familier | courant"}
${DeepSeekService.exerciseWidgetRules(_explanationLanguage)}

The lesson teaches these rules (in order):
$ruleNames

Write ONLY these parts: ${wanted.map((k) => '"$k"').join(', ')} (skip the others below).
A. "intro": section_title (🎯, French, e.g. "C'est quoi l'imparfait ?"), a text that explains the topic from zero with an
   everyday analogy, and a tipbox blue "In this lesson" listing the French rule names.
B. "expressions": if the list below is not empty, a section_title "🇧🇪 Dans la rue" followed by one expression widget each
   (fix any mistake in them; drop any that are not real or not related to the topic). [] if the list is empty.
   Expressions: ${jsonEncode(expressions)}
C. "summary": section_title "📌 Résumé" and ONE tipbox yellow cheat sheet: one line per rule, "French formula or key form → English hint";
   then one tipbox yellow "Memory trick" with a mnemonic that helps remember the hardest rule.
D. "quiz": section_title "✍️ Quiz" and ONE exercise widget with ONE item per rule (at most 16 items; mix multiple choice
   and typed answers). Every item makes the learner USE the rule in a French sentence — never ask for definitions.
   Double-check every answer.
JSON: {${wanted.map((k) => '"$k": [...]').join(', ')}}'''
      },
      {'role': 'user', 'content': 'Write ${wanted.join(', ')} for "$title".'},
    ], temperature: 0.4);
  }

  // ── Step 5: review ─────────────────────────────────────────────────────────

  /// Sends examples, mistake cards and quiz items to a strict examiner and
  /// applies its fixes. Ids: `w12` = widget 12, `w40.q3` = item 3 of exercise widget 40.
  static Future<List<dynamic>> _review(String title, List<dynamic> widgets) async {
    final checks = <String, dynamic>{};
    for (var i = 0; i < widgets.length; i++) {
      final w = widgets[i];
      if (w is! Map) continue;
      if (w['type'] == 'example' || w['type'] == 'mistake') checks['w$i'] = w;
      if (w['type'] == 'exercise') {
        final items = w['items'] as List? ?? const [];
        for (var j = 0; j < items.length; j++) {
          checks['w$i.q$j'] = items[j];
        }
      }
    }
    if (checks.isEmpty) return widgets;

    final Map<String, dynamic> result;
    try {
      result = await chat([
        {
          'role': 'system',
          'content': '''You are a strict examiner of French grammar checking material for the B1 grammar lesson "$title".
Check every entry:
- "example": the French is correct, natural, and the translation matches.
- "mistake": "wrong" is REALLY incorrect French, "right" is correct, and the mistake is about "$title" (not another tense or topic).
- quiz item: the question is clear, has ONE correct answer (other valid answers go in "alternatives"), the answer is French
  and correct, and the item practises "$title" (e.g. a polite form with "voudrais" is the conditionnel, not the imparfait).
Return ONLY the entries that need a change: "replace" with the corrected entry (same JSON shape), or "remove" when it
cannot be fixed. Explanations stay in English.
JSON: {"fixes": [{"id": "w12", "action": "replace", "value": {...}}, {"id": "w40.q3", "action": "remove"}]}'''
        },
        {'role': 'user', 'content': 'ENTRIES:\n${jsonEncode(checks)}'},
      ], thinking: true);
    } catch (e) {
      debugPrint('Review step failed, keeping unreviewed content: $e');
      return widgets;
    }

    final out = [for (final w in widgets) w is Map ? Map<String, dynamic>.from(w) : w];
    final removedWidgets = <int>{};
    final removedItems = <int, Set<int>>{};
    for (final fix in (result['fixes'] as List? ?? const []).whereType<Map>()) {
      final match = RegExp(r'^w(\d+)(?:\.q(\d+))?$').firstMatch((fix['id'] ?? '').toString());
      if (match == null || !checks.containsKey(fix['id'])) continue;
      final i = int.parse(match.group(1)!);
      final j = match.group(2) == null ? null : int.parse(match.group(2)!);
      final value = fix['value'];
      if (fix['action'] == 'remove') {
        j == null ? removedWidgets.add(i) : removedItems.putIfAbsent(i, () => {}).add(j);
      } else if (fix['action'] == 'replace' && value is Map) {
        if (j == null) {
          out[i] = {...Map<String, dynamic>.from(value), 'type': (out[i] as Map)['type']};
        } else {
          final items = List<dynamic>.from((out[i] as Map)['items'] as List);
          items[j] = Map<String, dynamic>.from(value);
          (out[i] as Map)['items'] = items;
        }
      }
    }
    removedItems.forEach((i, js) {
      final items = (out[i] as Map)['items'] as List;
      (out[i] as Map)['items'] = [for (var j = 0; j < items.length; j++) if (!js.contains(j)) items[j]];
    });
    final fixes = (result['fixes'] as List? ?? const []).length;
    debugPrint('🔎 Review of "$title": $fixes fix(es)');
    return [for (var i = 0; i < out.length; i++) if (!removedWidgets.contains(i)) out[i]];
  }

  /// [_bookExercises], but the lesson is still built if they fail.
  static Future<Map<String, dynamic>> _bookExercisesSafe(String title, String source) async {
    try {
      return await _bookExercises(title, source);
    } catch (e) {
      debugPrint('Book exercises failed, lesson built without them: $e');
      return {'widgets': const []};
    }
  }

  /// Turns the exercises of a textbook extract into exercise widgets.
  static Future<Map<String, dynamic>> _bookExercises(String title, String source) async {
    final result = await chat([
      {
        'role': 'system',
        'content': '''Convert EVERY exercise in this textbook extract about "$title" into interactive exercise widgets.
${DeepSeekService.photoContentRules(_explanationLanguage)}
If there are no exercises, return {"widgets": []}.
JSON: {"widgets": [{"type": "section_title", "emoji": "📖", "title": "Exercices du livre"}, {"type": "exercise", ...}]}'''
      },
      {'role': 'user', 'content': 'TEXTBOOK EXTRACT:\n$source'},
    ], temperature: 0.2);
    final widgets = (result['widgets'] as List? ?? const []).whereType<Map>().toList();
    final hasExercise = widgets.any((w) => w['type'] == 'exercise');
    return {'widgets': hasExercise ? widgets : const []};
  }

  /// A "mistake" whose wrong and right sentences are the same teaches nothing.
  static bool _isBrokenMistake(Map w) {
    if (w['type'] != 'mistake') return false;
    String norm(Object? s) => (s ?? '').toString().toLowerCase().replaceAll(RegExp(r'[^a-zàâäéèêëîïôöùûüç]'), '');
    return norm(w['wrong']).isEmpty || norm(w['wrong']) == norm(w['right']);
  }

  static String _trim(String text) =>
      text.length > _maxSourceChars ? text.substring(0, _maxSourceChars) : text;
}
