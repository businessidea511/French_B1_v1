import 'package:flutter/material.dart';
import '../../../widgets/lesson_template.dart';

class FuturSimplePage extends StatelessWidget {
  const FuturSimplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LessonTemplate(
      title: 'Futur Simple',
      icon: '🔮',
      children: [
        const Text(
          'Futur Simple = "will" in English. It\'s for predictions, promises, and things you\'ll do in the more distant future (not immediate like Futur Proche).',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('⚖️ Futur Proche vs Futur Simple'),
        const Text(
          '🔜 Futur Proche: "I\'m going to eat" (soon, decided)\n'
          '🔮 Futur Simple: "I will eat" (general future, promise, prediction)',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('🔧 How to Build It'),
        const TipBox(
          title: 'Two Ways to Build',
          content: '**Regular verbs (-ER/-IR):** INFINITIVE + endings\n'
              '**Regular -RE verbs:** Remove E, then add endings\n\n'
              'Endings: -ai, -as, -a, -ons, -ez, -ont',
          icon: Icons.calculate,
          color: Color(0xFF6366F1),
        ),
        const SectionTitle('📝 Regular Examples'),
        const Text(
          'PARLER → je parlerai (I will speak)\n'
          'FINIR → tu finiras (you will finish)\n'
          'VENDRE → il vendra (he will sell)',
          style: TextStyle(fontSize: 15, height: 1.8, fontFamily: 'monospace'),
        ),
        const SectionTitle('✨ Usage Examples'),
        const ExampleBox(
          french: 'Je te téléphonerai demain',
          english: 'I will call you tomorrow (promise)',
        ),
        const ExampleBox(
          french: 'Il fera beau ce weekend',
          english: 'It will be nice this weekend (prediction)',
        ),
        const ExampleBox(
          french: 'Vous finirez à quelle heure?',
          english: 'What time will you finish?',
        ),
        const SectionTitle('⚠️ Common Irregular Stems'),
        const TipBox(
          title: 'Memorize These!',
          content: 'être → ser- (je serai)\n'
              'avoir → aur- (j\'aurai)\n'
              'aller → ir- (j\'irai)\n'
              'faire → fer- (je ferai)\n'
              'voir → verr- (je verrai)\n'
              'vouloir → voudr- (je voudrai)\n'
              'pouvoir → pourr- (je pourrai)\n'
              'venir → viendr- (je viendrai)',
          icon: Icons.warning,
          color: Color(0xFFEF4444),
        ),
        const TipBox(
          title: '💡 Easy Trick',
          content:
              'These irregular stems are THE SAME as Conditionnel! Learn them once, use them twice!',
          icon: Icons.lightbulb,
          color: Color(0xFF10B981),
        ),
        const SectionTitle('🎯 Signal Words'),
        const Text(
          'Look for:\n'
          '• demain (tomorrow)\n'
          '• la semaine prochaine (next week)\n'
          '• dans 2 jours (in 2 days)\n'
          '• quand + future (when + future = both future!)',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const ExampleBox(
          french: 'Quand tu viendras, je serai là',
          english: 'When you come (will come), I will be there',
        ),
      ],
    );
  }
}
