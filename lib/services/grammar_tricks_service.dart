import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/grammar_tricks.dart';
import '../pages/lessons/dynamic_lesson_page.dart';
import 'deepseek_service.dart';

/// Finds or writes the memory tricks of a grammar topic.
///
/// Order: hand-written tricks → tricks saved in the topic (written by the AI
/// when the admin created or rebuilt it) → tricks written on this device.
class GrammarTricksService {
  /// The AI call. Tests replace it with a fake.
  @visibleForTesting
  static Future<Map<String, dynamic>> Function(
    List<Map<String, dynamic>> messages, {
    bool thinking,
    double? temperature,
    int? maxTokens,
  }) chat = DeepSeekService.chatJson;

  static String _prefKey(String id) => 'grammar_tricks_$id';

  /// The tricks already available, without asking the AI.
  static Future<GrammarTricks?> find(String id, String title, List<dynamic>? content) async {
    final known = curatedTricksFor(id, title) ?? embeddedTricks(content);
    if (known != null) return known;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey(id));
      if (saved != null) return GrammarTricks.fromJson(jsonDecode(saved));
    } catch (_) {}
    return null;
  }

  /// Writes the tricks of a topic with the AI and keeps them on this device.
  static Future<GrammarTricks> writeAndKeep(String id, String title, String subtitle, List<dynamic>? content) async {
    final tricks = await write(title, subtitle, content);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey(id), jsonEncode(tricks.toWidget()));
    } catch (_) {}
    return tricks;
  }

  /// The lesson's own texts, short, so the tricks match what the course teaches.
  static String _lessonDigest(List<dynamic>? content) {
    final b = StringBuffer();
    for (final w in content ?? const []) {
      if (w is! Map || w['type'] == GrammarTricks.widgetType) continue;
      for (final key in ['title', 'content', 'frenchText', 'french', 'translation']) {
        final v = DynamicLessonPage.clean('${w[key] ?? ''}');
        if (v.isNotEmpty) b.writeln(v);
      }
      if (b.length > 7000) break;
    }
    final s = b.toString();
    return s.length > 7000 ? s.substring(0, 7000) : s;
  }

  /// Asks the AI for the tricks of a topic.
  static Future<GrammarTricks> write(String title, String subtitle, List<dynamic>? content) async {
    final digest = _lessonDigest(content);
    final r = await chat([
      {
        'role': 'system',
        'content': '''You are an expert teacher of French (CEFR B1) for adult migrants in Belgium.
Make an "easy-peasy" memory card for ONE grammar topic: not the whole lesson, only what makes the rule stick in the mind.
- "one_line": the whole topic in ONE simple sentence (English).
- "tricks": 3 to 6 memory tricks. Each has a short catchy "title" (English, may quote French words), a "trick" (English, 1–3 short sentences: a mnemonic, a pattern, a question to ask, a shortcut, an image), and 1–3 short French "examples" (correct B1 French, daily life).
  Prefer real tricks (acronyms, "ask the question…", sound patterns, opposite pairs, formulas like "nous − ons + ais"). If the topic has none, give the clearest short summary rules.
- "traps": 2 or 3 classic mistakes: "wrong" (French), "right" (French), "why" (English, very short).
Everything must be 100% correct French grammar. No Belgian specifics unless the topic is about them.
Return JSON: {"one_line": "...", "tricks": [{"title": "...", "trick": "...", "examples": ["..."]}], "traps": [{"wrong": "...", "right": "...", "why": "..."}]}''',
      },
      {
        'role': 'user',
        'content': 'Topic: $title${subtitle.isEmpty ? '' : ' ($subtitle)'}\n${digest.isEmpty ? '' : 'What the lesson says:\n$digest'}',
      },
    ], temperature: 0.3, maxTokens: 2500);
    final tricks = GrammarTricks.fromJson(r);
    if (tricks == null) throw Exception('No tricks in the answer');
    return tricks;
  }

  /// The topic's content with its tricks inside (replaces old ones). Topics
  /// with hand-written tricks are left as they are. Never fails: without
  /// tricks the content is returned unchanged.
  static Future<List<dynamic>> attach(String id, String title, String subtitle, List<dynamic> content) async {
    if (curatedTricksFor(id, title) != null) return content;
    try {
      final tricks = await write(title, subtitle, content).timeout(const Duration(seconds: 90));
      return [
        for (final w in content)
          if (!(w is Map && w['type'] == GrammarTricks.widgetType)) w,
        tricks.toWidget(),
      ];
    } catch (e) {
      debugPrint('Memory tricks not written: $e');
      return content;
    }
  }
}
