import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class CodCoiPage extends StatelessWidget {
  const CodCoiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return LessonTemplate(
      title: lp.currentLanguage == AppLanguage.french
          ? 'COD / COI'
          : 'Direct & Indirect Objects',
      icon: '🎯',
      topic: 'COD / COI',
      children: [
        const TranslatedText(
          'COD and COI are OBJECT PRONOUNS that replace nouns to avoid repetition. Think of them as shortcuts!',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('🎯 What Are They?'),
        const TranslatedText(
          'COD (Complément d\'Objet Direct) = Direct Object\n'
          '→ WHAT or WHO directly receives the action\n'
          '→ No preposition needed\n\n'
          'COI (Complément d\'Objet Indirect) = Indirect Object\n'
          '→ TO WHOM the action is done\n'
          '→ Uses preposition "à"',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        // COD pronouns — French grammar terms must stay in French
        const SectionTitle('📋 COD Pronouns (Direct Object)'),
        FrenchTipBox(
          title: 'COD — Direct Object Pronouns',
          frenchText: 'me / m\'  =  me\n'
              'te / t\'  =  you\n'
              'le / l\'  =  him / it (masculine)\n'
              'la / l\'  =  her / it (feminine)\n'
              'nous     =  us\n'
              'vous     =  you (plural / formal)\n'
              'les      =  them',
          icon: Icons.account_circle,
          color: AppTheme.primary,
        ),
        // COI pronouns
        const SectionTitle('📋 COI Pronouns (Indirect Object)'),
        FrenchTipBox(
          title: 'COI — Indirect Object Pronouns',
          frenchText: 'me / m\'  =  to me\n'
              'te / t\'  =  to you\n'
              'lui      =  to him / her\n'
              'nous     =  to us\n'
              'vous     =  to you (plural / formal)\n'
              'leur     =  to them',
          icon: Icons.account_circle_outlined,
          color: AppTheme.success,
        ),
        const SectionTitle('✨ COD Examples'),
        const ExampleBox(
          french: 'Je vois Marie → Je la vois',
          english: 'I see Marie → I see her',
        ),
        const ExampleBox(
          french: 'Il mange la pomme → Il la mange',
          english: 'He eats the apple → He eats it',
        ),
        const ExampleBox(
          french: 'Elle regarde les films → Elle les regarde',
          english: 'She watches movies → She watches them',
        ),
        const SectionTitle('💬 COI Examples'),
        const ExampleBox(
          french: 'Je parle à Marie → Je lui parle',
          english: 'I talk to Marie → I talk to her',
        ),
        const ExampleBox(
          french: 'Il téléphone à ses parents → Il leur téléphone',
          english: 'He calls his parents → He calls them',
        ),
        TipBox(
          title: '🔍 How to Identify COD vs COI',
          content: 'Ask questions:\n'
              '• COD: WHAT? or WHO? (no preposition)\n'
              '• COI: TO WHOM? (à + person)',
          icon: Icons.help_outline,
          color: AppTheme.primary,
        ),
        const SectionTitle('📍 Position — Where to Put Them'),
        FrenchTipBox(
          title: 'Pronoun placement rules',
          frenchText: 'Present / Future  →  BEFORE the verb\n'
              '  Je le vois.  (I see him)\n\n'
              'Passé Composé  →  BEFORE the auxiliary\n'
              '  Je l\'ai vu.  (I saw him)\n\n'
              'With infinitive  →  BEFORE the infinitive\n'
              '  Je vais le voir.  (I\'m going to see him)',
          icon: Icons.place,
          color: AppTheme.warning,
        ),
        const SectionTitle('⚠️ Tricky Verbs with À'),
        const TranslatedText(
          'These verbs use COI (even though they might not in English):',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
        const ExampleBox(
          french: 'parler à → Je lui parle',
          english: 'talk to → I talk to him/her',
        ),
        const ExampleBox(
          french: 'téléphoner à → Je lui téléphone',
          english: 'call → I call him/her',
        ),
        const ExampleBox(
          french: 'répondre à → Je lui réponds',
          english: 'answer → I answer him/her',
        ),
        FrenchTipBox(
          title: '⚠️ Agreement Alert! (Passé Composé)',
          frenchText: 'Participle agrees with COD when it comes BEFORE:\n\n'
              '✅ La pomme ? Je l\'ai mangée.   (agrees — COD)\n'
              '✅ Marie ?   Je lui ai parlé.    (no agreement — COI)',
          icon: Icons.warning,
          color: AppTheme.error,
        ),
      ],
    );
  }
}
