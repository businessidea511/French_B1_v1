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
          content:
              'Take the NOUS form, remove -ONS, add Imparfait endings:\n-ais, -ais, -ait, -ions, -iez, -aient',
          icon: Icons.calculate,
          color: Color(0xFF6366F1),
        ),
        const SectionTitle('Step-by-Step Example: PARLER'),
        const TranslatedText(
          '1. Nous parlons (present)\n'
          '2. Remove -ons → parl-\n'
          '3. Add endings:\n\n'
          '   je parlais\n'
          '   tu parlais\n'
          '   il/elle parlait\n'
          '   nous parlions\n'
          '   vous parliez\n'
          '   ils/elles parlaient',
          style: TextStyle(fontSize: 15, height: 1.8, fontFamily: 'monospace'),
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
          '1. **Descriptions** (age, weather, feelings, appearance)\n'
          '   • Il faisait froid (It was cold)\n'
          '   • Elle était contente (She was happy)\n\n'
          '2. **Habits / Repeated Actions** ("used to" or "would")\n'
          '   • Je mangeais toujours  des céréales (I used to always eat cereal)\n\n'
          '3. **Ongoing Actions** (what "was happening")\n'
          '   • Je dormais quand tu as appelé (I was sleeping when you called)\n\n'
          '4. **Time / Age**\n'
          '   • Il était 10h (It was 10 o\'clock)\n'
          '   • J\'avais 15 ans (I was 15 years old)',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const TipBox(
          title: '💡 Magic Word: "USED TO"',
          content:
              'If you can say "used to" or "was/were doing" in English, use Imparfait!',
          icon: Icons.lightbulb,
          color: Color(0xFFF59E0B),
        ),
        const SectionTitle('⚠️ Only ONE Irregular Stem'),
        const TipBox(
          title: 'ÊTRE is the ONLY exception!',
          content:
              'être → ét-\n\nj\'étais, tu étais, il était, nous étions, vous étiez, ils étaient',
          icon: Icons.warning,
          color: Color(0xFFEF4444),
        ),
        const SectionTitle('❌ Common Mistakes'),
        const TipBox(
          title: 'Don\'t Mix Them Up!',
          content:
              '❌ Hier, il pleuvait et je sortais\n✅ Hier, il pleuvait et je suis sorti\n\nThe rain = background (Imparfait)\nLeaving = specific action ( Passé Composé)',
          icon: Icons.error_outline,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}
