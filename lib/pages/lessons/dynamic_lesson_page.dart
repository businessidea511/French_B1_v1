import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/lesson_template.dart';
import '../../models/lesson_topic.dart';
import '../../theme/app_theme.dart';
import '../../services/language_provider.dart';
import '../../services/deepseek_service.dart';

class DynamicLessonPage extends StatefulWidget {
  final LessonTopic topic;

  const DynamicLessonPage({super.key, required this.topic});

  @override
  State<DynamicLessonPage> createState() => _DynamicLessonPageState();
}

class _DynamicLessonPageState extends State<DynamicLessonPage> {
  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    
    return LessonTemplate(
      title: widget.topic.title,
      icon: widget.topic.icon,
      topic: widget.topic.title,
      children: _buildWidgets(lp),
    );
  }

  List<Widget> _buildWidgets(LanguageProvider lp) {
    final List<Widget> result = [];
    final rawWidgets = widget.topic.content;
    if (rawWidgets == null || rawWidgets.isEmpty) return result;

    final isNewFormat = rawWidgets.isNotEmpty &&
        rawWidgets.first is Map &&
        (rawWidgets.first as Map).containsKey('type');

    if (isNewFormat) {
      return _buildFromWidgetFormat(rawWidgets, lp);
    } else {
      return _buildFromSectionsFormat(rawWidgets, lp);
    }
  }

  List<Widget> _buildFromWidgetFormat(List<dynamic> widgetList, LanguageProvider lp) {
    final List<Widget> result = [];

    for (final w in widgetList) {
      if (w is! Map) continue;
      final type = (w['type'] ?? '').toString();
      final rawContent = (w['content'] ?? '').toString();

      if (_isPreamble(rawContent) || _isPreamble(w['title']?.toString() ?? '')) {
        continue;
      }

      switch (type) {
        case 'section_title':
          final title = _clean(w['title'] ?? '');
          final emoji = (w['emoji'] ?? '📖').toString();
          if (title.isEmpty) break;
          result.add(_TranslatedWidget(
            originalText: title,
            targetLanguage: lp.currentLanguage.name,
            builder: (translated) => SectionTitle(translated, emoji: emoji),
          ));
          break;

        case 'text':
          final text = _clean(rawContent);
          if (text.isEmpty) break;
          result.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TranslatedWidget(
                originalText: text,
                targetLanguage: lp.currentLanguage.name,
                builder: (translated) => Text(
                  translated,
                  style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white),
                ),
              ),
            ),
          );
          break;

        case 'example':
          final french = _clean(w['french'] ?? '');
          final translation = _clean(w['translation'] ?? '');
          if (french.isEmpty) break;
          
          result.add(_TranslatedWidget(
            originalText: translation,
            targetLanguage: lp.currentLanguage.name,
            builder: (translated) => ExampleBox(
              french: french, 
              english: translated,
            ),
          ));
          break;

        case 'tipbox':
          final title = _clean(w['title'] ?? 'Note');
          final content = _clean(rawContent);
          final color = _colorFromString(w['color']?.toString() ?? 'blue');
          final icon = _iconFromColor(w['color']?.toString() ?? 'blue');
          if (content.isEmpty) break;
          
          result.add(_TranslatedWidget(
            originalText: content,
            targetLanguage: lp.currentLanguage.name,
            builder: (translatedContent) => _TranslatedWidget(
              originalText: title,
              targetLanguage: lp.currentLanguage.name,
              builder: (translatedTitle) => TipBox(
                title: translatedTitle,
                content: translatedContent,
                icon: icon,
                color: color,
              ),
            ),
          ));
          break;

        default:
          final text = _clean(rawContent);
          if (text.isNotEmpty) {
            result.add(_TranslatedWidget(
              originalText: text,
              targetLanguage: lp.currentLanguage.name,
              builder: (translated) => Text(
                translated,
                style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white),
              ),
            ));
          }
      }
      result.add(const SizedBox(height: 8));
    }
    return result;
  }

  List<Widget> _buildFromSectionsFormat(List<dynamic> sections, LanguageProvider lp) {
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

      result.add(_TranslatedWidget(
        originalText: title,
        targetLanguage: lp.currentLanguage.name,
        builder: (tTitle) => SectionTitle(tTitle, emoji: emoji),
      ));
      
      result.add(const SizedBox(height: 8));

      if (content.isNotEmpty) {
        result.add(_TranslatedWidget(
          originalText: content,
          targetLanguage: lp.currentLanguage.name,
          builder: (tContent) => _TranslatedWidget(
            originalText: title,
            targetLanguage: lp.currentLanguage.name,
            builder: (tTitle) => TipBox(
              title: tTitle,
              content: tContent,
              icon: Icons.info_outline_rounded,
              color: color,
            ),
          ),
        ));
      }
      result.add(const SizedBox(height: 16));
    }
    return result;
  }

  bool _isPreamble(String text) {
    final t = text.toLowerCase().trim();
    return t.contains('here is') ||
        t.contains('following your') ||
        t.contains('translation of') ||
        t.contains('ترجمة') ||
        t.contains('محتوى الدرس') ||
        (t.startsWith(':') && t.length < 10);
  }

  String _clean(String text) {
    if (text.isEmpty) return '';
    final lines = text.split('\n').where((line) {
      final t = line.trim();
      if (t.isEmpty) return false;
      final lowerLine = t.toLowerCase();
      final badPhrases = [
        'here is', 'following your', 'translation of', 'as per your', 
        'per your instructions', 'sorry', 'cannot translate', 'assist with this',
        'intended to provide', 'appears you may', 'already in arabic',
        'preserve', 'i have kept', 'requested content', 'given text',
        'instruction was to', 'please provide a french', 'into arabic',
        'تم الاحتفاظ', 'وفقًا للتعليمات', 'ملاحظة:', 'محتوى الدرس',
        'عذراً', 'لا يمكنني', 'بالفعل باللغة العربية', 'موجود بالفعل',
        'تمت الترجمة', 'أنا آسف', 'يبدو أن', 'يرجى تقديم'
      ];
      for (var phrase in badPhrases) {
        if (lowerLine.contains(phrase)) return false;
      }
      return true;
    }).map((line) {
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
      default:       return const Color(0xFF6366F1);
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

/// A helper widget that automatically translates text if needed
class _TranslatedWidget extends StatelessWidget {
  final String originalText;
  final String targetLanguage;
  final Widget Function(String translatedText) builder;

  const _TranslatedWidget({
    required this.originalText,
    required this.targetLanguage,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    // If it's already in the target language (rough detection), just show it
    final bool isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(originalText);
    final bool wantArabic = targetLanguage.toLowerCase().contains('arab');
    
    // If text is long and looks like English, but we want Arabic/Ukrainian/etc.
    // We use DeepSeekService.translateText for on-the-fly translation
    return FutureBuilder<String>(
      future: DeepSeekService.translateText(originalText, targetLanguage),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While waiting, show original text with slight opacity or a tiny loader
          return Opacity(
            opacity: 0.7,
            child: builder(originalText),
          );
        }
        return builder(snapshot.data ?? originalText);
      },
    );
  }
}
