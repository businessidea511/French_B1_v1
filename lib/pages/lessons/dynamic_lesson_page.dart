import 'package:flutter/material.dart';
import '../../widgets/lesson_template.dart';
import '../../models/lesson_topic.dart';
import '../../theme/app_theme.dart';

class DynamicLessonPage extends StatelessWidget {
  final LessonTopic topic;

  const DynamicLessonPage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return LessonTemplate(
      title: topic.title,
      icon: topic.icon,
      topic: topic.title,
      children: _buildWidgets(),
    );
  }

  List<Widget> _buildWidgets() {
    final List<Widget> result = [];

    // Support both old format (sections[]) and new format (widgets[])
    final rawWidgets = topic.content;
    if (rawWidgets == null || rawWidgets.isEmpty) return result;

    // Detect format: new format has "type" key, old format has "title"+"content"
    final isNewFormat = rawWidgets.isNotEmpty &&
        rawWidgets.first is Map &&
        (rawWidgets.first as Map).containsKey('type');

    if (isNewFormat) {
      return _buildFromWidgetFormat(rawWidgets);
    } else {
      return _buildFromSectionsFormat(rawWidgets);
    }
  }

  // ─── NEW FORMAT: widget-based JSON ───────────────────────────────────────
  List<Widget> _buildFromWidgetFormat(List<dynamic> widgetList) {
    final List<Widget> result = [];

    for (final w in widgetList) {
      if (w is! Map) continue;
      final type = (w['type'] ?? '').toString();
      final rawContent = (w['content'] ?? '').toString();

      // Skip any preamble the AI might have slipped in
      if (_isPreamble(rawContent) || _isPreamble(w['title']?.toString() ?? '')) {
        continue;
      }

      switch (type) {
        case 'section_title':
          final title = _clean(w['title'] ?? '');
          final emoji = (w['emoji'] ?? '📖').toString();
          if (title.isEmpty) break;
          result.add(SectionTitle(title, emoji: emoji));
          break;

        case 'text':
          final text = _clean(rawContent);
          if (text.isEmpty) break;
          result.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white),
              ),
            ),
          );
          break;

        case 'example':
          final french = _clean(w['french'] ?? '');
          final translation = _clean(w['translation'] ?? '');
          if (french.isEmpty) break;
          result.add(ExampleBox(french: french, english: translation));
          break;

        case 'tipbox':
          final title = _clean(w['title'] ?? 'Note');
          final content = _clean(rawContent);
          final color = _colorFromString(w['color']?.toString() ?? 'blue');
          final icon = _iconFromColor(w['color']?.toString() ?? 'blue');
          if (content.isEmpty) break;
          result.add(TipBox(
            title: title,
            content: content,
            icon: icon,
            color: color,
          ));
          break;

        default:
          // Fallback: render as plain text
          final text = _clean(rawContent);
          if (text.isNotEmpty) {
            result.add(Text(text,
                style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white)));
          }
      }

      result.add(const SizedBox(height: 8));
    }

    return result;
  }

  // ─── OLD FORMAT: sections-based JSON (backward compatibility) ────────────
  List<Widget> _buildFromSectionsFormat(List<dynamic> sections) {
    final List<Widget> result = [];
    final colors = [
      AppTheme.primary, AppTheme.secondary, AppTheme.accent,
      AppTheme.success, const Color(0xFFF59E0B), const Color(0xFFEC4899),
    ];

    final valid = sections.where((s) {
      final t = _clean((s['title'] ?? '').toString());
      final c = (s['content'] ?? '').toString();
      return !_isPreamble(t) && !_isPreamble(c.split('\n').take(2).join(' '));
    }).toList();

    for (int i = 0; i < valid.length; i++) {
      final title = _clean(valid[i]['title'] ?? 'Section ${i + 1}');
      final content = _clean(valid[i]['content'] ?? '');
      final color = colors[i % colors.length];
      final emoji = _emojiFor(title);

      result.add(SectionTitle(title, emoji: emoji));
      result.add(const SizedBox(height: 8));

      if (content.isNotEmpty) {
        result.add(TipBox(
          title: title,
          content: content,
          icon: Icons.info_outline_rounded,
          color: color,
        ));
      }
      result.add(const SizedBox(height: 16));
    }

    return result;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  bool _isPreamble(String text) {
    final t = text.toLowerCase().trim();
    return t.contains('here is') ||
        t.contains('following your') ||
        t.contains('translation of') ||
        t.contains('ترجمة') ||
        t.contains('محتوى الدرس') ||
        (t.startsWith(':') && t.length < 10);
  }

  /// Strips markdown symbols and ANY preamble line from text
  String _clean(String text) {
    if (text.isEmpty) return '';
    
    // Split into lines, filter out preamble lines, rejoin
    final lines = text.split('\n').where((line) {
      final t = line.trim();
      if (t.isEmpty) return false;
      final lower = t.toLowerCase();
      // Drop any line that contains AI meta-commentary
      if (lower.contains('here is')) return false;
      if (lower.contains('following your')) return false;
      if (lower.contains('translation of')) return false;
      if (lower.contains('as per your')) return false;
      if (lower.contains('per your instructions')) return false;
      if (lower.contains('تم الاحتفاظ')) return false;
      if (lower.contains('وفقًا للتعليمات')) return false;
      if (lower.contains('ملاحظة:')) return false;
      if (lower.contains('محتوى الدرس')) return false;
      return true;
    }).map((line) {
      // Remove markdown from each line
      return line
          .replaceAll('**', '')
          .replaceAll('__', '')
          .replaceAll(RegExp(r'^#{1,6}\s*'), '')
          .trim();
    }).where((line) => line.isNotEmpty).toList();
    
    return lines.join('\n').trim();
  }

  Color _colorFromString(String c) {
    switch (c) {
      case 'red':    return const Color(0xFFEF4444);
      case 'green':  return const Color(0xFF10B981);
      case 'yellow': return const Color(0xFFF59E0B);
      case 'purple': return const Color(0xFF8B5CF6);
      default:       return const Color(0xFF6366F1); // blue
    }
  }

  IconData _iconFromColor(String c) {
    switch (c) {
      case 'red':    return Icons.warning_amber_rounded;
      case 'green':  return Icons.check_circle_outline;
      case 'yellow': return Icons.lightbulb_outline;
      case 'purple': return Icons.auto_awesome;
      default:       return Icons.info_outline_rounded;
    }
  }

  String _emojiFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('intro') || t.contains('مقدمة')) return '🚀';
    if (t.contains('rule') || t.contains('قاعدة')) return '⚖️';
    if (t.contains('example') || t.contains('مثال')) return '💬';
    if (t.contains('mistake') || t.contains('خطأ')) return '⚠️';
    if (t.contains('practice') || t.contains('تدريب')) return '🎯';
    if (t.contains('vocab') || t.contains('مفردات')) return '📚';
    if (t.contains('tip') || t.contains('ملاحظة')) return '💡';
    return '📖';
  }
}
