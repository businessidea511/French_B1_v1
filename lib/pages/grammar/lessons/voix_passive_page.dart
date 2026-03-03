import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

// ── Helper: a styled box where the TITLE is translated but
//    the FRENCH content stays in plain Text (never translated).
class _FrenchTipBox extends StatelessWidget {
  final String title; // translated label / heading
  final String frenchText; // always stays in French
  final IconData icon;
  final Color color;

  const _FrenchTipBox({
    required this.title,
    required this.frenchText,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                // ← plain Text: French never gets translated
                Text(
                  frenchText,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.7,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
              '2. When we DON\'T CARE who did it.\n'
              '3. To put MORE FOCUS on the result than on the doer.',
          icon: Icons.lightbulb,
          color: Color(0xFF6366F1),
        ),

        // ── THE FORMULA ────────────────────────────────────────────────────
        const SectionTitle('🛠️ The Magic Formula — 3 Easy Steps'),
        // Formula box — French formula stays in French
        _FrenchTipBox(
          title: 'Passive Formula',
          frenchText:
              'SUBJECT  +  ÊTRE (correct tense)  +  PAST PARTICIPLE  +  (par + agent)\n\n'
              'Exemple :\n'
              '  Le gâteau  +  est  +  mangé  +  par les enfants.',
          icon: Icons.auto_fix_high,
          color: const Color(0xFF10B981),
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
        const TranslatedText(
          'The past participle must MATCH the new subject in gender and number:',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
        _FrenchTipBox(
          title: '⚠️ Add -e / -s / -es to the participle',
          frenchText:
              '  Le livre est lu.           (masculine singular — no change)\n'
              '  La lettre est lue.         (feminine → add -e)\n'
              '  Les livres sont lus.       (masculine plural → add -s)\n'
              '  Les lettres sont lues.     (feminine plural → add -es)',
          icon: Icons.warning,
          color: const Color(0xFFEF4444),
        ),

        // ── ÊTRE CONJUGATION TABLE ─────────────────────────────────────────
        const SectionTitle('📊 ÊTRE in Every Tense — Your Cheat Sheet'),
        const TranslatedText(
          'Because ÊTRE is the key verb in ALL passive sentences, you need to know it in every tense. Here it is — always in French!',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),

        // 1. Présent
        _FrenchTipBox(
          title: '1️⃣ Présent — "is / are"',
          frenchText: 'je          suis\n'
              'tu          es\n'
              'il / elle   est\n'
              'nous        sommes\n'
              'vous        êtes\n'
              'ils / elles sont',
          icon: Icons.access_time,
          color: const Color(0xFF6366F1),
        ),
        const ExampleBox(
          french: 'Le repas est préparé par ma mère.',
          english:
              'The meal IS prepared by my mother.  (right now / in general)',
        ),

        // 2. Passé Composé
        _FrenchTipBox(
          title: '2️⃣ Passé Composé — "was / were" (completed)',
          frenchText: 'j\'ai été\n'
              'tu as été\n'
              'il / elle a été\n'
              'nous avons été\n'
              'vous avez été\n'
              'ils / elles ont été',
          icon: Icons.history,
          color: const Color(0xFF10B981),
        ),
        const ExampleBox(
          french: 'La lettre a été écrite par Paul.',
          english: 'The letter WAS WRITTEN by Paul.  (done, finished!)',
        ),
        const ExampleBox(
          french: 'Les maisons ont été construites en 1990.',
          english: 'The houses WERE BUILT in 1990.',
        ),

        // 3. Imparfait
        _FrenchTipBox(
          title: '3️⃣ Imparfait — "was being / used to be"',
          frenchText: 'j\'étais\n'
              'tu étais\n'
              'il / elle était\n'
              'nous étions\n'
              'vous étiez\n'
              'ils / elles étaient',
          icon: Icons.replay,
          color: const Color(0xFFF59E0B),
        ),
        const ExampleBox(
          french: 'Le livre était lu chaque soir.',
          english: 'The book WAS BEING READ every evening.  (ongoing / habit)',
        ),
        const ExampleBox(
          french: 'Les enfants étaient surveillés par leurs parents.',
          english: 'The children WERE BEING WATCHED by their parents.',
        ),

        // 4. Futur Simple
        _FrenchTipBox(
          title: '4️⃣ Futur Simple — "will be"',
          frenchText: 'je serai\n'
              'tu seras\n'
              'il / elle sera\n'
              'nous serons\n'
              'vous serez\n'
              'ils / elles seront',
          icon: Icons.arrow_forward,
          color: const Color(0xFF0EA5E9),
        ),
        const ExampleBox(
          french: 'Le gâteau sera mangé demain.',
          english: 'The cake WILL BE eaten tomorrow.',
        ),
        const ExampleBox(
          french: 'Les résultats seront annoncés lundi.',
          english: 'The results WILL BE announced on Monday.',
        ),

        // 5. Conditionnel Présent
        _FrenchTipBox(
          title: '5️⃣ Conditionnel Présent — "would be"',
          frenchText: 'je serais\n'
              'tu serais\n'
              'il / elle serait\n'
              'nous serions\n'
              'vous seriez\n'
              'ils / elles seraient',
          icon: Icons.help_outline,
          color: const Color(0xFFEC4899),
        ),
        const ExampleBox(
          french: 'Le travail serait fini si tu aidais.',
          english: 'The work WOULD BE finished if you helped.',
        ),

        // 6. Plus-que-parfait
        _FrenchTipBox(
          title: '6️⃣ Plus-que-parfait — "had been"',
          frenchText: 'j\'avais été\n'
              'tu avais été\n'
              'il / elle avait été\n'
              'nous avions été\n'
              'vous aviez été\n'
              'ils / elles avaient été',
          icon: Icons.fast_rewind,
          color: const Color(0xFF8B5CF6),
        ),
        const ExampleBox(
          french: 'La porte avait été fermée avant notre arrivée.',
          english: 'The door HAD BEEN closed before we arrived.',
        ),

        // ── TENSE SUMMARY ──────────────────────────────────────────────────
        const SectionTitle('📋 Quick Tense Summary'),
        // Summary — French verbs must NOT be translated
        _FrenchTipBox(
          title: 'All 6 passive patterns at a glance',
          frenchText: '• Présent          →  est / sont  +  participe\n'
              '• Passé Composé    →  a été / ont été  +  participe\n'
              '• Imparfait        →  était / étaient  +  participe\n'
              '• Futur Simple     →  sera / seront  +  participe\n'
              '• Conditionnel     →  serait / seraient  +  participe\n'
              '• Plus-que-parfait →  avait été / avaient été  +  participe',
          icon: Icons.table_chart,
          color: const Color(0xFF6366F1),
        ),

        // ── THE "ON" SHORTCUT ──────────────────────────────────────────────
        const SectionTitle('🤫 The French Secret — Use "ON" Instead!'),
        const TipBox(
          title: 'Native speakers rarely use the passive!',
          content:
              'In everyday spoken French, people prefer "on" (someone / they) over the passive voice. It sounds much more natural!\n\n'
              'Use the passive in WRITING, reports, and formal contexts — "on" in daily conversation!',
          icon: Icons.psychology,
          color: Color(0xFF10B981),
        ),
        const ExampleBox(
          french: '❌ Passive:  La porte a été fermée.',
          english:
              '✅ Natural:  On a fermé la porte.  (Someone closed the door.)',
        ),
        const ExampleBox(
          french: '❌ Passive:  Les magasins seront ouverts.',
          english:
              '✅ Natural:  On va ouvrir les magasins.  (They\'re going to open the shops.)',
        ),

        // ── COMMON MISTAKES ────────────────────────────────────────────────
        const SectionTitle('❌ Common Mistakes'),
        _FrenchTipBox(
          title: 'Mistake 1 — Forgetting the Agreement',
          frenchText: '❌  La lettre est écrit par Paul.\n'
              '✅  La lettre est écrite par Paul.\n\n'
              '"La lettre" est féminin → participe + e !',
          icon: Icons.error_outline,
          color: const Color(0xFFF59E0B),
        ),
        _FrenchTipBox(
          title: 'Mistake 2 — Wrong Tense of ÊTRE',
          frenchText: '❌  Le repas est préparé hier.\n'
              '✅  Le repas a été préparé hier.\n\n'
              'Action hier = Passé Composé → "a été" !',
          icon: Icons.error_outline,
          color: const Color(0xFFF59E0B),
        ),
        _FrenchTipBox(
          title: 'Mistake 3 — Using AVOIR instead of ÊTRE',
          frenchText: '❌  Le gâteau a mangé par les enfants.\n'
              '✅  Le gâteau est mangé par les enfants.\n\n'
              'La voix passive utilise toujours ÊTRE !',
          icon: Icons.error_outline,
          color: const Color(0xFFEF4444),
        ),

        // ── FINAL PRACTICE ─────────────────────────────────────────────────
        const SectionTitle('🏋️ Practice — Flip These Sentences!'),
        const TranslatedText(
          'Try turning these ACTIVE sentences into PASSIVE (fill in the blanks):',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
        const ExampleBox(
          french: '1. Le professeur explique la leçon.\n'
              '   → La leçon ___ expliquée par le professeur.\n\n'
              '2. Les enfants ont mangé les bonbons.\n'
              '   → Les bonbons ___ ___ mangés par les enfants.\n\n'
              '3. On construira un nouveau pont.\n'
              '   → Un nouveau pont ___ construit.',
          english: 'Fill in the missing form(s) of ÊTRE!',
        ),
        // Answers — always in French, never translated
        _FrenchTipBox(
          title: '✅ Answers',
          frenchText: '1. La leçon  EST  expliquée par le professeur.\n'
              '   (Présent)\n\n'
              '2. Les bonbons  ONT ÉTÉ  mangés par les enfants.\n'
              '   (Passé Composé)\n\n'
              '3. Un nouveau pont  SERA  construit.\n'
              '   (Futur Simple)',
          icon: Icons.check_circle_outline,
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }
}
