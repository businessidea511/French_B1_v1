import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class ConditionnelPage extends StatelessWidget {
  const ConditionnelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return LessonTemplate(
      title: lp.currentLanguage == AppLanguage.french
          ? 'Conditionnel'
          : 'Conditional Tense',
      icon: '🤔',
      children: [
        const TranslatedText(
          'The Conditionnel is your "WISHING AND WONDERING" tense. Use it for would/could/should - basically anything that\'s HYPOTHETICAL or POLITE!',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('🎯 Three Main Uses'),
        const TranslatedText(
          '1. **Polite Requests** - More polite than present tense\n'
          '2. **Wishes and Dreams** - Things you "would" do\n'
          '3. **Hypothetical Situations** - "If I won the lottery, I would..."',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('🔧 How to Build It'),
        const TranslatedText(
          'Super Formula!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TranslatedText(
          'Take the FUTURE SIMPLE stem and add:\n'
          '-ais, -ais, -ait, -ions, -iez, -aient',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('📝 Regular Verbs'),
        const TranslatedText(
          'PARLER → je parlerais (I would speak)\n'
          'FINIR → tu finirais (you would finish)\n'
          'VENDRE → il vendrait (he would sell)',
          style: TextStyle(fontSize: 15, height: 1.8, fontFamily: 'monospace'),
        ),
        const SectionTitle('🎯 Examples - Polite Requests'),
        const ExampleBox(
          french: 'Je voudrais un café',
          english: 'I would like a coffee (polite)',
        ),
        const ExampleBox(
          french: 'Pourriez-vous m\'aider?',
          english: 'Could you help me? (very polite)',
        ),
        const SectionTitle('💭 Examples - Wishes'),
        const ExampleBox(
          french: 'J\'aimerais visiter Tokyo',
          english: 'I would love to visit Tokyo',
        ),
        const ExampleBox(
          french: 'Nous voudrions une grande maison',
          english: 'We would like a big house',
        ),
        const SectionTitle('❓ Examples - Hypothetical'),
        const ExampleBox(
          french: 'Si j\'étais riche, je voyagerais beaucoup',
          english: 'If I were rich, I would travel a lot',
        ),
        const TipBox(
          title: '⚠️ Common Irregular Stems',
          content: 'être → ser- (je serais)\n'
              'avoir → aur- (j\'aurais)\n'
              'aller → ir- (j\'irais)\n'
              'faire → fer- (je ferais)\n'
              'vouloir → voudr- (je voudrais)\n'
              'pouvoir → pourr- (je pourrais)',
          icon: Icons.warning,
          color: Color(0xFFEF4444),
        ),
      ],
    );
  }
}
