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
          'Most French adverbs are formed by adding "-ment" to the feminine form of an adjective. This is equivalent to "-ly" in English.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('🔧 Basic Rule'),
        const TipBox(
          title: 'Formation',
          content:
              'Feminine Adjective + -ment\n\nExample: lent (slow) → lente (fem) → lentement (slowly)',
          icon: Icons.build,
          color: Color(0xFF10B981),
        ),
        const SectionTitle('📐 Special Rules'),
        const TranslatedText(
          '1. If the masculine adjective ends in a vowel: Add "-ment" directly.\n'
          '   • Vrai → Vraiment\n'
          '   • Poli → Poliment\n\n'
          '2. If the adjective ends in -ent or -ant: Replace with -emment or -amment.\n'
          '   • Patient → Patiemment\n'
          '   • Courant → Couramment',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('✨ Examples'),
        const ExampleBox(
          french: 'Il parle doucement.',
          english: 'He speaks softly.',
        ),
        const ExampleBox(
          french: 'Elle travaille sérieusement.',
          english: 'She works seriously.',
        ),
        const ExampleBox(
          french: 'Nous mangeons rapidement.',
          english: 'We eat quickly.',
        ),
        const SectionTitle('⚠️ Some Exceptions'),
        const TranslatedText(
          '• Bon → Bien (Well)\n'
          '• Mauvais → Mal (Badly)\n'
          '• Gentil → Gentiment (Kindly)',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const TipBox(
          title: '💡 Pro Tip',
          content:
              'The pronunciation of -emment and -amment is the same: [am-mã]. "Patiemment" sounds like it has an "a"!',
          icon: Icons.lightbulb,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}
