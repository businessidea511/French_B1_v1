import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class AdverbesMentPage extends StatelessWidget {
  const AdverbesMentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return LessonTemplate(
      title: lp.currentLanguage == AppLanguage.french
          ? 'Les Adverbes en -ment'
          : 'Adverbs in -ment',
      icon: '🏃',
      children: [
        const TranslatedText(
          'Adverbs are like "Action Spices" 🌶️. They tell us HOW someone does something (Slowly, happily, nicely). In French, most end in -MENT, just like English ends in -LY.',
          style:
              TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.bold),
        ),
        const SectionTitle('🧙‍♂️ The Magic "Ment" Formula'),
        const TipBox(
          title: 'Girl Power! 🚺',
          content:
              'The secret is simple: Use the FEMININE form of the adjective + MENT.\n\n'
              'Example: Lent (slow) → Lente (fem) → Lentement (slowly)',
          icon: Icons.auto_awesome,
          color: Color(0xFF10B981),
        ),
        const SectionTitle('📐 The 3 Rules for Adverb Success'),
        // Rules include French words — use FrenchTipBox for the examples
        const FrenchTipBox(
          title: '3 Rules — French Examples',
          frenchText: '1️⃣  Standard: Féminin + -ment\n'
              '   Heureux  →  Heureuse  →  Heureusement\n'
              '   Frais    →  Fraîche   →  Fraîchement\n\n'
              '2️⃣  Adjective ends in a vowel → just add -ment\n'
              '   Poli  →  Poliment\n'
              '   Vrai  →  Vraiment\n\n'
              '3️⃣  Ends in -ENT  →  -EMMENT\n'
              '   Prudent  →  Prudemment\n\n'
              '   Ends in -ANT  →  -AMMENT\n'
              '   Courant  →  Couramment',
          icon: Icons.rule,
          color: Color(0xFF6366F1),
        ),
        const SectionTitle('✨ Real-Life Examples'),
        const ExampleBox(
          french: 'Il conduit prudemment.',
          english: 'He drives prudently.',
        ),
        const ExampleBox(
          french: 'Elle chante admirablement.',
          english: 'She sings admirably.',
        ),
        const ExampleBox(
          french: 'Nous vivons tranquillement.',
          english: 'We live quietly.',
        ),
        const SectionTitle('🚫 The "Rebel" Adverbs (Irregulars)'),
        // Irregular adverbs — French words must stay in French
        const FrenchTipBox(
          title: 'Some adverbs just hate rules!',
          frenchText: 'Bon      (Good)   →  bien       (well)\n'
              'Mauvais  (Bad)    →  mal        (badly)\n'
              'Petit    (Small)  →  peu        (little)\n'
              'Gentil   (Kind)   →  gentiment  (kindly)',
          icon: Icons.warning,
          color: Color(0xFFEF4444),
        ),
        const TipBox(
          title: '👂 Dummy Ear Tip',
          content:
              'Both -emment and -amment sound EQUALLY like "ah-mah" [am-mã]. Don\'t let the spelling scare your ears!',
          icon: Icons.hearing,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}
