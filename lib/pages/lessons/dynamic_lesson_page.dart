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

    // Extremely aggressive filter for preamble sections
    final validSections = sections.where((s) {
      final title = (s['title'] ?? '').toString().toLowerCase();
      final content = (s['content'] ?? '').toString().toLowerCase();
      
      bool isPreamble(String text) {
        final t = text.toLowerCase().trim();
        return t.contains('here is') || 
               t.contains('following your') || 
               t.contains('translation of') ||
               t.contains('ترجمة') ||
               t.contains('محتوى الدرس') ||
               t.startsWith(':') || 
               t.length < 2;
      }

      return !isPreamble(title) && !isPreamble(content.split('\n').take(2).join(' '));
    }).toList();

    for (int i = 0; i < validSections.length; i++) {
      final section = validSections[i];
      final String title = _cleanText(section['title'] ?? 'Section ${i + 1}');
      final String content = _cleanText(section['content'] ?? '');
      final Color sectionColor = sectionColors[i % sectionColors.length];
      // Use dynamic emojis based on title
      String sectionEmoji = '📝';
      final lowerTitle = title.toLowerCase();
      if (lowerTitle.contains('intro')) sectionEmoji = '🚀';
      if (lowerTitle.contains('rule') || lowerTitle.contains('قاعدة')) sectionEmoji = '⚖️';
      if (lowerTitle.contains('example') || lowerTitle.contains('مثال')) sectionEmoji = '💡';
      if (lowerTitle.contains('mistake') || lowerTitle.contains('خطأ')) sectionEmoji = '⚠️';
      if (lowerTitle.contains('practice') || lowerTitle.contains('تدريب')) sectionEmoji = '🎯';

      widgets.add(SectionTitle(title, emoji: sectionEmoji));

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

      // Render content based on section type
      final isExampleSection = lowerTitle.contains('example') || lowerTitle.contains('مثال') || lowerTitle.contains('phrases');
      final isRuleSection = lowerTitle.contains('rule') || lowerTitle.contains('explanation') || lowerTitle.contains('قاعدة') || lowerTitle.contains('شرح');

      if (isRuleSection) {
        widgets.add(
          TipBox(
            title: title,
            content: prose.isNotEmpty ? prose.join('\n') : content,
            icon: _iconForSection(title),
            color: sectionColor,
          ),
        );
      } else if (isExampleSection && examples.isNotEmpty) {
        widgets.add(_buildVocabTable(examples, sectionColor));
      } else if (prose.isNotEmpty) {
        widgets.add(
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: sectionColor.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Text(
              prose.join('\n'),
              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white),
            ),
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

  /// Strips markdown symbols and preamble phrases from AI-generated text
  String _cleanText(String text) {
    if (text.isEmpty) return '';
    
    return text
        // Remove markdown symbols everywhere
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('* ', '')
        .replaceAll('- ', '')
        // Remove heading markers
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        // Aggressively remove any line containing preamble keywords
        .replaceAll(RegExp(r'^.*?(here is|following your|translation of|محتوى الدرس|ترجمة).*?(\n|$)', caseSensitive: false, multiLine: true), '')
        // Remove leading colons or dots that AI sometimes adds
        .replaceFirst(RegExp(r'^[:\.\s]+'), '')
        // Clean up extra blank lines
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
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
