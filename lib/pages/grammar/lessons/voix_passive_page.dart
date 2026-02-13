import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class VoixPassivePage extends StatelessWidget {
  const VoixPassivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return LessonTemplate(
      title: lp.currentLanguage == AppLanguage.french
          ? 'La Voix Passive'
          : 'Passive Voice',
      icon: '🔄',
      children: [
        const TranslatedText(
          'The passive voice (la voix passive) is used to shift the focus from the person performing the action to the action itself or the person/thing receiving it.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('🎯 When to Use It'),
        const TranslatedText(
          '• When the person doing the action is unknown or unimportant\n'
          '• To emphasize the result or the object of the action\n'
          '• In formal or journalistic writing',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('🔧 How to Form It'),
        const TipBox(
          title: 'The Formula',
          content:
              'ÊTRE (conjugated) + PAST PARTICIPLE (+ PAR + agent)\n\nNote: The past participle MUST agree in gender and number with the SUBJECT of the sentence!',
          icon: Icons.unfold_more,
          color: Color(0xFF10B981),
        ),
        const SectionTitle('📝 Examples in Different Tenses'),
        const TranslatedText(
          'Present: Le chat mange la souris → La souris est mangée par le chat.\n'
          'Passé Composé: J\'ai fini le travail → Le travail a été fini par moi.\n'
          'Futur Simple: Ils construiront la maison → La maison sera construite.',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('✨ More Examples'),
        const ExampleBox(
          french: 'Les fleurs sont arrosées chaque matin.',
          english: 'The flowers are watered every morning.',
        ),
        const ExampleBox(
          french: 'Le coupable a été arrêté par la police.',
          english: 'The culprit was arrested by the police.',
        ),
        const ExampleBox(
          french: 'Ce livre est écrit en français.',
          english: 'This book is written in French.',
        ),
        const TipBox(
          title: '💡 Pro Tip',
          content:
              'French speakers often use "ON" instead of the passive voice in casual conversation. Instead of "La porte a été fermée", they might say "On a fermé la porte".',
          icon: Icons.lightbulb,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}
