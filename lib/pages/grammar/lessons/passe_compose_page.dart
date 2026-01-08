import 'package:flutter/material.dart';
import '../../../widgets/lesson_template.dart';

class PasseComposePage extends StatelessWidget {
  const PasseComposePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LessonTemplate(
      title: 'Passé Composé',
      icon: '⏱️',
      children: [
        const Text(
          'Think of Passé Composé as the "I DID IT!" tense. It\'s for completed actions that happened in the past, like checking items off your to-do list ✅',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SectionTitle('🎬 The Movie Metaphor', emoji: null),
        const Text(
          'If your life were a movie, Passé Composé would be the SPECIFIC SCENES that happened:',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const ExampleBox(
          french: 'J\'ai mangé une pizza hier',
          english: 'I ate a pizza yesterday (one specific moment)',
        ),
        const ExampleBox(
          french: 'Elle a fini ses devoirs',
          english: 'She finished her homework (it\'s DONE!)',
        ),
        const SectionTitle('🔧 How to Build It'),
        const Text(
          'Super simple! Just 2 parts:',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const TipBox(
          title: 'Formula',
          content: 'AVOIR  or ÊTRE (present tense) + PAST PARTICIPLE',
          icon: Icons.calculate,
          color: Color(0xFF6366F1),
        ),
        const SectionTitle('Step 1: Choose Your Helper Verb'),
        const Text(
          '• Most verbs use AVOIR (to have)\n'
          '• Movement verbs & reflexive verbs use ÊTRE (to be)',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('Step 2: Make the Past Participle'),
        const Text(
          '• ER verbs → remove ER, add É (manger → mangé)\n'
          '• IR verbs → remove IR, add I (finir → fini)\n'
          '• RE verbs → remove RE, add U (vendre → vendu)',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('📝 Examples with AVOIR'),
        const ExampleBox(
          french: 'J\'ai regardé un film',
          english: 'I watched a movie',
        ),
        const ExampleBox(
          french: 'Tu as choisi ce livre',
          english: 'You chose this book',
        ),
        const ExampleBox(
          french: 'Nous avons attendu le bus',
          english: 'We waited for the bus',
        ),
        const SectionTitle(' 🚶 Examples with ÊTRE (Movement Verbs)'),
        const Text(
          'Remember DR & MRS VANDERTRAMP for ÊTRE verbs!',
          style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
        ),
        const ExampleBox(
          french: 'Je suis allé(e) à Paris',
          english: 'I went to Paris',
        ),
        const ExampleBox(
          french: 'Elle est arrivée ce matin',
          english: 'She arrived this morning',
        ),
        const ExampleBox(
          french: 'Nous sommes partis tôt',
          english: 'We left early',
        ),
        const TipBox(
          title: '⚠️ IMPORTANT!',
          content:
              'With ÊTRE, the past participle must AGREE with the subject (add e for feminine, s for plural, es for feminine plural)',
          icon: Icons.warning,
          color: Color(0xFFEF4444),
        ),
        const SectionTitle('🎯 Common Irregular Past Participles'),
        const Text(
          'These troublemakers don\'t follow the rules:\n\n'
          '• être → été (been)\n'
          '• avoir → eu (had)\n'
          '• faire → fait (done/made)\n'
          '• voir → vu (seen)\n'
          '• prendre → pris (taken)\n'
          '• mettre → mis (put)\n'
          '• écrire → écrit (written)\n'
          '• lire → lu (read)',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const SectionTitle('❌ Common Mistakes'),
        const TipBox(
          title: 'Don\'t  Forget the Helper Verb!',
          content: '❌ Je mangé ➜ ✅ J\'ai mangé\nYou ALWAYS need avoir or être!',
          icon: Icons.error_outline,
          color: Color(0xFFF59E0B),
        ),
        const TipBox(
          title: 'Watch Out for Agreement!',
          content:
              '❌ Marie est allé ➜ ✅ Marie est allée\nWith être, add -e for feminine subjects!',
          icon: Icons.error_outline,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}
