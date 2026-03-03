import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class SiSeulementPage extends StatelessWidget {
  const SiSeulementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return LessonTemplate(
      title:
          lp.currentLanguage == AppLanguage.french ? 'Si seulement' : 'If only',
      icon: '💭',
      children: [
        const TranslatedText(
          '"Si seulement" means "If only" - it\'s for expressing REGRETS and WISHES about things that aren\'t true or didn\'t happen. Very dramatic! 🎭',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('💔 Two Types of Regrets'),
        const TranslatedText(
          '1. Present / Future regrets — wish things were different NOW\n'
          '2. Past regrets — wish things had been different THEN',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('🔧 Structure 1: Present / Future Wishes'),
        const FrenchTipBox(
          title: 'Formula: Si seulement + Imparfait',
          frenchText: 'Si seulement + IMPARFAIT\n\n'
              'Use Imparfait to wish about the present or future!',
          icon: Icons.calculate,
          color: Color(0xFF6366F1),
        ),
        const ExampleBox(
          french: 'Si seulement j\'étais riche !',
          english: 'If only I were rich! (but I\'m not)',
        ),
        const ExampleBox(
          french: 'Si seulement il faisait beau',
          english: 'If only the weather were nice (but it\'s not)',
        ),
        const ExampleBox(
          french: 'Si seulement je pouvais voler !',
          english: 'If only I could fly! (but I can\'t)',
        ),
        const SectionTitle('🔧 Structure 2: Past Regrets'),
        const FrenchTipBox(
          title: 'Formula: Si seulement + Plus-que-parfait',
          frenchText: 'Si seulement + PLUS-QUE-PARFAIT\n\n'
              'Use Plus-que-parfait to regret things that happened (or didn\'t happen) in the past!',
          icon: Icons.calculate,
          color: Color(0xFF6366F1),
        ),
        const ExampleBox(
          french: 'Si seulement j\'avais étudié !',
          english: 'If only I had studied! (but I didn\'t)',
        ),
        const ExampleBox(
          french: 'Si seulement nous étions partis plus tôt',
          english: 'If only we had left earlier (but we didn\'t)',
        ),
        const ExampleBox(
          french: 'Si seulement elle avait dit la vérité',
          english: 'If only she had told the truth (but she didn\'t)',
        ),
        // Quick reference — French key sentences must stay French
        const FrenchTipBox(
          title: '💡 Quick Reference',
          frenchText: 'Wishing about NOW / FUTURE  →  Imparfait\n'
              '  Si seulement j\'ÉTAIS riche.\n\n'
              'Regretting the PAST  →  Plus-que-parfait\n'
              '  Si seulement j\'AVAIS ÉTÉ riche.',
          icon: Icons.lightbulb,
          color: Color(0xFF10B981),
        ),
        const SectionTitle('🎭 Common Expressions'),
        const ExampleBox(
          french: 'Si seulement je le savais !',
          english: 'If only I knew!',
        ),
        const ExampleBox(
          french: 'Si seulement c\'était vrai !',
          english: 'If only it were true!',
        ),
        const ExampleBox(
          french: 'Si seulement tu avais écouté !',
          english: 'If only you had listened!',
        ),
        const ExampleBox(
          french: 'Si seulement j\'avais su, je ne serais pas venu',
          english: 'If only I had known, I wouldn\'t have come',
        ),
        const TipBox(
          title: '⚠️ Don\'t Confuse Si!',
          content: '• "Si" in conditions = if (normal conditionals)\n'
              '• "Si seulement" = if only (regrets / wishes)\n\n'
              '"Si seulement" is MORE EMOTIONAL!',
          icon: Icons.warning,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}
