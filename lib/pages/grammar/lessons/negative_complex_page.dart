import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class NegativeComplexPage extends StatelessWidget {
  const NegativeComplexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return LessonTemplate(
      title: lp.currentLanguage == AppLanguage.french
          ? 'Négation Complexe'
          : 'Complex Negation',
      icon: '⛔',
      children: [
        const TranslatedText(
          'You know "ne...pas" (not), but French has MORE ways to say NO! Let\'s master never, nothing, nobody, and no more!',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('🚫 The Negative Squad'),
        const SectionTitle('1. NE... JAMAIS (never)'),
        const ExampleBox(
          french: 'Je ne mange jamais de viande',
          english: 'I never eat meat',
        ),
        const ExampleBox(
          french: 'Il n\'est jamais en retard',
          english: 'He is never late',
        ),
        const SectionTitle('2. NE... RIEN (nothing)'),
        const ExampleBox(
          french: 'Je ne comprends rien',
          english: 'I understand nothing / I don\'t understand anything',
        ),
        const ExampleBox(
          french: 'Elle n\'a rien dit',
          english: 'She said nothing / She didn\'t say anything',
        ),
        const SectionTitle('3. NE... PERSONNE (nobody)'),
        const ExampleBox(
          french: 'Je ne vois personne',
          english: 'I see nobody / I don\'t see anyone',
        ),
        const ExampleBox(
          french: 'Personne n\'est venu',
          english: 'Nobody came',
        ),
        const SectionTitle('4. NE... PLUS (no more / no longer)'),
        const ExampleBox(
          french: 'Je n\'ai plus d\'argent',
          english: 'I don\'t have money anymore / I have no more money',
        ),
        const ExampleBox(
          french: 'Il ne fume plus',
          english: 'He doesn\'t smoke anymore',
        ),
        const SectionTitle('5. NE... AUCUN(E) (no, none, not any)'),
        const ExampleBox(
          french: 'Je n\'ai aucune idée',
          english: 'I have no idea',
        ),
        const ExampleBox(
          french: 'Il n\'y a aucun problème',
          english: 'There is no problem',
        ),
        const TipBox(
          title: '🎯 Position in Passé Composé',
          content: 'ne + helping verb + jamais/rien/plus + past participle\n\n'
              'Example: Je n\'ai jamais vu ce film\n\n'
              'BUT with PERSONNE: Je n\'ai vu personne (after participle)',
          icon: Icons.info,
          color: Color(0xFF6366F1),
        ),
        const TipBox(
          title: '⚠️ Double Negatives are OK!',
          content: 'In French, you CAN combine negatives:\n'
              '• Je ne dis jamais rien (I never say anything)\n'
              '• Il n\'y a plus personne (There\'s nobody left)',
          icon: Icons.warning,
          color: Color(0xFFF59E0B),
        ),
        const SectionTitle('❌ Common Mistakes'),
        const TranslatedText(
          '❌ Je ne jamais mange → ✅ Je ne mange jamais\n'
          '❌ Je rien comprends → ✅ Je ne comprends rien\n\n'
          'Don\'t forget the NE!',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
      ],
    );
  }
}
