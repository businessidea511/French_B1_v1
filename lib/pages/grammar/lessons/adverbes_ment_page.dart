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
        const TranslatedText(
          '1️⃣ Standard Rule: Fem. Adjective + -ment\n'
          '• Heureux → Heureuse → Heureusement\n'
          '• Frais → Fraîche → Fraîchement\n\n'
          '2️⃣ If Adjective ends in a Vowel: Just add -ment directly (skip the feminine step!)\n'
          '• Poli → Poliment\n'
          '• Vrai → Vraiment\n\n'
          '3️⃣ The "-NT" Trap (Important!): \n'
          '• Ends in -ENT? Change to -EMMENT (Prudent → Prudemment)\n'
          '• Ends in -ANT? Change to -AMMENT (Courant → Couramment)',
          style: TextStyle(fontSize: 15, height: 1.8),
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
        const TranslatedText(
          'Some adverbs just hate rules:\n'
          '• Bon (Good) → BIEN (Well)\n'
          '• Mauvais (Bad) → MAL (Badly)\n'
          '• Petit (Small) → PEU (Little)\n'
          '• Gentil (Kind) → GENTIMENT (Kindly)',
          style: TextStyle(fontSize: 15, height: 1.8),
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
