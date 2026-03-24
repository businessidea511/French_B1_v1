import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/lesson_topic.dart';
import '../../services/language_provider.dart';
import '../../services/deepseek_service.dart';
import 'metiers_page.dart';

class LessonsPage extends StatelessWidget {
  const LessonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 900
                  ? 3
                  : MediaQuery.of(context).size.width > 600
                      ? 2
                      : 1,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.6,
            ),
            itemCount: lessonTopics.length,
            itemBuilder: (context, index) {
              final topic = lessonTopics[index];
              return _buildTopicCard(context, topic, lp);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopicCard(
      BuildContext context, LessonTopic topic, LanguageProvider lp) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => _getLessonPage(topic.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        topic.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward,
                      color: AppTheme.textTertiary, size: 20),
                ],
              ),
              const Spacer(),
              Text(
                topic.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              FutureBuilder<String>(
                future: lp.currentLanguage == AppLanguage.english
                    ? Future.value(topic.subtitle)
                    : DeepSeekService.translateText(
                        topic.subtitle, lp.currentLanguage.name),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? topic.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getLessonPage(String topicId) {
    switch (topicId) {
      case 'metiers':
        return const MetiersPage();
      default:
        return const Scaffold(body: Center(child: Text('Lesson not found')));
    }
  }
}
