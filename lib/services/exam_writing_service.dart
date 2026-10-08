import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/exam_kit.dart';
import 'deepseek_service.dart';

class WritingMistake {
  final String wrong; // the learner's words, exactly
  final String right;
  final String why; // in the learner's language
  const WritingMistake(this.wrong, this.right, this.why);
}

/// A correction like a teacher's: a mark out of 20 on four criteria.
class WritingFeedback {
  final int task, grammar, vocabulary, organisation; // each 0–5
  final String summary;
  final List<WritingMistake> mistakes;
  final List<String> good;
  final String betterVersion; // French
  final String nextTip;

  const WritingFeedback({
    required this.task,
    required this.grammar,
    required this.vocabulary,
    required this.organisation,
    required this.summary,
    required this.mistakes,
    required this.good,
    required this.betterVersion,
    required this.nextTip,
  });

  int get score => task + grammar + vocabulary + organisation;

  static int _mark(Object? v) => ((v is num ? v : num.tryParse('$v') ?? 0).round()).clamp(0, 5);

  static WritingFeedback fromJson(Map<String, dynamic> j) {
    final c = (j['criteria'] as Map?) ?? const {};
    return WritingFeedback(
      task: _mark(c['task']),
      grammar: _mark(c['grammar']),
      vocabulary: _mark(c['vocabulary']),
      organisation: _mark(c['organisation']),
      summary: '${j['summary'] ?? ''}'.trim(),
      mistakes: [
        for (final m in (j['mistakes'] as List? ?? const []))
          if (m is Map && '${m['wrong'] ?? ''}'.trim().isNotEmpty && '${m['right'] ?? ''}'.trim().isNotEmpty)
            WritingMistake('${m['wrong']}'.trim(), '${m['right']}'.trim(), '${m['why'] ?? ''}'.trim()),
      ],
      good: [for (final g in (j['good'] as List? ?? const [])) if ('$g'.trim().isNotEmpty) '$g'.trim()],
      betterVersion: '${j['better_version'] ?? ''}'.trim(),
      nextTip: '${j['next_tip'] ?? ''}'.trim(),
    );
  }
}

class ExamWritingService {
  /// The AI call. Tests replace it with a fake.
  @visibleForTesting
  static Future<Map<String, dynamic>> Function(
    List<Map<String, dynamic>> messages, {
    bool thinking,
    double? temperature,
    int? maxTokens,
  }) chat = DeepSeekService.chatJson;

  static int wordCount(String text) => RegExp(r"[\p{L}\p{N}]+(?:['’-][\p{L}\p{N}]+)*", unicode: true).allMatches(text).length;

  static String _focusName(ExamFocus f) => switch (f) {
        ExamFocus.subjonctif => 'the subjonctif',
        ExamFocus.codCoi => 'COD / COI pronouns (le, la, les, lui, leur, en, y)',
        ExamFocus.both => 'the subjonctif AND COD / COI pronouns',
        ExamFocus.any => 'the B1 tenses (passé composé, imparfait, futur, conditionnel) and connectors',
      };

  /// Corrects the text like a B1 teacher. Explanations in [language] (English name).
  static Future<WritingFeedback> correct(ExamSubject subject, String text, {required String language}) async {
    final r = await chat([
      {
        'role': 'system',
        'content': '''You are a strict but kind French teacher (Belgium, CEFR B1 exam, written production).
Mark the learner's text out of 20 with 4 criteria, each 0–5:
- "task": does it answer the subject, with the right type of text and length (${subject.minWords}–${subject.maxWords} words)?
- "grammar": correct grammar and conjugation; the exam checks ${_focusName(subject.focus)}.
- "vocabulary": range and precision of words, spelling.
- "organisation": paragraphs, logical order, connectors.
Be fair for B1: a clear text with a few mistakes gets 13–16; a perfect B1 text 18–20.
"mistakes": EVERY grammar, conjugation, agreement, spelling or word-choice mistake (max 15), in the order of the text:
  "wrong" = the learner's exact words (copy them exactly, short excerpt), "right" = the corrected words,
  "why" = the rule in very simple $language (one short sentence).
"good": 2–3 things done well ($language), e.g. a correct subjonctif or pronoun, with the French words.
"summary": 1–2 sentences in $language: the general impression.
"better_version": the same text corrected and slightly improved, still B1 level, same ideas, using ${_focusName(subject.focus)} where natural.
"next_tip": one concrete tip in $language for the next text.
Return JSON: {"criteria": {"task": 0, "grammar": 0, "vocabulary": 0, "organisation": 0}, "summary": "", "mistakes": [{"wrong": "", "right": "", "why": ""}], "good": [], "better_version": "", "next_tip": ""}''',
      },
      {
        'role': 'user',
        'content': 'Subject: ${subject.title}\n${subject.instruction}\n\nMy text (${wordCount(text)} words):\n$text',
      },
    ], temperature: 0.2, maxTokens: 4000);
    return WritingFeedback.fromJson(r);
  }

  /// A new exam subject that makes the learner use [focus].
  static Future<ExamSubject> newSubject(ExamFocus focus) async {
    final r = await chat([
      {
        'role': 'system',
        'content': '''You write writing subjects for a French B1 exam in Belgium (adults, everyday life).
Write ONE new subject that naturally makes the learner use ${_focusName(focus)}.
Types: email or letter to a friend, story of an experience, opinion with arguments, description, instructions.
"title": short French title. "instruction": the exam instruction in French (1–2 sentences, simple B1 French). "emoji": one emoji.
Return JSON: {"title": "", "instruction": "", "emoji": ""}''',
      },
      {'role': 'user', 'content': 'A new subject, please (random seed ${DateTime.now().millisecondsSinceEpoch % 9973}).'},
    ], temperature: 0.9, maxTokens: 400);
    final subject = ExamSubject.fromJson({...r, 'id': 'ai_${DateTime.now().millisecondsSinceEpoch}', 'focus': focus.name});
    if (subject == null) throw Exception('No subject');
    return subject;
  }

  // Drafts are kept on the device, so a text is never lost.
  static String _draftKey(String subjectId) => 'exam_draft_$subjectId';

  static Future<String> draft(String subjectId) async {
    try {
      return (await SharedPreferences.getInstance()).getString(_draftKey(subjectId)) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> saveDraft(String subjectId, String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      text.trim().isEmpty ? await prefs.remove(_draftKey(subjectId)) : await prefs.setString(_draftKey(subjectId), text);
    } catch (_) {}
  }
}
