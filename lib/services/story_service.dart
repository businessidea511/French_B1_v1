import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'deepseek_service.dart';

/// Story genres the learner can pick. Key → (emoji, label shown in the app).
const Map<String, (String, String)> storyGenres = {
  'mystery': ('🕵️', 'Mystère'),
  'thriller': ('⚡', 'Suspense'),
  'comedy': ('😂', 'Comédie'),
  'romance': ('💘', 'Romance'),
  'adventure': ('🧭', 'Aventure'),
  'drama': ('🏙️', 'Vie quotidienne'),
  'fantasy': ('✨', 'Fantastique'),
};

/// A serialized story ("feuilleton"): chapters written one at a time, each
/// ending on a cliffhanger. [memory] carries the plot between chapters.
class StorySeries {
  final String id;
  String title;
  String titleTranslation;
  final String genre;
  final String theme;
  final List<String> grammar;
  final List<String> lessons;
  final String language;
  final List<Map<String, dynamic>> chapters;
  Map<String, dynamic> memory;
  DateTime updatedAt;

  StorySeries({
    required this.id,
    required this.title,
    required this.titleTranslation,
    required this.genre,
    required this.theme,
    required this.grammar,
    required this.lessons,
    required this.language,
    required this.chapters,
    required this.memory,
    required this.updatedAt,
  });

  String get teaser => (memory['cliffhanger'] ?? '').toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'title_translation': titleTranslation,
        'genre': genre,
        'theme': theme,
        'grammar': grammar,
        'lessons': lessons,
        'language': language,
        'chapters': chapters,
        'memory': memory,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory StorySeries.fromJson(Map<String, dynamic> j) => StorySeries(
        id: j['id'] as String,
        title: (j['title'] ?? 'Histoire').toString(),
        titleTranslation: (j['title_translation'] ?? '').toString(),
        genre: (j['genre'] ?? 'mystery').toString(),
        theme: (j['theme'] ?? '').toString(),
        grammar: List<String>.from(j['grammar'] ?? const []),
        lessons: List<String>.from(j['lessons'] ?? const []),
        language: (j['language'] ?? 'English').toString(),
        chapters: [for (final c in (j['chapters'] as List? ?? const [])) Map<String, dynamic>.from(c as Map)],
        memory: Map<String, dynamic>.from(j['memory'] as Map? ?? const {}),
        updatedAt: DateTime.tryParse((j['updated_at'] ?? '').toString()) ?? DateTime.now(),
      );
}

class StoryService {
  static const String _prefKey = 'story_series_v2';
  static const int _maxSaved = 12;

  /// The AI call. Tests replace it with a fake.
  @visibleForTesting
  static Future<Map<String, dynamic>> Function(
    List<Map<String, dynamic>> messages, {
    bool thinking,
    double? temperature,
    int? maxTokens,
  }) chat = DeepSeekService.chatJson;

  // ── Library (saved on this device) ────────────────────────────────────────

  static Future<List<StorySeries>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) return [];
      final list = [
        for (final j in jsonDecode(raw) as List) StorySeries.fromJson(Map<String, dynamic>.from(j as Map))
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    } catch (e) {
      debugPrint('Could not load stories: $e');
      return [];
    }
  }

  static Future<void> save(StorySeries series) async {
    final all = await loadAll();
    all.removeWhere((s) => s.id == series.id);
    all.insert(0, series);
    await _write(all.take(_maxSaved).toList());
  }

  static Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((s) => s.id == id);
    await _write(all);
  }

  static Future<void> _write(List<StorySeries> all) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode([for (final s in all) s.toJson()]));
    } catch (e) {
      debugPrint('Could not save stories: $e');
    }
  }

  // ── Writing ────────────────────────────────────────────────────────────────

  /// Writes chapter 1 of a new series.
  static Future<StorySeries> start({
    required String genre,
    required String theme,
    required List<String> grammar,
    required List<String> lessons,
    required String language,
  }) async {
    final chapter = await _writeChapter(
      genre: genre,
      theme: theme,
      grammar: grammar,
      lessons: lessons,
      language: language,
      chapterNumber: 1,
    );
    final series = StorySeries(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: (chapter['series_title'] ?? 'Une histoire').toString(),
      titleTranslation: (chapter['series_title_translation'] ?? '').toString(),
      genre: genre,
      theme: theme,
      grammar: grammar,
      lessons: lessons,
      language: language,
      chapters: [chapter],
      memory: Map<String, dynamic>.from(chapter['memory'] as Map? ?? const {}),
      updatedAt: DateTime.now(),
    );
    await save(series);
    return series;
  }

  /// Writes the next chapter, picking up from the last cliffhanger.
  /// [readerIdea] is an optional wish from the learner for what happens next.
  static Future<StorySeries> continueSeries(StorySeries series, {String? readerIdea, String? language}) async {
    final last = series.chapters.last;
    final lastPages = (last['pages'] as List? ?? const []);
    final chapter = await _writeChapter(
      genre: series.genre,
      theme: series.theme,
      grammar: series.grammar,
      lessons: series.lessons,
      language: language ?? series.language,
      chapterNumber: series.chapters.length + 1,
      seriesTitle: series.title,
      memory: series.memory,
      lastPageText: lastPages.isEmpty ? '' : (lastPages.last as Map)['text'].toString(),
      readerIdea: readerIdea,
    );
    series.chapters.add(chapter);
    series.memory = Map<String, dynamic>.from(chapter['memory'] as Map? ?? series.memory);
    series.updatedAt = DateTime.now();
    await save(series);
    return series;
  }

  static Future<Map<String, dynamic>> _writeChapter({
    required String genre,
    required String theme,
    required List<String> grammar,
    required List<String> lessons,
    required String language,
    required int chapterNumber,
    String? seriesTitle,
    Map<String, dynamic>? memory,
    String? lastPageText,
    String? readerIdea,
  }) async {
    final genreLabel = storyGenres[genre]?.$2 ?? genre;
    final isFirst = chapterNumber == 1;

    final continuation = isFirst
        ? '''
THIS IS CHAPTER 1.
- The FIRST SENTENCE is the hook: start in the middle of something — a strange event, a secret, a danger, a funny
  disaster, or a question the reader must have answered. Never open with the weather, "Il était une fois",
  or someone's morning routine.
- Within the first page, the main character wants something and runs into a problem.'''
        : '''
THIS IS CHAPTER $chapterNumber of "$seriesTitle".
STORY MEMORY (for you only — do not recap it in the chapter):
${jsonEncode(memory ?? const {})}
LAST PAGE OF THE PREVIOUS CHAPTER:
"""$lastPageText"""
- Start IMMEDIATELY after that cliffhanger, in the same moment. No summary of earlier chapters.
- Keep every character, name, place and fact consistent with the memory.
- Answer at least one open question, then add a new complication or twist.
${chapterNumber >= 8 ? '- The story may reach a satisfying ending in this chapter if it feels right; otherwise keep going.' : '- Do NOT end the story; it continues.'}
${readerIdea == null || readerIdea.trim().isEmpty ? '' : '- The reader would love this to happen: "${readerIdea.trim()}". Work it in if it fits the story.'}''';

    final chapter = await chat([
      {
        'role': 'system',
        'content': '''You are a bestselling author of addictive serial stories ("feuilletons") written in French for B1 learners
whose own language is $language. Readers should NOT be able to stop reading.

GENRE: $genreLabel. THEME: ${theme.trim().isEmpty ? 'your choice' : theme.trim()}.
$continuation

CRAFT
- A main character the reader cares about, with a clear goal and a flaw; side characters with distinct voices.
- Show, don't tell: concrete details (sounds, smells, objects), real dialogue with « » or —.
- Every page adds tension, a question, a joke or a surprise. One real twist in the chapter.
- END ON A CLIFFHANGER: a revelation, a danger, a hard choice, or a line of dialogue that changes everything.
  The last sentence must make the reader tap "next chapter".
- Set in real places in Belgium (Bruxelles, Liège, Namur, Gand, Bruges, the coast…) used naturally — not tourist-guide text.
- No moral lessons, no explaining the plot, no "ils vécurent heureux".

FRENCH LEVEL: B1. Mostly short and medium sentences, everyday vocabulary, some spoken French in dialogue.
GRAMMAR TO PRACTISE: ${grammar.isEmpty ? 'a natural mix of B1 tenses (passé composé, imparfait, futur, conditionnel)' : grammar.join(', ')} — use it often and naturally.
VOCABULARY TOPICS: ${lessons.isEmpty ? 'free' : lessons.join(', ')}.
Put **double asterisks** around 2–4 uses of the practised grammar or vocabulary per page.

LENGTH: 4 pages, 80–120 words each.

PER PAGE
- "text": the French page.
- "translation": the page translated naturally into $language.
- "annotations": one per **bold** part (2–4): {"original": exact French words, "hint": 1–3 word label (e.g. "Imparfait"),
  "explanation": one simple sentence in $language}.

AFTER THE CHAPTER
- "questions": 3 short comprehension questions in French that also practise the grammar. Item format:
  {"question": "...", "options": ["...", "...", "..."], "correct": 0, "explanation": "in $language"} or
  {"question": "... ___ ...", "answer": "...", "alternatives": [], "explanation": "in $language"}.
- "memory": updated story memory IN ENGLISH for writing the next chapter:
  {"summary": "everything that has happened so far, 5–8 sentences", "characters": [{"name": "...", "who": "role, personality, secrets"}],
   "open_threads": ["unanswered questions and mysteries"], "cliffhanger": "the chapter's final situation in one French sentence"}

JSON:
{${isFirst ? '"series_title": "short catchy French title", "series_title_translation": "in $language", ' : ''}"chapter_title": "French chapter title",
 "pages": [{"text": "...", "translation": "...", "annotations": [...]}], "questions": [...], "memory": {...}}'''
      },
      {'role': 'user', 'content': 'Write chapter $chapterNumber now.'},
    ], temperature: 0.9, maxTokens: 9000);

    final pages = (chapter['pages'] as List? ?? const [])
        .whereType<Map>()
        .where((p) => (p['text'] ?? '').toString().trim().isNotEmpty)
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    if (pages.isEmpty) throw Exception('The chapter came back empty. Please try again.');
    chapter['pages'] = pages;
    chapter['number'] = chapterNumber;
    // The app shows "Chapitre N · <title>", so drop a "Chapitre N :" prefix from the AI.
    chapter['chapter_title'] = (chapter['chapter_title'] ?? '')
        .toString()
        .replaceFirst(RegExp(r'^\s*chapitre\s*\d+\s*[:.\-–—]?\s*', caseSensitive: false), '')
        .trim();
    return chapter;
  }
}
