import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/grammar_topic.dart';
import 'lessons/passe_compose_page.dart';
import 'lessons/present_page.dart';
import 'lessons/imparfait_page.dart';
import 'lessons/plus_que_parfait_page.dart';
import 'lessons/conditionnel_page.dart';
import 'lessons/negative_complex_page.dart';
import 'lessons/futur_proche_page.dart';
import 'lessons/futur_simple_page.dart';
import 'lessons/cod_coi_page.dart';
import 'lessons/si_seulement_page.dart';

class GrammarPage extends StatelessWidget {
  const GrammarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grammar Lessons'),
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
            itemCount: grammarTopics.length,
            itemBuilder: (context, index) {
              final topic = grammarTopics[index];
              return _buildTopicCard(context, topic);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, GrammarTopic topic) {
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
                      color: AppTheme.primary.withOpacity(0.1),
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
              Text(
                topic.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getLessonPage(String topicId) {
    switch (topicId) {
      case 'present':
        return const PresentPage();
      case 'passe_compose':
        return const PasseComposePage();
      case 'imparfait':
        return const ImparfaitPage();
      case 'plus_que_parfait':
        return const PlusQueParfaitPage();
      case 'conditionnel':
        return const ConditionnelPage();
      case 'negative_complex':
        return const NegativeComplexPage();
      case 'futur_proche':
        return const FuturProchePage();
      case 'futur_simple':
        return const FuturSimplePage();
      case 'cod_coi':
        return const CodCoiPage();
      case 'si_seulement':
        return const SiSeulementPage();
      default:
        return const Scaffold(body: Center(child: Text('Lesson not found')));
    }
  }
}
