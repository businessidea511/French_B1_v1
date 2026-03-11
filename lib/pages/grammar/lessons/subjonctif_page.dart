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
        // Each category uses SectionTitle (TranslatedText = translates) + FrenchTipBox (French stays French)
        const SectionTitle('🎯 When Do You Use It?'),
        const TranslatedText(
          'Use Subjonctif after these 5 types of expressions:',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),

        const SectionTitle('1️⃣ Wishes & Desires'),
        const FrenchTipBox(
          title: 'Key expressions',
          frenchText: 'Je veux que...\n'
              'Je voudrais que...\n'
              'J\'aimerais que...\n'
              'Je désire que...',
          icon: Icons.favorite,
          color: Color(0xFF6366F1),
        ),

        const SectionTitle('2️⃣ Emotions & Feelings'),
        const FrenchTipBox(
          title: 'Key expressions',
          frenchText: 'Je suis content(e) que...\n'
              'Je suis triste que...\n'
              'J\'ai peur que...\n'
              'Il est dommage que...\n'
              'C\'est incroyable que...',
          icon: Icons.favorite_border,
          color: Color(0xFFEC4899),
        ),

        const SectionTitle('3️⃣ Doubt & Uncertainty'),
        const FrenchTipBox(
          title: 'Key expressions',
          frenchText: 'Je doute que...\n'
              'Il est possible que...\n'
              'Il est peu probable que...\n'
              'Il est improbable que...',
          icon: Icons.help_outline,
          color: Color(0xFFF59E0B),
        ),

        const SectionTitle('4️⃣ Obligation & Necessity'),
        const FrenchTipBox(
          title: 'Key expressions',
          frenchText: 'Il faut que...\n'
              'Il est nécessaire que...\n'
              'Il est important que...\n'
              'Il est essentiel que...',
          icon: Icons.assignment_turned_in,
          color: Color(0xFF10B981),
        ),

        const SectionTitle('5️⃣ Conjunctions (time / purpose / concession)'),
        const FrenchTipBox(
          title: 'Key conjunctions that trigger Subjonctif',
          frenchText: 'pour que...        (so that)\n'
              'afin que...        (in order that)\n'
              'bien que...        (although)\n'
              'quoique...         (although)\n'
              'avant que...       (before)\n'
              'à moins que...     (unless)\n'
              'jusqu\'à ce que... (until)',
          icon: Icons.link,
          color: Color(0xFF8B5CF6),
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
        const SectionTitle(
            '🚨 15 Most Important Irregular Verbs — Memorize These!'),
        const TranslatedText(
          'These verbs do NOT follow the regular pattern. They are the most frequently used in French — learn them well!',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),

        // ★ Group 1 — Completely irregular (must memorize fully)
        const FrenchTipBox(
          title: 'ÊTRE — completely irregular ★ most important',
          frenchText: 'que je       sois\n'
              'que tu       sois\n'
              'qu\'il/elle   soit\n'
              'que nous     soyons\n'
              'que vous     soyez\n'
              'qu\'ils/elles soient',
          icon: Icons.star,
          color: Color(0xFF8B5CF6),
        ),
        const FrenchTipBox(
          title: 'AVOIR — completely irregular ★ most important',
          frenchText: 'que j\'aie\n'
              'que tu aies\n'
              'qu\'il/elle   ait\n'
              'que nous     ayons\n'
              'que vous     ayez\n'
              'qu\'ils/elles aient',
          icon: Icons.star,
          color: Color(0xFFEC4899),
        ),

        // ★ Group 2 — Very common irregulars
        const FrenchTipBox(
          title: 'ALLER — to go',
          frenchText: 'que j\'aille      que nous allions\n'
              'que tu ailles    que vous alliez\n'
              'qu\'il aille      qu\'ils aillent',
          icon: Icons.directions_run,
          color: Color(0xFF10B981),
        ),
        const FrenchTipBox(
          title: 'FAIRE — to do / make',
          frenchText: 'que je fasse     que nous fassions\n'
              'que tu fasses    que vous fassiez\n'
              'qu\'il fasse      qu\'ils fassent',
          icon: Icons.build,
          color: Color(0xFF10B981),
        ),
        const FrenchTipBox(
          title: 'POUVOIR — to be able to / can',
          frenchText: 'que je puisse    que nous puissions\n'
              'que tu puisses   que vous puissiez\n'
              'qu\'il puisse     qu\'ils puissent',
          icon: Icons.bolt,
          color: Color(0xFF0EA5E9),
        ),
        const FrenchTipBox(
          title: 'SAVOIR — to know',
          frenchText: 'que je sache     que nous sachions\n'
              'que tu saches    que vous sachiez\n'
              'qu\'il sache      qu\'ils sachent',
          icon: Icons.school,
          color: Color(0xFF0EA5E9),
        ),
        const FrenchTipBox(
          title: 'VOULOIR — to want',
          frenchText: 'que je veuille   que nous voulions\n'
              'que tu veuilles  que vous vouliez\n'
              'qu\'il veuille    qu\'ils veuillent',
          icon: Icons.favorite,
          color: Color(0xFFF59E0B),
        ),
        const FrenchTipBox(
          title: 'VENIR — to come',
          frenchText: 'que je vienne    que nous venions\n'
              'que tu viennes   que vous veniez\n'
              'qu\'il vienne     qu\'ils viennent',
          icon: Icons.login,
          color: Color(0xFFF59E0B),
        ),

        // ★ Group 3 — Common semi-irregulars
        const FrenchTipBox(
          title: 'PRENDRE — to take',
          frenchText: 'que je prenne    que nous prenions\n'
              'que tu prennes   que vous preniez\n'
              'qu\'il prenne     qu\'ils prennent',
          icon: Icons.pan_tool,
          color: Color(0xFFEF4444),
        ),
        const FrenchTipBox(
          title: 'DEVOIR — must / to have to',
          frenchText: 'que je doive     que nous devions\n'
              'que tu doives    que vous deviez\n'
              'qu\'il doive      qu\'ils doivent',
          icon: Icons.assignment,
          color: Color(0xFFEF4444),
        ),
        const FrenchTipBox(
          title: 'BOIRE — to drink',
          frenchText: 'que je boive     que nous buvions\n'
              'que tu boives    que vous buviez\n'
              'qu\'il boive      qu\'ils boivent',
          icon: Icons.local_drink,
          color: Color(0xFF6366F1),
        ),
        const FrenchTipBox(
          title: 'VENIR — TENIR — to hold',
          frenchText: 'que je tienne    que nous tenions\n'
              'que tu tiennes   que vous teniez\n'
              'qu\'il tienne     qu\'ils tiennent',
          icon: Icons.back_hand,
          color: Color(0xFF6366F1),
        ),
        const FrenchTipBox(
          title: 'CROIRE — to believe',
          frenchText: 'que je croie     que nous croyions\n'
              'que tu croies    que vous croyiez\n'
              'qu\'il croie      qu\'ils croient',
          icon: Icons.psychology,
          color: Color(0xFF8B5CF6),
        ),
        const FrenchTipBox(
          title: 'RECEVOIR — to receive',
          frenchText: 'que je reçoive   que nous recevions\n'
              'que tu reçoives  que vous receviez\n'
              'qu\'il reçoive    qu\'ils reçoivent',
          icon: Icons.inbox,
          color: Color(0xFF8B5CF6),
        ),
        const FrenchTipBox(
          title: 'VALOIR — to be worth',
          frenchText: 'que je vaille    que nous valions\n'
              'que tu vailles   que vous valiez\n'
              'qu\'il vaille     qu\'ils vaillent',
          icon: Icons.star_rate,
          color: Color(0xFFEC4899),
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
              'Positive penser/croire + que  →  Indicatif\n'
              'Negative/question penser/croire + que  →  Subjonctif\n'
              '✅  Je ne pense pas qu\'il SOIT là.',
          icon: Icons.error_outline,
          color: Color(0xFFEF4444),
        ),
        const FrenchTipBox(
          title: 'Mistake 3 — Forgetting "que" before Subjonctif',
          frenchText: '❌  Il faut tu fasses cela.\n'
              '✅  Il faut QUE tu fasses cela.\n\n'
              '"que" is mandatory between the trigger and the Subjonctif!',
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
