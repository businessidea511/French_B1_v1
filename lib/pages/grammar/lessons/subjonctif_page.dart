import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';
import '../../../services/language_provider.dart';

class SubjonctifPage extends StatelessWidget {
  const SubjonctifPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return LessonTemplate(
      title: lp.currentLanguage == AppLanguage.french
          ? 'Le Subjonctif'
          : 'The Subjunctive',
      icon: '🌀',
      children: [
        // ── INTRO ──────────────────────────────────────────────────────────
        const TranslatedText(
          'Imagine two people talking:\n\n'
          '👤 "Tu viens?" (Are you coming?) — FACTS, certainty → use Indicatif\n'
          '👤 "Je veux que tu viennes." (I want you to come!) — FEELINGS, wishes, doubt → use Subjonctif\n\n'
          'The Subjonctif is the tense of EMOTIONS and UNCERTAINTY. Whenever you express a wish, a fear, a doubt, or an obligation, you switch into Subjonctif mode! 🎭',
          style: TextStyle(fontSize: 16, height: 1.7),
        ),

        // ── WHEN TO USE IT ─────────────────────────────────────────────────
        const SectionTitle('🎯 When Do You Use It?'),
        const TranslatedText(
          'Use Subjonctif after these types of expressions:',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
        const FrenchTipBox(
          title: '5 Trigger Categories',
          frenchText: '1️⃣  WISHES / DESIRES\n'
              '   Je veux que... / Je voudrais que...\n'
              '   J\'aimerais que...\n\n'
              '2️⃣  EMOTIONS / FEELINGS\n'
              '   Je suis content(e) que...\n'
              '   J\'ai peur que...\n'
              '   Il est dommage que...\n\n'
              '3️⃣  DOUBT / UNCERTAINTY\n'
              '   Je doute que...\n'
              '   Il est possible que...\n'
              '   Il est peu probable que...\n\n'
              '4️⃣  OBLIGATION / NECESSITY\n'
              '   Il faut que...\n'
              '   Il est nécessaire que...\n'
              '   Il est important que...\n\n'
              '5️⃣  CONJUNCTIONS (time / purpose)\n'
              '   pour que... / afin que... (so that)\n'
              '   bien que... / quoique... (although)\n'
              '   avant que... (before)\n'
              '   à moins que... (unless)',
          icon: Icons.category,
          color: Color(0xFF6366F1),
        ),

        // ── THE KEY RULE ───────────────────────────────────────────────────
        const SectionTitle('⚠️ The Golden Rule — TWO Different Subjects!'),
        const TipBox(
          title: 'SAME subject? Don\'t use Subjonctif!',
          content:
              'Subjonctif only appears when the MAIN clause and the SUBORDINATE clause have DIFFERENT subjects.\n\n'
              '✅ DIFFERENT subjects  →  use Subjonctif\n'
              '   Je veux que TU viennes. (I want / you to come)\n\n'
              '✅ SAME subject  →  use Infinitive instead\n'
              '   Je veux venir. (I want to come — same person "I")',
          icon: Icons.warning,
          color: Color(0xFFEF4444),
        ),

        // ── HOW TO BUILD IT ────────────────────────────────────────────────
        const SectionTitle('🔧 How to Form It — 3 Simple Steps'),
        const TipBox(
          title: 'The Formula',
          content: 'Step 1 ▶ Take the ILS/ELLES form of the present tense.\n'
              'Step 2 ▶ Remove the -ENT ending to get the STEM.\n'
              'Step 3 ▶ Add these endings:\n'
              '   -e, -es, -e, -ions, -iez, -ent',
          icon: Icons.auto_fix_high,
          color: Color(0xFF10B981),
        ),

        // ── PARLER EXAMPLE ─────────────────────────────────────────────────
        const SectionTitle('📝 Step-by-Step: PARLER (to speak)'),
        const FrenchTipBox(
          title: 'PARLER → ils parlent → stem: parl-',
          frenchText: 'que je         parle\n'
              'que tu         parles\n'
              'qu\'il / elle   parle\n'
              'que nous       parlions\n'
              'que vous       parliez\n'
              'qu\'ils / elles parlent',
          icon: Icons.record_voice_over,
          color: Color(0xFF6366F1),
        ),

        // ── FINIR EXAMPLE ──────────────────────────────────────────────────
        const FrenchTipBox(
          title: 'FINIR → ils finissent → stem: finiss-',
          frenchText: 'que je         finisse\n'
              'que tu         finisses\n'
              'qu\'il / elle   finisse\n'
              'que nous       finissions\n'
              'que vous       finissiez\n'
              'qu\'ils / elles finissent',
          icon: Icons.check_circle_outline,
          color: Color(0xFF10B981),
        ),

        // ── COMMON EXAMPLES ────────────────────────────────────────────────
        const SectionTitle('✨ Common Real-Life Examples'),
        const ExampleBox(
          french: 'Il faut que tu fasses tes devoirs.',
          english: 'You have to do your homework.  (necessity)',
        ),
        const ExampleBox(
          french: 'Je suis content qu\'elle soit là.',
          english: 'I\'m glad she is here.  (emotion)',
        ),
        const ExampleBox(
          french: 'Il est possible que nous soyons en retard.',
          english: 'It\'s possible that we will be late.  (doubt)',
        ),
        const ExampleBox(
          french: 'Je veux que vous parliez plus lentement.',
          english: 'I want you to speak more slowly.  (wish)',
        ),
        const ExampleBox(
          french: 'Je téléphone avant que tu partes.',
          english: 'I\'ll call before you leave.  (conjunction)',
        ),

        // ── IRREGULAR VERBS ────────────────────────────────────────────────
        const SectionTitle('🚨 The Irregular "Big 6" — Memorize These!'),
        const TranslatedText(
          'These 6 verbs do NOT follow the regular pattern. You MUST learn them by heart:',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
        const FrenchTipBox(
          title: 'ÊTRE — completely irregular',
          frenchText: 'que je    sois\n'
              'que tu    sois\n'
              'qu\'il/elle soit\n'
              'que nous  soyons\n'
              'que vous  soyez\n'
              'qu\'ils/elles soient',
          icon: Icons.star,
          color: Color(0xFF8B5CF6),
        ),
        const FrenchTipBox(
          title: 'AVOIR — completely irregular',
          frenchText: 'que j\'aie\n'
              'que tu aies\n'
              'qu\'il/elle ait\n'
              'que nous ayons\n'
              'que vous ayez\n'
              'qu\'ils/elles aient',
          icon: Icons.star,
          color: Color(0xFFEC4899),
        ),
        const FrenchTipBox(
          title: 'ALLER / FAIRE / POUVOIR / SAVOIR',
          frenchText: 'aller   →  que j\'aille,  que nous allions\n'
              'faire   →  que je fasse,  que nous fassions\n'
              'pouvoir →  que je puisse, que nous puissions\n'
              'savoir  →  que je sache,  que nous sachions',
          icon: Icons.warning,
          color: Color(0xFFF59E0B),
        ),

        // ── COMMON MISTAKES ────────────────────────────────────────────────
        const SectionTitle('❌ Common Mistakes'),
        const FrenchTipBox(
          title: 'Mistake 1 — Using Indicatif when Subjonctif needed',
          frenchText:
              '❌  Je veux que tu VIENS.        (viens = present indicatif)\n'
              '✅  Je veux que tu VIENNES.      (viennes = subjonctif)\n\n'
              'After "vouloir que", always use Subjonctif!',
          icon: Icons.error_outline,
          color: Color(0xFFF59E0B),
        ),
        const FrenchTipBox(
          title: 'Mistake 2 — Using Subjonctif with penser/croire (positive)',
          frenchText: '❌  Je pense qu\'il SOIT là.      (Subjonctif — wrong!)\n'
              '✅  Je pense qu\'il EST là.       (Indicatif — correct!)\n\n'
              'Penser/croire + que in POSITIVE = Indicatif\n'
              'Penser/croire + que in NEGATIVE/QUESTION = Subjonctif\n'
              '✅  Je ne pense pas qu\'il SOIT là.  (Subjonctif — correct!)',
          icon: Icons.error_outline,
          color: Color(0xFFEF4444),
        ),
        const FrenchTipBox(
          title: 'Mistake 3 — Forgetting "que" before Subjonctif',
          frenchText: '❌  Il faut tu fasses cela.\n'
              '✅  Il faut QUE tu fasses cela.\n\n'
              'The word "que" is mandatory between the trigger and the Subjonctif!',
          icon: Icons.error_outline,
          color: Color(0xFFF59E0B),
        ),

        // ── PRACTICE ───────────────────────────────────────────────────────
        const SectionTitle('🏋️ Practice — Fill in the Subjonctif!'),
        const TranslatedText(
          'Complete with the correct Subjonctif form:',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
        const ExampleBox(
          french: '1. Il faut que tu ___ (faire) tes devoirs.\n'
              '2. Je suis triste qu\'elle ___ (partir).\n'
              '3. Bien qu\'il ___ (être) tard, je reste.\n'
              '4. Il est possible que nous ___ (avoir) tort.',
          english: 'Fill in — use the Subjonctif of the verb in brackets!',
        ),
        const FrenchTipBox(
          title: '✅ Answers',
          frenchText: '1.  Il faut que tu  FASSES  tes devoirs.\n'
              '    (faire → que je fasse — irregular!)\n\n'
              '2.  Je suis triste qu\'elle  PARTE.\n'
              '    (partir → ils partent → stem: part- → parte)\n\n'
              '3.  Bien qu\'il  SOIT  tard, je reste.\n'
              '    (être → que je sois — irregular!)\n\n'
              '4.  Il est possible que nous  AYONS  tort.\n'
              '    (avoir → que nous ayons — irregular!)',
          icon: Icons.check_circle_outline,
          color: Color(0xFF10B981),
        ),
      ],
    );
  }
}
