import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class FuturProchePage extends StatelessWidget {
  const FuturProchePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return LessonTemplate(
      title: lp.currentLanguage == AppLanguage.french
          ? 'Futur Proche'
          : 'Near Future',
      icon: '🔜',
      topic: 'Futur Proche',
      children: [
        const TranslatedText(
          'Futur Proche = "going to" in English. It\'s the EASIEST future tense because it\'s for things happening SOON or that you\'ve already decided to do!',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('🎯 When to Use It'),
        const TranslatedText(
          '• Immediate future (happening very soon)\n'
          '• Plans you\'ve already decided\n'
          '• Obvious consequences',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('🔧 Super Easy Formula!'),
        TipBox(
          title: 'The Easiest Tense!',
          content: 'ALLER (present) + INFINITIVE\n\n'
              'That\'s it! Just conjugate "aller" and add any verb in infinitive form!',
          icon: Icons.calculate,
          color: AppTheme.success,
        ),
        // ALLER conjugation — must stay in French
        FrenchTipBox(
          title: 'Conjugation of ALLER (to go)',
          frenchText: 'je          vais\n'
              'tu          vas\n'
              'il / elle   va\n'
              'nous        allons\n'
              'vous        allez\n'
              'ils / elles vont',
          icon: Icons.directions_run,
          color: AppTheme.primary,
        ),
        const SectionTitle('✨ Examples'),
        const ExampleBox(
          french: 'Je vais manger une pizza',
          english: 'I\'m going to eat a pizza',
        ),
        const ExampleBox(
          french: 'Tu vas regarder le film ?',
          english: 'Are you going to watch the movie?',
        ),
        const ExampleBox(
          french: 'Nous allons partir demain',
          english: 'We\'re going to leave tomorrow',
        ),
        const ExampleBox(
          french: 'Attention ! Tu vas tomber !',
          english: 'Watch out! You\'re going to fall! (obvious consequence)',
        ),
        TipBox(
          title: '💡 Pro Tip',
          content:
              'Futur Proche is MORE COMMON in spoken French than Futur Simple. Use it when talking about your plans!',
          icon: Icons.lightbulb,
          color: AppTheme.warning,
        ),
        const SectionTitle('❌ Common Mistakes'),
        FrenchTipBox(
          title: 'Don\'t use aller + aller!',
          frenchText: '❌  Je vais aller au cinéma.  (weird!)\n'
              '✅  Je vais au cinéma.         (just use present of aller)\n\n'
              '"Aller + aller" sounds silly — avoid it!',
          icon: Icons.error_outline,
          color: AppTheme.error,
        ),
      ],
    );
  }
}
