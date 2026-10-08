// "Exam writing kit": ready-made phrases that fit any text, a plan for any
// story, a check before handing in, likely exam subjects and dictation
// sentences. French is shown as it is; English is shown translated.

/// A blank in a joker phrase for the "learn by heart" game. The wrong
/// options are the mistakes learners really make.
class PhraseGap {
  final String answer;
  final List<String> wrong;
  final String why; // English
  const PhraseGap(this.answer, this.wrong, this.why);
}

class JokerPhrase {
  final String french;
  final String where; // English: where to put it in a text
  final String grammar; // what it shows the teacher
  final List<PhraseGap> gaps;
  const JokerPhrase(this.french, this.where, this.grammar, this.gaps);

  /// The phrase with [gap] replaced by "___" (first time the answer appears as a word).
  String withBlank(PhraseGap gap) {
    final i = _find(gap.answer);
    return i < 0 ? french : '${french.substring(0, i)}___${french.substring(i + gap.answer.length)}';
  }

  static final _letter = RegExp(r'\p{L}', unicode: true);

  // No look-behind in a pattern: older iPhones (Safari < 16.4) do not support it.
  int _find(String word) {
    for (var i = french.indexOf(word); i >= 0; i = french.indexOf(word, i + 1)) {
      final before = i == 0 ? '' : french[i - 1];
      final end = i + word.length;
      final after = end >= french.length ? '' : french[end];
      if (!_letter.hasMatch(before) && !_letter.hasMatch(after)) return i;
    }
    return -1;
  }
}

const jokerPhrases = [
  JokerPhrase(
    "Je voudrais vous raconter une expérience qui m'a beaucoup marqué(e).",
    'First line of any story, letter or email.',
    'COD (m\') + qui',
    [
      PhraseGap('qui', ['que', 'dont', 'où'], 'qui replaces the subject: the experience marked me.'),
      PhraseGap('raconter', ['raconte', 'racontez', 'raconté'], 'After je voudrais: the infinitive.'),
    ],
  ),
  JokerPhrase(
    "À mon avis, il est important que chacun puisse s'exprimer.",
    'Any opinion or argument. Change the end: …puisse travailler / se soigner / apprendre.',
    'Subjonctif',
    [
      PhraseGap('puisse', ['peut', 'pourra', 'pouvoir'], 'il est important que → subjonctif: que je puisse, que chacun puisse.'),
      PhraseGap('que', ['de', 'qui', 'si'], 'il est important QUE + a new subject.'),
    ],
  ),
  JokerPhrase(
    'Bien que ce soit difficile, je ne regrette rien.',
    'After any problem in your story or text.',
    'Subjonctif (bien que)',
    [
      PhraseGap('soit', ['est', 'sera', 'était'], 'bien que → always the subjonctif: que ce soit.'),
      PhraseGap('rien', ['pas', 'jamais rien', 'personne'], 'ne… rien = nothing (no pas with rien).'),
    ],
  ),
  JokerPhrase(
    "J'en ai parlé à mes amis et ils m'ont conseillé de rester calme.",
    'When you need help, advice or a solution.',
    'EN + COI (m\')',
    [
      PhraseGap('en', ['y', 'le', 'lui'], 'parler DE quelque chose → en.'),
      PhraseGap('de', ['à', 'que', 'pour'], 'conseiller à quelqu\'un DE faire quelque chose.'),
      PhraseGap('parlé', ['parler', 'parlée', 'parlais'], 'Passé composé with avoir: no agreement here.'),
    ],
  ),
  JokerPhrase(
    "D'abord, j'ai eu peur, ensuite j'ai demandé de l'aide, mais finalement tout s'est bien passé.",
    'To organise any text: first, then, but in the end.',
    'Connectors + passé composé',
    [
      PhraseGap('ensuite', ['donc', 'parce que', 'pourtant'], 'd\'abord → ensuite → finalement: the order of events.'),
      PhraseGap('passé', ['passée', 'passer', 'passait'], 'tout s\'est passé: se passer uses être, "tout" is masculine.'),
    ],
  ),
  JokerPhrase(
    "Cette expérience m'a appris qu'il faut que je sois patient(e).",
    'The last line of anything: the lesson you learned.',
    'COI (m\') + subjonctif',
    [
      PhraseGap('sois', ['suis', 'serai', 'être'], 'il faut que → subjonctif: que je sois.'),
      PhraseGap('appris', ['apprend', 'apprendre', 'apprit'], 'm\'a appris: passé composé of apprendre.'),
    ],
  ),
  JokerPhrase(
    'Je suis vraiment content(e) que tu viennes !',
    'Bonus for letters and emails: answer an invitation, welcome someone.',
    'Subjonctif (emotion)',
    [
      PhraseGap('viennes', ['viens', 'viendras', 'venir'], 'content que → subjonctif: que tu viennes.'),
    ],
  ),
];

class StoryStep {
  final String emoji;
  final String title; // English
  final String tense;
  final String example; // French
  const StoryStep(this.emoji, this.title, this.tense, this.example);
}

const storyPlan = [
  StoryStep('📍', 'Where, when, who', 'imparfait', "C'était un samedi, il faisait froid et j'étais à Liège avec ma sœur."),
  StoryStep('⚡', 'Suddenly…', 'passé composé', "Soudain, j'ai perdu mon portefeuille."),
  StoryStep('😟', 'Your feeling', 'subjonctif', "J'avais peur que quelqu'un le prenne."),
  StoryStep('🛠️', 'The solution', 'COD / COI', "Je l'ai cherché partout, puis j'ai téléphoné à la police et je leur ai tout expliqué."),
  StoryStep('🎓', 'The lesson', 'phrase 6', "Cette expérience m'a appris qu'il faut que je sois plus prudent."),
];

/// English, shown translated.
const examChecklist = [
  'Every verb agrees with its subject (je → -e / -s, nous → -ons, ils → -ent).',
  'Passé composé with être: the participle agrees (elle est allée, ils sont partis).',
  'After il faut que, bien que, je veux que, content que: the subjonctif.',
  'Pronouns go before the verb: je le vois, je lui parle, j\'y vais, j\'en ai.',
  'Accents and little words: à / a, où / ou, é / er, ce / se.',
];

/// What the teacher wants to see in the text.
enum ExamFocus { subjonctif, codCoi, both, any }

class ExamSubject {
  final String id;
  final String emoji;
  final String title; // French
  final String instruction; // French, as in an exam
  final ExamFocus focus;
  final int minWords;
  final int maxWords;
  const ExamSubject(this.id, this.emoji, this.title, this.instruction, this.focus, {this.minWords = 80, this.maxWords = 120});

  Map<String, dynamic> toJson() => {
        'id': id,
        'emoji': emoji,
        'title': title,
        'instruction': instruction,
        'focus': focus.name,
        'min': minWords,
        'max': maxWords,
      };

  static ExamSubject? fromJson(Object? j) {
    if (j is! Map) return null;
    final title = '${j['title'] ?? ''}'.trim();
    final instruction = '${j['instruction'] ?? ''}'.trim();
    if (title.isEmpty || instruction.isEmpty) return null;
    return ExamSubject(
      '${j['id'] ?? 'ai_${title.hashCode}'}',
      '${j['emoji'] ?? '📝'}',
      title,
      instruction,
      ExamFocus.values.firstWhere((f) => f.name == j['focus'], orElse: () => ExamFocus.any),
      minWords: (j['min'] as num?)?.toInt() ?? 80,
      maxWords: (j['max'] as num?)?.toInt() ?? 120,
    );
  }
}

const examSubjects = [
  ExamSubject('conseils_ami', '✉️', 'Conseils à un ami',
      "Votre ami arrive en Belgique le mois prochain. Écrivez-lui un e-mail : donnez-lui des conseils pour bien s'installer (logement, commune, transports, cours de français).",
      ExamFocus.both),
  ExamSubject('invitation', '💍', 'Une invitation',
      'Votre amie se marie et vous invite. Répondez-lui : dites que vous êtes content(e), posez des questions et dites ce que vous allez lui offrir.',
      ExamFocus.both),
  ExamSubject('ville_ideale', '🏙️', 'Ma ville idéale',
      'Décrivez la ville idéale pour vous. Qu\'est-ce que vous voudriez qu\'on change dans votre ville ?',
      ExamFocus.subjonctif),
  ExamSubject('regles_coloc', '🏠', 'Les règles de la colocation',
      'Vous partagez un appartement. Écrivez les règles de la colocation pour vos colocataires (ménage, bruit, visites, courses).',
      ExamFocus.subjonctif),
  ExamSubject('telephones', '📱', "Les téléphones à l'école",
      "Faut-il interdire les téléphones à l'école ? Donnez votre opinion avec des arguments et des exemples.",
      ExamFocus.subjonctif),
  ExamSubject('travail_reve', '💼', 'Le travail de mes rêves',
      'Décrivez le travail de vos rêves et ce que vous souhaitez pour votre avenir en Belgique.',
      ExamFocus.subjonctif),
  ExamSubject('cadeau', '🎁', 'Un cadeau',
      'Racontez un cadeau que vous avez offert ou reçu : qu\'est-ce que c\'était, pour qui, et quelle a été la réaction ?',
      ExamFocus.codCoi),
  ExamSubject('objet_perdu', '🔑', 'Un objet perdu',
      "Racontez la fois où vous avez perdu un objet important. Comment l'avez-vous retrouvé ? Qui vous a aidé(e) ?",
      ExamFocus.codCoi),
  ExamSubject('voisin', '🤝', 'Aider un voisin',
      "Racontez comment vous avez aidé un voisin, ou comment quelqu'un vous a aidé(e).",
      ExamFocus.codCoi),
  ExamSubject('famille', '👨‍👩‍👧', 'Ma famille et moi',
      'Parlez de votre famille : vous leur téléphonez souvent ? Qu\'est-ce que vous leur racontez ? Qu\'est-ce qu\'ils vous conseillent ?',
      ExamFocus.codCoi),
  ExamSubject('recette', '🍲', 'Une recette de mon pays',
      'Expliquez à un ami belge comment préparer un plat de votre pays (ingrédients et étapes).',
      ExamFocus.codCoi),
  ExamSubject('premier_jour', '🇧🇪', 'Mon premier jour en Belgique',
      'Racontez votre premier jour en Belgique : où étiez-vous, qu\'est-ce qui s\'est passé, qu\'avez-vous ressenti ?',
      ExamFocus.any),
];

/// Dictation sentences with the exam grammar (no "?" in the middle: the
/// dictation compares word by word).
const examDictation = [
  // Subjonctif
  'Il faut que tu prennes le bus de huit heures.',
  'Je suis contente que vous soyez là.',
  "Bien qu'il pleuve, nous allons au marché.",
  'Ma mère veut que je fasse mes devoirs.',
  'Il est important que chacun puisse parler.',
  "Je ne pense pas qu'il vienne ce soir.",
  'Il faut que nous allions à la commune.',
  "J'ai peur que le train soit en retard.",
  'Le professeur souhaite que nous lisions ce livre.',
  'Avant que tu partes, ferme la fenêtre.',
  // COD / COI / en / y
  'Je lui ai donné mon numéro de téléphone.',
  'Les clés, je les ai oubliées à la maison.',
  'Nous leur avons expliqué le problème.',
  'Je connais Sofia, je la vois tous les jours.',
  "Des pommes, j'en achète au marché le samedi.",
  "Liège, j'y vais demain avec mes amis.",
  "Elle m'a envoyé un message hier soir.",
  'Je vais lui téléphoner après le cours.',
  'Ce livre, je te le prête jusqu\'à lundi.',
  'Mes parents, je leur parle tous les jours.',
];

/// Today's dictation: 6 sentences that change every day (2 subjonctif,
/// 2 COD/COI, 2 joker phrases), the same for everyone on the same day.
List<String> dailyDictation(DateTime day) {
  final seed = day.year * 1000 + day.month * 40 + day.day;
  List<T> pick<T>(List<T> list, int n, int salt) {
    final picked = <T>[];
    var i = (seed * 7 + salt) % list.length;
    while (picked.length < n) {
      final item = list[i % list.length];
      if (!picked.contains(item)) picked.add(item);
      i += 3;
    }
    return picked;
  }

  return [
    ...pick(examDictation.sublist(0, 10), 2, 1),
    ...pick(examDictation.sublist(10), 2, 5),
    // Phrases with "(e)" are not dictated.
    ...pick([for (final p in jokerPhrases) if (!p.french.contains('(')) p.french], 2, 9),
  ];
}

/// The English texts of the kit, translated once for everyone ("Translate everything now").
List<String> get examKitTexts => [
      for (final p in jokerPhrases) ...[p.where, for (final g in p.gaps) g.why],
      for (final s in storyPlan) s.title,
      ...examChecklist,
    ];
