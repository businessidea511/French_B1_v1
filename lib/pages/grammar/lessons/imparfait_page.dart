import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class ImparfaitPage extends StatelessWidget {
  const ImparfaitPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return LessonTemplate(
      title: lp.currentLanguage == AppLanguage.french
          ? 'Imparfait'
          : 'Imperfect Tense',
      icon: '🎬',
      children: [
        const TranslatedText(
          'Think of Imparfait as the "BACKGROUND MUSIC" of your past. While Passé Composé is specific actions, Imparfait sets the SCENE and describes what was ONGOING.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('🎥 The Movie Metaphor', emoji: null),
        const TranslatedText(
          'If Passé Composé is the main ACTION, Imparfait is the SCENERY:\n\n'
          '• The weather in the background\n'
          '• What characters were wearing\n'
          '• What was happening while the action occurred\n'
          '• Repeated habits ("used to" do something)',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('⚖️ Passé Composé vs Imparfait'),
        const ExampleBox(
          french: 'Il pleuvait quand je suis sorti',
          english: 'It WAS RAINING (background) when I left (specific action)',
        ),
        const TranslatedText(
          '→ "pleuvait" = setting the scene (Imparfait)\n'
          '→ "suis sorti" = what happened (Passé Composé)',
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
        const SectionTitle('🔧 How to Build It'),
        const TipBox(
          title: 'Super Easy Formula!',
          content: 'Take the NOUS form, remove -ONS, add Imparfait endings:\n'
              '-ais, -ais, -ait, -ions, -iez, -aient',
          icon: Icons.calculate,
          color: Color(0xFF6366F1),
        ),
        // Full conjugation example — must stay in French
        const FrenchTipBox(
          title: 'Step-by-Step Example: PARLER',
          frenchText: '1. Nous parlons (present)\n'
              '2. Remove -ons  →  parl-\n'
              '3. Add endings:\n\n'
              '   je         parlais\n'
              '   tu         parlais\n'
              '   il / elle  parlait\n'
              '   nous       parlions\n'
              '   vous       parliez\n'
              '   ils/elles  parlaient',
          icon: Icons.auto_fix_high,
          color: Color(0xFF10B981),
        ),
        const SectionTitle('📝 More Examples'),
        const ExampleBox(
          french: 'Quand j\'étais petit, je jouais au foot',
          english: 'When I was little, I used to play soccer',
        ),
        const ExampleBox(
          french: 'Il faisait beau hier',
          english: 'The weather was nice yesterday',
        ),
        const ExampleBox(
          french: 'Nous habitions à Paris en 2020',
          english: 'We were living / used to live in Paris in 2020',
        ),
        const SectionTitle('🎯 When to Use Imparfait'),
        const TranslatedText(
          '1. Descriptions (age, weather, feelings, appearance)\n'
          '2. Habits / Repeated Actions ("used to" or "would")\n'
          '3. Ongoing Actions (what "was happening")\n'
          '4. Time / Age',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const ExampleBox(
          french: 'Il faisait froid.',
          english: 'It was cold.  (description)',
        ),
        const ExampleBox(
          french: 'Je mangeais toujours des céréales.',
          english: 'I used to always eat cereal.  (habit)',
        ),
        const ExampleBox(
          french: 'Je dormais quand tu as appelé.',
          english: 'I was sleeping when you called.  (ongoing)',
        ),
        const TipBox(
          title: '💡 Magic Word: "USED TO"',
          content:
              'If you can say "used to" or "was/were doing" in English, use Imparfait!',
          icon: Icons.lightbulb,
          color: Color(0xFFF59E0B),
        ),
        // ÊTRE irregular — must stay in French
        const FrenchTipBox(
          title: '⚠️ ÊTRE is the ONLY Irregular Stem!',
          frenchText: 'être  →  ét-\n\n'
              'j\'étais\n'
              'tu étais\n'
              'il / elle était\n'
              'nous étions\n'
              'vous étiez\n'
              'ils / elles étaient',
          icon: Icons.warning,
          color: Color(0xFFEF4444),
        ),
        const SectionTitle('❌ Common Mistakes'),
        const FrenchTipBox(
          title: 'Don\'t Mix Them Up!',
          frenchText: '❌ Hier, il pleuvait et je sortais.\n'
              '✅ Hier, il pleuvait et je suis sorti.\n\n'
              'La pluie = background (Imparfait)\n'
              'Sortir = specific action (Passé Composé)',
          icon: Icons.error_outline,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}
