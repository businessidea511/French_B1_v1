import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class VoixPassivePage extends StatelessWidget {
  const VoixPassivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return LessonTemplate(
      title: lp.currentLanguage == AppLanguage.french
          ? 'La Voix Passive & Active'
          : 'Passive & Active Voice',
      icon: '🔄',
      children: [
        // ── INTRO ──────────────────────────────────────────────────────────
        const TranslatedText(
          'Imagine a football match ⚽.\n\n'
          '• ACTIVE voice = the player KICKS the ball. The player is the star!\n'
          '• PASSIVE voice = the ball IS KICKED by the player. The ball is now the star!\n\n'
          'Same event, different spotlight. That\'s all there is to it! 🎉',
          style: TextStyle(fontSize: 16, height: 1.7),
        ),

        // ── ACTIVE vs PASSIVE ──────────────────────────────────────────────
        const SectionTitle('⚡ Active vs Passive — Side by Side'),
        const TranslatedText(
          'In the ACTIVE voice:\n'
          '  Subject → does the action → to the Object\n\n'
          'In the PASSIVE voice:\n'
          '  Object → becomes the Subject → receives the action',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),
        const ExampleBox(
          french: '🟢 ACTIVE:  Le chef cuisine le repas.',
          english: 'The chef cooks the meal.   (chef = doing it)',
        ),
        const ExampleBox(
          french: '🔵 PASSIVE: Le repas est cuisiné par le chef.',
          english:
              'The meal is cooked by the chef.   (meal = in the spotlight)',
        ),
        const TipBox(
          title: '💡 When do French people use the passive?',
          content: '1. When we DON\'T KNOW who did the action.\n'
              '   → La banque a été volée.  (The bank was robbed — by whom? No idea!)\n\n'
              '2. When we DON\'T CARE who did it.\n'
              '   → Le pont a été construit en 1900.  (Built in 1900 — who built it doesn\'t matter)\n\n'
              '3. To put MORE FOCUS on the result than on the doer.',
          icon: Icons.lightbulb,
          color: Color(0xFF6366F1),
        ),

        // ── THE FORMULA ────────────────────────────────────────────────────
        const SectionTitle('🛠️ The Magic Formula — 3 Easy Steps'),
        const TipBox(
          title: 'Passive Formula',
          content:
              'SUBJECT  +  ÊTRE (correct tense)  +  PAST PARTICIPLE  +  (par + agent)\n\n'
              'Example:\n'
              '  Le gâteau  +  est  +  mangé  +  par les enfants.\n'
              '  The cake is eaten by the children.',
          icon: Icons.auto_fix_high,
          color: Color(0xFF10B981),
        ),
        const TranslatedText(
          'Step 1 ▶ Take the OBJECT of the active sentence → make it the new SUBJECT.\n'
          'Step 2 ▶ Conjugate ÊTRE in the SAME tense the original verb was in.\n'
          'Step 3 ▶ Add the PAST PARTICIPLE of the original verb.\n\n'
          'The original subject (the "doer") goes to the end with PAR (by) — or you can drop it completely!',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),

        // ── AGREEMENT RULE ─────────────────────────────────────────────────
        const SectionTitle('🎯 The Agreement Rule — Super Important!'),
        const TipBox(
          title: '⚠️ The Past Participle MUST match the NEW Subject',
          content: 'Add  -e  for feminine\n'
              'Add  -s  for masculine plural\n'
              'Add  -es  for feminine plural\n\n'
              'Examples:\n'
              '  Le livre est lu.          (masculine singular — no change)\n'
              '  La lettre est lue.        (feminine → add -e)\n'
              '  Les livres sont lus.      (masculine plural → add -s)\n'
              '  Les lettres sont lues.    (feminine plural → add -es)',
          icon: Icons.warning,
          color: Color(0xFFEF4444),
        ),

        // ── ÊTRE CONJUGATION TABLE ─────────────────────────────────────────
        const SectionTitle('📊 ÊTRE in Every Tense — Your Cheat Sheet'),
        const TranslatedText(
          'Because ÊTRE is the key verb in ALL passive sentences, you need to know it in every tense. Here it is!',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),

        // Present
        const TipBox(
          title: '1️⃣ Présent (Present) — "is / are"',
          content: 'je   suis\n'
              'tu   es\n'
              'il/elle   est\n'
              'nous   sommes\n'
              'vous   êtes\n'
              'ils/elles   sont',
          icon: Icons.access_time,
          color: Color(0xFF6366F1),
        ),
        const ExampleBox(
          french: 'Le repas est préparé par ma mère.',
          english:
              'The meal IS prepared by my mother.  (right now / in general)',
        ),

        // Passé Composé
        const TipBox(
          title: '2️⃣ Passé Composé (Past — completed action) — "was / were"',
          content: 'j\'ai été\n'
              'tu as été\n'
              'il/elle a été\n'
              'nous avons été\n'
              'vous avez été\n'
              'ils/elles ont été',
          icon: Icons.history,
          color: Color(0xFF10B981),
        ),
        const ExampleBox(
          french: 'La lettre a été écrite par Paul.',
          english: 'The letter WAS WRITTEN by Paul.  (it\'s done, finished!)',
        ),
        const ExampleBox(
          french: 'Les maisons ont été construites en 1990.',
          english: 'The houses WERE BUILT in 1990.',
        ),

        // Imparfait
        const TipBox(
          title: '3️⃣ Imparfait (Imperfect) — "was being / used to be"',
          content: 'j\'étais\n'
              'tu étais\n'
              'il/elle était\n'
              'nous étions\n'
              'vous étiez\n'
              'ils/elles étaient',
          icon: Icons.replay,
          color: Color(0xFFF59E0B),
        ),
        const ExampleBox(
          french: 'Le livre était lu chaque soir.',
          english:
              'The book WAS BEING READ every evening.  (ongoing / repeated habit)',
        ),
        const ExampleBox(
          french: 'Les enfants étaient surveillés par leurs parents.',
          english: 'The children WERE BEING WATCHED by their parents.',
        ),

        // Futur Simple
        const TipBox(
          title: '4️⃣ Futur Simple (Future) — "will be"',
          content: 'je serai\n'
              'tu seras\n'
              'il/elle sera\n'
              'nous serons\n'
              'vous serez\n'
              'ils/elles seront',
          icon: Icons.arrow_forward,
          color: Color(0xFF0EA5E9),
        ),
        const ExampleBox(
          french: 'Le gâteau sera mangé demain.',
          english: 'The cake WILL BE eaten tomorrow.',
        ),
        const ExampleBox(
          french: 'Les résultats seront annoncés lundi.',
          english: 'The results WILL BE announced on Monday.',
        ),

        // Conditionnel
        const TipBox(
          title: '5️⃣ Conditionnel Présent (Conditional) — "would be"',
          content: 'je serais\n'
              'tu serais\n'
              'il/elle serait\n'
              'nous serions\n'
              'vous seriez\n'
              'ils/elles seraient',
          icon: Icons.help_outline,
          color: Color(0xFFEC4899),
        ),
        const ExampleBox(
          french: 'Le travail serait fini si tu aidais.',
          english: 'The work WOULD BE finished if you helped.',
        ),

        // Plus-que-parfait
        const TipBox(
          title: '6️⃣ Plus-que-parfait (Pluperfect) — "had been"',
          content: 'j\'avais été\n'
              'tu avais été\n'
              'il/elle avait été\n'
              'nous avions été\n'
              'vous aviez été\n'
              'ils/elles avaient été',
          icon: Icons.fast_rewind,
          color: Color(0xFF8B5CF6),
        ),
        const ExampleBox(
          french: 'La porte avait été fermée avant notre arrivée.',
          english: 'The door HAD BEEN closed before we arrived.',
        ),

        // ── TENSE SUMMARY ──────────────────────────────────────────────────
        const SectionTitle('📋 Quick Tense Summary'),
        const TranslatedText(
          '• Présent          →  est / sont  +  participle\n'
          '• Passé Composé    →  a été / ont été  +  participle\n'
          '• Imparfait        →  était / étaient  +  participle\n'
          '• Futur Simple     →  sera / seront  +  participle\n'
          '• Conditionnel     →  serait / seraient  +  participle\n'
          '• Plus-que-parfait →  avait été / avaient été  +  participle',
          style: TextStyle(fontSize: 15, height: 2.0, fontFamily: 'monospace'),
        ),

        // ── THE "ON" SHORTCUT ──────────────────────────────────────────────
        const SectionTitle('🤫 The French Secret — Use "ON" Instead!'),
        const TipBox(
          title: 'Native speakers rarely use the passive!',
          content:
              'In everyday spoken French, people prefer "on" (someone / they / one) over the passive voice. It sounds much more natural!\n\n'
              '❌ Passive:  La porte a été fermée.  (The door was closed.)\n'
              '✅ Natural:  On a fermé la porte.    (Someone closed the door.)\n\n'
              '❌ Passive:  Les magasins seront ouverts.  (The shops will be opened.)\n'
              '✅ Natural:  On va ouvrir les magasins.    (They\'re going to open the shops.)\n\n'
              'Use the passive in WRITING, reports, and formal contexts — but "on" in everyday conversation!',
          icon: Icons.psychology,
          color: Color(0xFF10B981),
        ),

        // ── COMMON MISTAKES ────────────────────────────────────────────────
        const SectionTitle('❌ Common Mistakes'),
        const TipBox(
          title: 'Mistake 1 — Forgetting the Agreement',
          content: '❌ La lettre est écrit par Paul.\n'
              '✅ La lettre est écrite par Paul.\n\n'
              '"La lettre" is feminine → the participle needs -e!',
          icon: Icons.error_outline,
          color: Color(0xFFF59E0B),
        ),
        const TipBox(
          title: 'Mistake 2 — Wrong Tense of ÊTRE',
          content:
              '❌ Le repas est préparé hier.  (using present for a past action)\n'
              '✅ Le repas a été préparé hier.\n\n'
              'Always match ÊTRE\'s tense to WHEN the action happened!',
          icon: Icons.error_outline,
          color: Color(0xFFF59E0B),
        ),
        const TipBox(
          title: 'Mistake 3 — Using AVOIR instead of ÊTRE',
          content: '❌ Le gâteau a mangé par les enfants.\n'
              '✅ Le gâteau est mangé par les enfants.\n\n'
              'Passive voice ALWAYS uses ÊTRE — never "avoir" directly as the linking verb!',
          icon: Icons.error_outline,
          color: Color(0xFFEF4444),
        ),

        // ── FINAL PRACTICE ─────────────────────────────────────────────────
        const SectionTitle('🏋️ Practice — Flip These Sentences!'),
        const TranslatedText(
          'Try turning these ACTIVE sentences into PASSIVE:\n\n'
          '1. Le professeur explique la leçon.\n'
          '   → La leçon ___ expliquée par le professeur.\n\n'
          '2. Les enfants ont mangé les bonbons.\n'
          '   → Les bonbons ___ ___ mangés par les enfants.\n\n'
          '3. On construira un nouveau pont.\n'
          '   → Un nouveau pont ___ construit.',
          style: TextStyle(fontSize: 15, height: 1.9),
        ),
        const TipBox(
          title: '✅ Answers',
          content: '1. La leçon EST expliquée par le professeur.  (présent)\n'
              '2. Les bonbons ONT ÉTÉ mangés par les enfants.  (passé composé)\n'
              '3. Un nouveau pont SERA construit.  (futur simple)',
          icon: Icons.check_circle_outline,
          color: Color(0xFF10B981),
        ),
      ],
    );
  }
}
