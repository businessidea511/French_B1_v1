import 'package:flutter/material.dart';
import '../../../widgets/lesson_template.dart';
import '../../../widgets/translated_text.dart';

class MetiersPage extends StatelessWidget {
  const MetiersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LessonTemplate(
      title: 'Les Métiers',
      icon: '💼',
      topic: 'Les Métiers',
      children: [
        const TranslatedText(
          'Les Métiers = JOBS and PROFESSIONS. In Belgium, work is central to social life in Bruxelles, Liège, and Namur. '
          'This topic is essential for meeting people, navigating Actiris or Forem, and integrating into the Belgian professional landscape!',
          style: TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
        ),

        // ── Key rule ──────────────────────────────────────────────────────────
        const SectionTitle('🎯 The KEY Rule — No Article!'),
        const TranslatedText(
          'In French, when you say WHAT you do for work, you do NOT use "un/une"!\n\n'
          '✅  Je suis médecin.       (I am a doctor.)\n'
          '❌  Je suis UN médecin.    (WRONG — sounds weird!)\n\n'
          '✅  Elle est professeure.  (She is a teacher.)\n'
          '❌  Elle est UNE professeure.  (WRONG!)\n\n'
          'Think of it like a label, not a description.',
          style: TextStyle(fontSize: 15, height: 1.8),
        ),

        // ── Gender ────────────────────────────────────────────────────────────
        const SectionTitle('♂️♀️ Masculine & Feminine Forms'),
        const TranslatedText(
          'Most professions have TWO forms — one for men, one for women. '
          'The feminine is usually formed by adding -e or changing the ending:',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
        const FrenchTipBox(
          title: 'Regular patterns',
          frenchText: 'étudiant   →  étudiante       (student)\n'
              'employé    →  employée        (employee)\n'
              'avocat     →  avocate         (lawyer)\n'
              'directeur  →  directrice      (director)\n'
              'acteur     →  actrice         (actor/actress)\n'
              'serveur    →  serveuse        (waiter/waitress)\n'
              'chanteur   →  chanteuse       (singer)\n'
              'boulanger  →  boulangère      (baker)',
          icon: Icons.people,
          color: Color(0xFF6366F1),
        ),
        const TipBox(
          title: '💡 Same Form for Both Genders',
          content: 'Some jobs have the SAME word for men and women:\n'
              'médecin → (un/une) médecin\n'
              'professeur → (un/une) professeur\n'
              'ingénieur → (un/une) ingénieur\n\n'
              '(Though modern French increasingly uses: professeure, ingénieure)',
          icon: Icons.info_outline,
          color: Color(0xFF10B981),
        ),

        // ── Common jobs ───────────────────────────────────────────────────────
        const SectionTitle('📋 Most Common Professions'),
        const FrenchTipBox(
          title: 'Health & Education',
          frenchText: 'médecin          →  doctor\n'
              'infirmier/ière   →  nurse\n'
              'dentiste         →  dentist\n'
              'pharmacien/ne    →  pharmacist\n'
              'professeur       →  teacher\n'
              'instituteur/rice →  primary school teacher\n'
              'étudiant/e       →  student',
          icon: Icons.local_hospital_outlined,
          color: Color(0xFFEF4444),
        ),
        const FrenchTipBox(
          title: 'Business & Office',
          frenchText: 'directeur/rice   →  manager / director\n'
              'secrétaire       →  secretary\n'
              'comptable        →  accountant\n'
              'avocat/e         →  lawyer\n'
              'informaticien/ne →  IT specialist\n'
              'ingénieur/e      →  engineer\n'
              'architecte       →  architect',
          icon: Icons.business_center_outlined,
          color: Color(0xFF6366F1),
        ),
        const FrenchTipBox(
          title: 'Trades & Services',
          frenchText: 'cuisinier/ère    →  cook / chef\n'
              'serveur/euse     →  waiter / waitress\n'
              'boulanger/ère    →  baker\n'
              'coiffeur/euse    →  hairdresser\n'
              'plombier         →  plumber\n'
              'électricien/ne   →  electrician\n'
              'chauffeur        →  driver',
          icon: Icons.build_outlined,
          color: Color(0xFFF59E0B),
        ),
        const FrenchTipBox(
          title: 'Arts, Media & Culture',
          frenchText: 'artiste          →  artist\n'
              'musicien/ne      →  musician\n'
              'acteur/rice      →  actor / actress\n'
              'chanteur/euse    →  singer\n'
              'journaliste      →  journalist\n'
              'photographe      →  photographer\n'
              'écrivain/e       →  writer',
          icon: Icons.palette_outlined,
          color: Color(0xFF10B981),
        ),
        
        // ── Rare & Dangerous ──────────────────────────────────────────────────
        const SectionTitle('⚡ Rare & Dangerous Professions'),
        const TranslatedText(
          'Some jobs in France are known for being particularly risky or unusual. Here are a few "métiers de l\'extrême":',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
        const FrenchTipBox(
          title: 'Extreme Careers',
          frenchText: 'marin-pêcheur     →  deep-sea fisher\n'
              'démineur          →  bomb disposal expert\n'
              'élagueur          →  tree surgeon / trimmer\n'
              'scaphandrier      →  deep-sea diver\n'
              'cascadeur         →  stunt performer\n'
              'laveur de vitres  →  skyscraper window cleaner\n'
              'égoutier          →  sewer worker\n'
              'nettoyeur de crime → crime scene cleaner\n'
              'récupérateur de venin → venom milker\n'
              'convoyeur de fonds → armored car guard',
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFEF4444),
        ),
        const ExampleBox(
          french: 'Le métier de marin-pêcheur est l\'un des plus dangereux au monde.',
          english: 'The job of deep-sea fisher is one of the most dangerous in the world.',
        ),
        const ExampleBox(
          french: 'Il travaille comme démineur pour l\'armée.',
          english: 'He works as a bomb disposal expert for the army.',
        ),
        const ExampleBox(
          french: 'Elle est cascadeuse dans des films d\'action.',
          english: 'She is a stunt performer in action movies.',
        ),

        // ── Bizarre & Unusual ────────────────────────────────────────────────
        const SectionTitle('🇧🇪 Professional Life in Belgium'),
        const TranslatedText(
          'In Belgium, the administration of work depends on your region. You should know these key organizations:',
          style: TextStyle(fontSize: 15, height: 1.6, color: Colors.white),
        ),
        const FrenchTipBox(
          title: 'Employment Agencies',
          frenchText: 'Actiris          →  Brussels agency\n'
              'Le Forem         →  Walloon agency\n'
              'VDAB             →  Flemish agency\n'
              'Le CPAS          →  Social assistance\n'
              'Un syndicat      →  A union',
          icon: Icons.account_balance_rounded,
          color: Color(0xFFAB47BC),
        ),
        const ExampleBox(
          french: 'Je suis inscrit chez Actiris pour trouver un job à Bruxelles.',
          english: 'I am registered with Actiris to find a job in Brussels.',
        ),
        const ExampleBox(
          french: 'Il reçoit des allocations via le CPAS.',
          english: 'He receives allowances via the CPAS.',
        ),

        // ── Key phrases ───────────────────────────────────────────────────────
        const SectionTitle('💬 Key Phrases — Talking About Work'),
        const ExampleBox(
          french: 'Qu\'est-ce que vous faites dans la vie ?',
          english: 'What do you do for a living? (formal)',
        ),
        const ExampleBox(
          french: 'Tu fais quoi comme travail ?',
          english: 'What work do you do? (informal)',
        ),
        const ExampleBox(
          french: 'Je suis infirmière dans un hôpital.',
          english: 'I am a nurse in a hospital.',
        ),
        const ExampleBox(
          french: 'Il travaille comme ingénieur chez SWIFT à La Hulpe.',
          english: 'He works as an engineer at SWIFT in La Hulpe.',
        ),
        const ExampleBox(
          french: 'Elle est à son compte — elle est architecte.',
          english: 'She is self-employed — she is an architect.',
        ),
        const ExampleBox(
          french: 'Je cherche un emploi dans la finance.',
          english: 'I am looking for a job in finance.',
        ),
        const ExampleBox(
          french: 'Je suis sans emploi / au chômage en ce moment.',
          english: 'I am unemployed / out of work at the moment.',
        ),

        // ── Useful vocabulary ─────────────────────────────────────────────────
        const SectionTitle('📖 Useful Work Vocabulary'),
        const FrenchTipBox(
          title: 'Work & Employment Words',
          frenchText: 'un emploi / un poste  →  a job / a position\n'
              'un salaire            →  a salary\n'
              'un contrat            →  a contract\n'
              'un collègue           →  a colleague\n'
              'le patron / la patronne →  the boss\n'
              'une réunion           →  a meeting\n'
              'embaucher             →  to hire\n'
              'licencier             →  to fire / lay off\n'
              'démissionner          →  to resign\n'
              'être à la retraite    →  to be retired',
          icon: Icons.work_outline,
          color: Color(0xFF6366F1),
        ),

        // ── Common mistake ────────────────────────────────────────────────────
        const FrenchTipBox(
          title: '⚠️ Common Mistakes to Avoid',
          frenchText:
              '❌  Je suis un avocat.         (don\'t use un/une after être)\n'
              '✅  Je suis avocat.\n\n'
              '❌  Je travaille comme un chef. (don\'t use un/une after comme)\n'
              '✅  Je travaille comme chef.\n\n'
              '❌  Elle est professeur(wrong gender ending in formal French)\n'
              '✅  Elle est professeure.       (modern feminine form)',
          icon: Icons.warning,
          color: Color(0xFFEF4444),
        ),
      ],
    );
  }
}
