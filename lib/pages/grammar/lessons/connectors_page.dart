import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class ConnectorsPage extends StatelessWidget {
  const ConnectorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    
    return LessonTemplate(
      title: lp.currentLanguage == AppLanguage.french ? 'Les Connecteurs' : 'Logical Connectors',
      icon: '🔗',
      children: [
        const TranslatedText(
          'Logical connectors are the "glue" of language. They help you join two ideas together and show the relationship between them—like cause, result, or opposition.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        
        const SectionTitle('Reasons & Causes', emoji: '🧐'),
        const TranslatedText(
          'Use these words to explain WHY something happened.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const ExampleBox(
          french: 'Je mange parce que j\'ai faim',
          english: 'I am eating because I am hungry',
        ),
        const ExampleBox(
          french: 'Il reste à la maison car il pleut',
          english: 'He is staying home because it is raining',
        ),

        const SectionTitle('Results & Consequences', emoji: '🎯'),
        const TranslatedText(
          'Use these to show the result or the "So what?" of an action.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const ExampleBox(
          french: 'Je pense, donc je suis',
          english: 'I think, therefore I am',
        ),
        const ExampleBox(
          french: 'Il a plu, aussi la terre est humide',
          english: 'It rained, so/therefore the ground is wet',
        ),

        const SectionTitle('Buts & Oppositions', emoji: '⚖️'),
        const TranslatedText(
          'Use these when things don\'t go as expected or for contrasting ideas.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const ExampleBox(
          french: 'Je l\'aime, mais il est fou',
          english: 'I love him, but he is crazy',
        ),
        const ExampleBox(
          french: 'J\'aime le thé, par contre je déteste le café',
          english: 'I like tea; on the other hand, I hate coffee',
        ),
        const ExampleBox(
          french: 'Il fait froid, cependant il y a du soleil',
          english: 'It is cold; however, it is sunny',
        ),

        const SectionTitle('Despite the Odds', emoji: '☔'),
        const TranslatedText(
          'Use "Malgré" followed by a noun to say "Despite" or "In spite of".',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const ExampleBox(
          french: 'Il sort malgré la pluie',
          english: 'He goes out despite the rain',
        ),

        const SectionTitle('Purpose', emoji: '🏹'),
        const TranslatedText(
          'Use "Pour" followed by an infinitive verb to show intent.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const ExampleBox(
          french: 'Je travaille pour réussir',
          english: 'I work in order to succeed',
        ),

        const TipBox(
          title: 'Quick Hack 💡',
          content: '• Because? -> Parce que / Car\n• So? -> Donc / Aussi\n• But? -> Mais / Par contre\n• Although/However? -> Cependant\n• Despite? -> Malgré\n• To do something? -> Pour',
          icon: Icons.bolt,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}
