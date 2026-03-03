import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class PresentPage extends StatelessWidget {
  const PresentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return LessonTemplate(
      title: lp.currentLanguage == AppLanguage.french
          ? 'Le Présent'
          : 'Present Tense',
      icon: '⌚',
      children: [
        const TranslatedText(
          'Think of Le Présent as the "Live Stream" tense. It\'s for what\'s happening RIGHT NOW or things that are always true, like habits or scientific facts 📺',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('🎬 The "Live Stream" Metaphor', emoji: null),
        const TranslatedText(
          'If you were filming a TikTok or a Live Stream, you would use Le Présent to describe the action as it happens:',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const ExampleBox(
          french: 'Je regarde un film maintenant',
          english: 'I am watching a movie now (Right now!)',
        ),
        const ExampleBox(
          french: 'Le soleil brille tous les jours',
          english: 'The sun shines every day (Always true)',
        ),
        const SectionTitle('🔧 How to Build It'),
        const TranslatedText(
          'French verbs belong to 3 main groups. Each has its own "ending" formula:',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const SectionTitle('Group 1: -ER Verbs (Easy Mode 🟢)'),
        const TranslatedText(
          'Remove -ER and add: -e, -es, -e, -ons, -ez, -ent',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const ExampleBox(
          french:
              'Je parle, Tu parles, Il parle\nNous parlons, Vous parlez, Ils parlent',
          english: 'Parler (To speak)',
        ),
        const SectionTitle('Group 2: -IR Verbs (Steady Mode 🟡)'),
        const TranslatedText(
          'Remove -IR and add: -is, -is, -it, -issons, -issez, -issent',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const ExampleBox(
          french:
              'Je finis, Tu finis, Il finit\nNous finissons, Vous finissez, Ils finissent',
          english: 'Finir (To finish)',
        ),
        const SectionTitle('Group 3: -RE Verbs (Boss Mode 🔴)'),
        const TranslatedText(
          'Remove -RE and add: -s, -s, -(nothing), -ons, -ez, -ent',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const ExampleBox(
          french:
              'Je vends, Tu vends, Il vend\nNous vendons, Vous vendez, Ils vendent',
          english: 'Vendre (To sell)',
        ),
        const SectionTitle('🎯 The "Fantastic Four" Irregulars'),
        const TranslatedText(
          'These 4 are the most used verbs in French. You MUST memorize them!',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const FrenchTipBox(
          title: 'Être (To be)',
          frenchText: 'je suis\n'
              'tu es\n'
              'il / elle est\n'
              'nous sommes\n'
              'vous êtes\n'
              'ils / elles sont',
          icon: Icons.person,
          color: Color(0xFF6366F1),
        ),
        const FrenchTipBox(
          title: 'Avoir (To have)',
          frenchText: 'j\'ai\n'
              'tu as\n'
              'il / elle a\n'
              'nous avons\n'
              'vous avez\n'
              'ils / elles ont',
          icon: Icons.inventory_2,
          color: Color(0xFFEC4899),
        ),
        const FrenchTipBox(
          title: 'Aller (To go)',
          frenchText: 'je vais\n'
              'tu vas\n'
              'il / elle va\n'
              'nous allons\n'
              'vous allez\n'
              'ils / elles vont',
          icon: Icons.directions_run,
          color: Color(0xFF10B981),
        ),
        const FrenchTipBox(
          title: 'Faire (To do / make)',
          frenchText: 'je fais\n'
              'tu fais\n'
              'il / elle fait\n'
              'nous faisons\n'
              'vous faites\n'
              'ils / elles font',
          icon: Icons.build,
          color: Color(0xFFF59E0B),
        ),
        const SectionTitle('❌ Common Mistakes'),
        const TipBox(
          title: 'Pronunciation Trap!',
          content: 'The "-ent" ending for "Ils/Elles" is SILENT! 🤫\n'
              '❌ Ils parl-ENT ➜ ✅ Ils parl (sounds like "parle")',
          icon: Icons.volume_off,
          color: Color(0xFFEF4444),
        ),
      ],
    );
  }
}
