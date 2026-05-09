import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../widgets/translated_markdown.dart';
import '../../widgets/lesson_template.dart';
import '../../models/lesson_topic.dart';

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
      children: sections.map((section) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(section['title'] ?? 'Section'),
            TranslatedMarkdown(
              data: section['content'] ?? '',
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white),
                h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                em: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }
}
