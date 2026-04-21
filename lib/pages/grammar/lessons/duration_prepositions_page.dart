import 'package:flutter/material.dart';
import '../../../widgets/lesson_template.dart';

class DurationPrepositionsPage extends StatelessWidget {
  const DurationPrepositionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LessonTemplate(
      title: 'Mots de Temps',
      icon: '🕰️',
      children: [
        const Text(
          'Talking about time in French is like being a time traveler 🕰️. You need different tools depending on whether you\'re looking back, looking forward, or measuring how long things take.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        
        const SectionTitle('🔄 Depuis (Since / For)', emoji: null),
        const Text(
          'Use "Depuis" when an action started in the past and is STILL HAPPENING right now. In English, we usually use "have been doing".',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const ExampleBox(
          french: 'J\'habite à Paris depuis 2020',
          english: 'I have lived in Paris since 2020 (and I still live there!)',
        ),
        const ExampleBox(
          french: 'Je t\'attends depuis une heure',
          english: 'I have been waiting for you for an hour (and I\'m still waiting!)',
        ),
        const TipBox(
          title: 'Wait! What about "For"?',
          content: 'In English, you use "For" for both finished and unfinished actions. In French, you MUST use "Depuis" if it\'s still going on!',
          icon: Icons.priority_high,
          color: Color(0xFF6366F1),
        ),

        const SectionTitle('⏳ Pendant (During / For)', emoji: null),
        const Text(
          'Use "Pendant" for a specific duration that has a clear START and END. It\'s for completed actions.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const ExampleBox(
          french: 'J\'ai dormi pendant 8 heures',
          english: 'I slept for 8 hours (the sleeping is finished)',
        ),
        const ExampleBox(
          french: 'Il a plu pendant tout le week-end',
          english: 'It rained during the whole weekend',
        ),

        const SectionTitle('⏪ Il y a (Ago)', emoji: null),
        const Text(
          'Use "Il y a" to point to a specific moment in the past. It works exactly like "Ago" in English.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const ExampleBox(
          french: 'Je suis arrivé il y a dix minutes',
          english: 'I arrived ten minutes ago',
        ),
        const ExampleBox(
          french: 'On s\'est rencontrés il y a longtemps',
          english: 'We met a long time ago',
        ),

        const SectionTitle('🚀 Dans (In - Future)', emoji: null),
        const Text(
          'Use "Dans" to talk about when something WILL happen in the future.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const ExampleBox(
          french: 'Le train part dans 5 minutes',
          english: 'The train leaves in 5 minutes',
        ),

        const SectionTitle('⚡ En (In - Time Required)', emoji: null),
        const Text(
          'Use "En" to express how much time was NEEDED to complete a task. Think of it as "within".',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const ExampleBox(
          french: 'J\'ai fini cet exercice en 10 minutes',
          english: 'I finished this exercise in 10 minutes (it took me 10 mins)',
        ),
        const ExampleBox(
          french: 'On a fait le tour du monde en 80 jours',
          english: 'We went around the world in 80 days',
        ),

        const TipBox(
          title: 'Quick Hack 💡',
          content: '• Still happening? -> Depuis\n• Finished duration? -> Pendant\n• How long it took? -> En\n• Specific past point? -> Il y a\n• Future point? -> Dans',
          icon: Icons.bolt,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}
