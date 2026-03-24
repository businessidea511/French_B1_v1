import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class ComparatifPage extends StatelessWidget {
  const ComparatifPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return LessonTemplate(
      title: lp.currentLanguage == AppLanguage.french
          ? 'Le Comparatif'
          : 'Comparatives',
      icon: '⚖️',
      children: [
        const TranslatedText(
          'The Comparatif lets you COMPARE things — bigger, smaller, faster, cheaper! '
          'Think of it as your "versus" tool in French. It\'s simpler than you think!',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('🎯 Three Types of Comparison'),
        const TranslatedText(
          '1. ➕ Superiority — MORE than (bigger, better, faster)\n'
          '2. ➖ Inferiority — LESS than (smaller, cheaper, slower)\n'
          '3. ➡️ Equality — AS ... AS (the same size, same price)',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('🔧 The Magic Formulas'),
        const FrenchTipBox(
          title: 'Comparatif — Core Formulas',
          frenchText: 'plus  + adjective + que   →  more ... than\n'
              'moins + adjective + que   →  less ... than\n'
              'aussi + adjective + que   →  as ... as',
          icon: Icons.calculate,
          color: Color(0xFF6366F1),
        ),
        const SectionTitle('✨ Superiority — plus ... que (more than)'),
        const ExampleBox(
          french: 'Paris est plus grande que Lyon.',
          english: 'Paris is bigger than Lyon.',
        ),
        const ExampleBox(
          french: 'Ce film est plus intéressant que l\'autre.',
          english: 'This film is more interesting than the other one.',
        ),
        const ExampleBox(
          french: 'Il travaille plus vite que moi.',
          english: 'He works faster than me.',
        ),
        const SectionTitle('✨ Inferiority — moins ... que (less than)'),
        const ExampleBox(
          french: 'Ce restaurant est moins cher que l\'autre.',
          english:
              'This restaurant is cheaper (less expensive) than the other.',
        ),
        const ExampleBox(
          french: 'Elle est moins fatiguée que lui.',
          english: 'She is less tired than him.',
        ),
        const ExampleBox(
          french: 'Ce trajet est moins long que prévu.',
          english: 'This journey is shorter (less long) than expected.',
        ),
        const SectionTitle('✨ Equality — aussi ... que (as ... as)'),
        const ExampleBox(
          french: 'Mon café est aussi bon que le tien.',
          english: 'My coffee is as good as yours.',
        ),
        const ExampleBox(
          french: 'Elle chante aussi bien que lui.',
          english: 'She sings as well as him.',
        ),
        const ExampleBox(
          french: 'Ce sac est aussi lourd que celui-là.',
          english: 'This bag is as heavy as that one.',
        ),
        const SectionTitle('📊 Comparing Quantities (Nouns)'),
        const TranslatedText(
          'When comparing AMOUNTS (not qualities), replace "aussi" with "autant":',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
        const FrenchTipBox(
          title: 'Comparing quantities',
          frenchText: 'plus de  + noun + que   →  more ... than\n'
              'moins de + noun + que   →  less/fewer ... than\n'
              'autant de+ noun + que   →  as much/many ... as',
          icon: Icons.bar_chart,
          color: Color(0xFF10B981),
        ),
        const ExampleBox(
          french: 'J\'ai plus de temps que toi.',
          english: 'I have more time than you.',
        ),
        const ExampleBox(
          french: 'Il mange moins de sucre que sa sœur.',
          english: 'He eats less sugar than his sister.',
        ),
        const ExampleBox(
          french: 'Nous avons autant d\'argent qu\'eux.',
          english: 'We have as much money as them.',
        ),
        const SectionTitle('⚠️ Irregular Comparatives — The Exceptions!'),
        const TranslatedText(
          'Just like in English ("good → better", NOT "more good"), French has a few irregular forms you must memorize:',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
        const FrenchTipBox(
          title: '⚠️ Irregular Forms',
          frenchText:
              'bon  (good)   →  meilleur(e)  (better)   ❌ NOT plus bon\n'
              'mauvais (bad) →  pire         (worse)     ❌ NOT plus mauvais\n'
              'bien (well)   →  mieux        (better)    ❌ NOT plus bien\n'
              'mal  (badly)  →  pis / pire   (worse)     ❌ NOT plus mal',
          icon: Icons.warning,
          color: Color(0xFFEF4444),
        ),
        const ExampleBox(
          french: 'Ce vin est meilleur que l\'autre.',
          english: 'This wine is better than the other one.',
        ),
        const ExampleBox(
          french: 'Il chante mieux que moi.',
          english: 'He sings better than me.',
        ),
        const ExampleBox(
          french: 'La situation est pire qu\'avant.',
          english: 'The situation is worse than before.',
        ),
        const TipBox(
          title: '💡 Quick Tip — "que" becomes "qu\'" before a vowel!',
          content: 'plus intelligent QUE lui  (before consonant)\n'
              'plus intelligent QU\'elle  (before vowel — drop the e!)',
          icon: Icons.lightbulb_outline,
          color: Color(0xFFF59E0B),
        ),
        const SectionTitle('📝 Adjective Agreement'),
        const TranslatedText(
          'Remember: comparative adjectives still agree in GENDER and NUMBER with the noun they describe!',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
        const FrenchTipBox(
          title: 'Agreement examples',
          frenchText: 'un sac plus lourd    (masculine singular)\n'
              'une valise plus lourde   (feminine singular)\n'
              'des sacs plus lourds     (masculine plural)\n'
              'des valises plus lourdes (feminine plural)\n\n'
              '❌ un sac plus lourd / ✅ une valise plus lourde',
          icon: Icons.spellcheck,
          color: Color(0xFF6366F1),
        ),
      ],
    );
  }
}
