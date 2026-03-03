import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class PlusQueParfaitPage extends StatelessWidget {
  const PlusQueParfaitPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return LessonTemplate(
      title: lp.currentLanguage == AppLanguage.french
          ? 'Plus-que-parfait'
          : 'Past Perfect Tense',
      icon: '⏪',
      children: [
        const TranslatedText(
          'Think of Plus-que-parfait as the "FLASHBACK" tense. It\'s for actions that happened BEFORE other past actions. It\'s like going even FURTHER back in time!',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('⏰ The Timeline', emoji: null),
        const TranslatedText(
          'Past Perfect ⏪ → Passé Composé → Present\n\n'
          'When you\'re telling a story in the past and need to mention something that happened BEFORE that past moment, use Plus-que-parfait!',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const ExampleBox(
          french: 'Il a mangé le gâteau que j\'avais fait',
          english:
              'He ate the cake that I HAD MADE (made it first, then he ate it)',
        ),
        const SectionTitle('🔧 How to Build It'),
        const TipBox(
          title: 'Easy Formula!',
          content: 'AVOIR or ÊTRE (in Imparfait) + PAST PARTICIPLE\n\n'
              'It\'s just like Passé Composé, but with the helper verb in Imparfait!',
          icon: Icons.calculate,
          color: Color(0xFF6366F1),
        ),
        // Helper verb conjugation — must stay in French
        const FrenchTipBox(
          title: 'AVOIR in Imparfait (used with most verbs)',
          frenchText: 'j\'avais\n'
              'tu avais\n'
              'il / elle avait\n'
              'nous avions\n'
              'vous aviez\n'
              'ils / elles avaient',
          icon: Icons.history,
          color: Color(0xFF10B981),
        ),
        const FrenchTipBox(
          title: 'ÊTRE in Imparfait (movement & reflexive verbs)',
          frenchText: 'j\'étais\n'
              'tu étais\n'
              'il / elle était\n'
              'nous étions\n'
              'vous étiez\n'
              'ils / elles étaient',
          icon: Icons.directions_walk,
          color: Color(0xFF0EA5E9),
        ),
        const SectionTitle('📝 Examples'),
        const ExampleBox(
          french: 'J\'avais déjà mangé quand tu es arrivé',
          english: 'I had already eaten when you arrived',
        ),
        const ExampleBox(
          french: 'Elle était partie avant midi',
          english: 'She had left before noon',
        ),
        const ExampleBox(
          french: 'Nous avions fini nos devoirs',
          english: 'We had finished our homework',
        ),
        const TipBox(
          title: '💡 Key Signal Words',
          content:
              'Look for: déjà (already), avant (before), quand (when) — these often signal Plus-que-parfait!',
          icon: Icons.lightbulb,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}
