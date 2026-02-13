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
          'Imagine a MIRROR. 🪞 In the "Passive Voice," we just flip the sentence! The one who WAS the target now becomes the "Boss" (the subject).',
          style:
              TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.bold),
        ),
        const SectionTitle('💡 Why use it? (The "Lazy" Secret)'),
        const TranslatedText(
          'We use it when we don\'t know who did the action, or we don\'t care. \n'
          'Example: "The bank was robbed." (We don\'t know who did it!)',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('🛠️ The 3-Step Magic Formula'),
        const TipBox(
          title: 'Step-by-Step Flip',
          content: '1. Take the Object and make it the Subject.\n'
              '2. Add the verb ÊTRE in the SAME tense as the original verb.\n'
              '3. Add the Past Participle of the original verb.\n\n'
              '⚠️ PRO RULE: The participle must MATCH the new subject (add -e for feminine, -s for plural)!',
          icon: Icons.auto_fix_high,
          color: Color(0xFF10B981),
        ),
        const SectionTitle('📝 See the Flip!'),
        const ExampleBox(
          french: 'Le chat mange la souris. (Active)',
          english: 'The cat eats the mouse.',
        ),
        const ExampleBox(
          french: 'La souris est mangée par le chat. (Passive)',
          english: 'The mouse is eaten by the cat.',
        ),
        const TranslatedText(
          'See? "Mange" (Present) became "EST" (Present) + "mangée" (Matched to mouse).',
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
        const SectionTitle('🕰️ Different Tenses (No Panic!)'),
        const TranslatedText(
          '• Past: J\'ai fini le livre → Le livre A ÉTÉ fini.\n'
          '• Future: Tu feras le gâteau → Le gâteau SERA fait.\n'
          '• Imparfait: Il lisait l\'histoire → L\'histoire ÉTAIT lue.',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const TipBox(
          title: '🤫 The "ON" Shortcut',
          content:
              'DUMMY TIP: French people are lazy! Instead of saying "La porte a été fermée" (passive), they usually say "On a fermé la porte" (Someone closed it). It sounds much more natural!',
          icon: Icons.psychology,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}
