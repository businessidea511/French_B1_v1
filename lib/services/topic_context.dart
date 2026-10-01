import '../models/grammar_topic.dart';
import '../models/lesson_topic.dart';
import 'lessons_provider.dart';

/// Turns a lesson or grammar topic into a short text summary of what it
/// teaches, so AI-generated practice (exercises, flashcards) tests the
/// learner on the actual lesson instead of on the topic name alone.
class TopicContext {
  static const int _maxChars = 6000;

  /// Summary for the topic with this [title], or null if it has no content.
  static String? forTitle(LessonsProvider provider, String title) {
    List<dynamic>? content;
    final grammar = provider.allGrammar.where((t) => t.title == title).firstOrNull;
    if (grammar != null) {
      content = grammar.content;
      // Built-in topics with an empty cloud row still have their seed content.
      if (content == null || content.isEmpty) {
        content = grammarTopics.where((t) => t.id == grammar.id).firstOrNull?.content;
      }
    } else {
      final lesson = provider.allLessons.where((t) => t.title == title).firstOrNull;
      content = lesson?.content;
      if (lesson != null && (content == null || content.isEmpty)) {
        content = lessonTopics.where((t) => t.id == lesson.id).firstOrNull?.content;
      }
    }
    if (content == null || content.isEmpty) return null;
    final summary = summarize(content);
    return summary.isEmpty ? null : summary;
  }

  /// Keeps the parts worth practising: rule names, formulas, vocabulary,
  /// tables and example sentences. Long explanations are skipped.
  static String summarize(List<dynamic> content) {
    final buffer = StringBuffer();
    String cut(Object? s, int max) {
      final t = (s ?? '').toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      return t.length > max ? '${t.substring(0, max)}…' : t;
    }

    for (final w in content) {
      if (w is! Map) continue;
      final line = switch (w['type']) {
        'section_title' => '\n## ${cut(w['title'], 120)}',
        'tipbox' => '- ${cut(w['title'], 60)}: ${cut(w['content'], 220)}',
        'french_tipbox' => '- ${cut(w['title'], 60)}: ${cut(w['frenchText'], 400)}',
        'table' => '- table ${cut((w['headers'] as List?)?.join(' | '), 120)}: '
            '${cut((w['rows'] as List?)?.take(8).map((r) => (r as List).join(' | ')).join(' / '), 400)}',
        'example' => '- e.g. ${cut(w['french'], 160)}',
        'mistake' => '- mistake: ${cut(w['wrong'], 100)} → ${cut(w['right'], 100)}',
        'expression' => '- expression: ${cut(w['expression'], 80)} (${cut(w['meaning'], 80)})',
        _ => null,
      };
      if (line == null) continue;
      if (buffer.length + line.length > _maxChars) break;
      buffer.writeln(line);
    }
    return buffer.toString().trim();
  }
}
