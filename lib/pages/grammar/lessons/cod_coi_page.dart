import 'package:flutter/material.dart';
import '../../../widgets/lesson_template.dart';

class CodCoiPage extends StatelessWidget {
  const CodCoiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LessonTemplate(
      title: 'COD / COI',
      icon: '🎯',
      children: [
        const Text(
          'COD and COI are OBJECT PRONOUNS that replace nouns to avoid repetition. Think of them as shortcuts!',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('🎯 What Are They?'),
        const Text(
          '**COD (Complément d\'Objet Direct)** = Direct Object\n'
          '→ WHAT or WHO directly receives the action\n'
          '→ No preposition needed\n\n'
          '**COI (Complément d\'Objet Indirect)** = Indirect Object\n'
          '→ TO WHOM the action is done\n'
          '→ Uses preposition "à"',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('📋 The Pronouns'),
        const SectionTitle('COD (Direct Object)'),
        const Text(
          'me/m\' = me\n'
          'te/t\' = you\n'
          'le/l\' = him/it (masculine)\n'
          'la/l\' = her/it (feminine)\n'
          'nous = us\n'
          'vous = you (plural/formal)\n'
          'les = them',
          style: TextStyle(fontSize: 15, height: 1.8, fontFamily: 'monospace'),
        ),
        const SectionTitle('COI (Indirect Object)'),
        const Text(
          'me/m\' = to me\n'
          'te/t\' = to you\n'
          'lui = to him/her\n'
          'nous = to us\n'
          'vous = to you (plural/formal)\n'
          'leur = to them',
          style: TextStyle(fontSize: 15, height: 1.8, fontFamily: 'monospace'),
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
        const TipBox(
          title: '🔍 How to Identify COD vs COI',
          content: 'Ask questions:\n'
              '• COD: WHAT? or WHO? (no preposition)\n'
              '  "Je vois QUOI? → la voiture"\n\n'
              '• COI: TO WHOM? (à + person)\n'
              '  "Je parle à QUI? → à Marie"',
          icon: Icons.help_outline,
          color: Color(0xFF6366F1),
        ),
        const SectionTitle('📍Position'),
        const TipBox(
          title: 'Where to Put Them',
          content: '**Present/Future:** BEFORE the verb\n'
              '  Je le vois (I see him)\n\n'
              '**Passé Composé:** BEFORE the auxiliary\n'
              '  Je l\'ai vu (I saw him)\n\n'
              '**With infinitive:** BEFORE the infinitive\n'
              '  Je vais le voir (I\'m going to see him)',
          icon: Icons.place,
          color: Color(0xFFF59E0B),
        ),
        const SectionTitle('⚠️ Tricky Verbs with À'),
        const Text(
          'These verbs use COI (even though  they might not in English):\n\n'
          '• parler à (talk to) → Je lui parle\n'
          '• téléphoner à (call) → Je lui téléphone\n'
          '• répondre à (answer) → Je lui réponds\n'
          '• demander à (ask) → Je lui demande',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const TipBox(
          title: '⚠️ Agreement Alert!',
          content:
              'In Passé Composé, the past participle agrees with COD (not COI) when it comes BEFORE:\n\n'
              'La pomme? Je l\'ai mangée. (agrees)\n'
              'Marie? Je lui ai parlé. (no agreement - COI)',
          icon: Icons.warning,
          color: Color(0xFFEF4444),
        ),
      ],
    );
  }
}
