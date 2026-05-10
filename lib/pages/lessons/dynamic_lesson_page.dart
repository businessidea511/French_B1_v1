import 'package:flutter/material.dart';
import '../../widgets/lesson_template.dart';
import '../../models/lesson_topic.dart';
import '../../theme/app_theme.dart';

class DynamicLessonPage extends StatelessWidget {
  final LessonTopic topic;

  const DynamicLessonPage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> sections = topic.content ?? [];

    return LessonTemplate(
      title: topic.title,
      icon: topic.icon,
      topic: topic.title,
      children: _buildSections(sections),
    );
  }

  List<Widget> _buildSections(List<dynamic> sections) {
    final List<Widget> widgets = [];
    final sectionColors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.accent,
      AppTheme.success,
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
    ];

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      final String title = section['title'] ?? 'Section ${i + 1}';
      final String content = section['content'] ?? '';
      final Color sectionColor = sectionColors[i % sectionColors.length];
      final String emoji = _emojiForSection(title);

      // Section header
      widgets.add(SectionTitle(title, emoji: emoji));

      // Parse content lines into styled widgets
      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final List<List<String>> examples = [];
      final List<String> bullets = [];
      final List<String> tips = [];
      final List<String> prose = [];

      for (final line in lines) {
        final t = line.trim();
        if (_isExample(t)) {
          examples.add(_parseExample(t));
        } else if (_isTip(t)) {
          tips.add(t.replaceAll(RegExp(r'^[⚠️💡📌✅❌🔑🎯➡️•\-\*]\s*'), ''));
        } else if (_isBullet(t)) {
          bullets.add(t.replaceAll(RegExp(r'^[-•*]\s*'), ''));
        } else {
          prose.add(t);
        }
      }

      // Render prose as a styled tip box
      if (prose.isNotEmpty) {
        widgets.add(
          TipBox(
            title: title,
            content: prose.join('\n'),
            icon: _iconForSection(title),
            color: sectionColor,
          ),
        );
      }

      // Render examples
      if (examples.isNotEmpty) {
        widgets.add(_buildVocabTable(examples, sectionColor));
      }

      // Render bullets as a styled card
      if (bullets.isNotEmpty) {
        widgets.add(_buildBulletCard(bullets, sectionColor));
      }

      // Render tips
      for (final tip in tips) {
        widgets.add(
          TipBox(
            title: '💡 Note',
            content: tip,
            icon: Icons.lightbulb_outline,
            color: const Color(0xFFF59E0B),
          ),
        );
      }

      widgets.add(const SizedBox(height: 8));
    }

    return widgets;
  }

  bool _isExample(String line) {
    return line.contains('→') || line.contains('->') ||
        (line.contains(':') && line.length < 120 && !line.startsWith('http'));
  }

  bool _isTip(String line) {
    return line.startsWith('💡') || line.startsWith('⚠️') ||
        line.startsWith('📌') || line.startsWith('🔑') ||
        line.startsWith('✅') || line.startsWith('❌');
  }

  bool _isBullet(String line) {
    return line.startsWith('-') || line.startsWith('•') || line.startsWith('*');
  }

  List<String> _parseExample(String line) {
    if (line.contains('→')) return line.split('→').map((e) => e.trim()).toList();
    if (line.contains('->')) return line.split('->').map((e) => e.trim()).toList();
    if (line.contains(':')) {
      final idx = line.indexOf(':');
      return [line.substring(0, idx).trim(), line.substring(idx + 1).trim()];
    }
    return [line, ''];
  }

  Widget _buildVocabTable(List<List<String>> rows, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: rows.map((row) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.isNotEmpty ? row[0] : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: color, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    row.length > 1 ? row[1] : '',
                    style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 15),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBulletCard(List<String> bullets, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: bullets.map((b) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Text(
                    b,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _emojiForSection(String title) {
    final t = title.toLowerCase();
    if (t.contains('vocab') || t.contains('مفرد') || t.contains('mot')) return '📚';
    if (t.contains('example') || t.contains('مثال') || t.contains('exemple')) return '💬';
    if (t.contains('grammar') || t.contains('قاعد') || t.contains('grammaire')) return '📐';
    if (t.contains('tip') || t.contains('note') || t.contains('ملاحظ')) return '💡';
    if (t.contains('exercise') || t.contains('تمرين') || t.contains('exercice')) return '✏️';
    if (t.contains('culture') || t.contains('ثقاف')) return '🌍';
    if (t.contains('express') || t.contains('تعبير')) return '🗣️';
    return '📖';
  }

  IconData _iconForSection(String title) {
    final t = title.toLowerCase();
    if (t.contains('vocab') || t.contains('مفرد')) return Icons.menu_book_rounded;
    if (t.contains('grammar') || t.contains('قاعد')) return Icons.rule_rounded;
    if (t.contains('tip') || t.contains('note')) return Icons.lightbulb_outline;
    if (t.contains('exercise') || t.contains('تمرين')) return Icons.edit_note_rounded;
    return Icons.info_outline_rounded;
  }
}
