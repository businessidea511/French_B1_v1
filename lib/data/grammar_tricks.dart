/// "Easy-peasy" memory cards for each grammar topic: the rule in one line,
/// tricks to remember it, and the classic traps. Explanations are English
/// (shown translated), examples are French.
class MemoryTrick {
  final String title; // the hook, e.g. "The house of être"
  final String trick; // how to remember it
  final List<String> examples; // French

  const MemoryTrick(this.title, this.trick, [this.examples = const []]);

  Map<String, dynamic> toJson() => {'title': title, 'trick': trick, 'examples': examples};

  static MemoryTrick? fromJson(Object? j) {
    if (j is! Map) return null;
    final title = '${j['title'] ?? ''}'.trim();
    final trick = '${j['trick'] ?? ''}'.trim();
    if (title.isEmpty && trick.isEmpty) return null;
    return MemoryTrick(title, trick, [
      for (final e in (j['examples'] as List? ?? const []))
        if ('$e'.trim().isNotEmpty) '$e'.trim(),
    ]);
  }
}

/// A classic mistake: wrong → right, and why.
class GrammarTrap {
  final String wrong; // French
  final String right; // French
  final String why; // English

  const GrammarTrap(this.wrong, this.right, this.why);

  Map<String, dynamic> toJson() => {'wrong': wrong, 'right': right, 'why': why};

  static GrammarTrap? fromJson(Object? j) {
    if (j is! Map) return null;
    final wrong = '${j['wrong'] ?? ''}'.trim();
    final right = '${j['right'] ?? ''}'.trim();
    if (wrong.isEmpty || right.isEmpty) return null;
    return GrammarTrap(wrong, right, '${j['why'] ?? ''}'.trim());
  }
}

class GrammarTricks {
  final String oneLine; // English: the whole topic in one sentence
  final List<MemoryTrick> tricks;
  final List<GrammarTrap> traps;

  const GrammarTricks(this.oneLine, this.tricks, [this.traps = const []]);

  /// Saved inside a grammar topic's content as a widget of this type.
  static const widgetType = 'memory_tricks';

  Map<String, dynamic> toWidget() => {
        'type': widgetType,
        'one_line': oneLine,
        'tricks': [for (final t in tricks) t.toJson()],
        'traps': [for (final t in traps) t.toJson()],
      };

  static GrammarTricks? fromJson(Object? j) {
    if (j is! Map) return null;
    final tricks = [for (final t in (j['tricks'] as List? ?? const [])) MemoryTrick.fromJson(t)].whereType<MemoryTrick>().toList();
    if (tricks.isEmpty) return null;
    return GrammarTricks(
      '${j['one_line'] ?? ''}'.trim(),
      tricks,
      [for (final t in (j['traps'] as List? ?? const [])) GrammarTrap.fromJson(t)].whereType<GrammarTrap>().toList(),
    );
  }

  /// The English texts to translate for everyone.
  List<String> get texts => [
        if (oneLine.isNotEmpty) oneLine,
        for (final t in tricks) ...[t.title, t.trick],
        for (final t in traps)
          if (t.why.isNotEmpty) t.why,
      ];
}

/// Hand-written tricks for the topics of the course. Custom topics are
/// matched by words of their title (their id is random).
const Map<String, GrammarTricks> curatedTricks = {
  'present': GrammarTricks(
    'What happens now, habits and facts. Also for something that started in the past and is still true (with depuis).',
    [
      MemoryTrick(
        '-ER verbs: 4 forms, 1 sound',
        'je parle, tu parles, il parle, ils parlent all sound exactly the same ("parl"). Only nous (-ons) and vous (-ez) sound different. Learn one sound, get four forms.',
        ['je parle · tu parles · il parle · ils parlent', 'nous parlons · vous parlez'],
      ),
      MemoryTrick(
        'The -ONT club has only 4 members',
        'Only four verbs end in -ont with ils/elles: être, avoir, aller, faire. "SOVF": sont, ont, vont, font. Every other verb ends in -ent.',
        ['ils sont · ils ont · ils vont · ils font', 'ils parlent · ils prennent · ils finissent'],
      ),
      MemoryTrick(
        'Vous always -ez… except 3',
        'vous + -ez for every verb except three: vous êtes, vous faites, vous dites.',
        ['vous parlez · vous prenez', 'vous êtes · vous faites · vous dites'],
      ),
      MemoryTrick(
        '-IR / -RE / irregular verbs: S, S, T',
        'For je, tu, il the endings are usually -s, -s, -t. Verbs in -dre keep their d and drop the t.',
        ['je finis · tu finis · il finit', 'je prends · tu prends · il prend'],
      ),
      MemoryTrick(
        '"I have been… for" = présent + depuis',
        'When the action is still going on, French uses the present, not a past tense.',
        ["J'habite à Liège depuis deux ans.", 'Je suis en Belgique depuis mars.'],
      ),
    ],
    [
      GrammarTrap('Je suis habite à Namur.', "J'habite à Namur.", 'Never put être in front of another verb: one verb is enough.'),
      GrammarTrap("J'ai habité ici depuis 2 ans.", "J'habite ici depuis 2 ans.", 'Still true now + depuis → present.'),
      GrammarTrap('Je suis 25 ans.', "J'ai 25 ans.", 'Age uses avoir.'),
    ],
  ),
  'passe_compose': GrammarTricks(
    'A finished action in the past: avoir or être (in the present) + past participle.',
    [
      MemoryTrick(
        'The house of être',
        'Imagine a house: you arrive (arriver), enter (entrer), go up (monter), stay (rester), go down (descendre), go out (sortir), leave (partir), fall (tomber), are born (naître) and die (mourir) there. These movement verbs (+ aller, venir, devenir, revenir, rentrer, retourner) use être. Name to remember: DR & MRS VANDERTRAMP.',
        ['Elle est arrivée à 8 h.', 'Nous sommes allés à Bruges.', 'Ils sont nés en Syrie.'],
      ),
      MemoryTrick(
        'Every "se" verb uses être',
        'All reflexive verbs (se lever, se laver, se promener…) make the passé composé with être.',
        ['Je me suis levé tôt.', 'Elle s\'est promenée au parc.'],
      ),
      MemoryTrick(
        'With être, the participle agrees like an adjective',
        'Add -e for a woman, -s for plural, -es for women. With avoir, no agreement (except a COD placed before).',
        ['Elle est partie.', 'Ils sont venus.', 'Elles sont rentrées.'],
      ),
      MemoryTrick(
        'Participles: -ER → é, -IR → i, -RE → u',
        'parler → parlé, finir → fini, vendre → vendu. The most useful irregulars: eu, été, fait, pris, mis, vu, pu, dû, voulu, venu, dit, écrit, ouvert.',
        ["J'ai pris le train.", "Il a fait ses devoirs.", "Nous avons eu de la chance."],
      ),
      MemoryTrick(
        'The negation sandwich goes around the helper',
        'ne + avoir/être + pas + participle. The participle stays outside the sandwich.',
        ["Je n'ai pas mangé.", "Elle n'est jamais venue."],
      ),
    ],
    [
      GrammarTrap("J'ai allé au marché.", 'Je suis allé(e) au marché.', 'aller is in the house of être.'),
      GrammarTrap('Elle est arrivé.', 'Elle est arrivée.', 'With être, agree with the subject.'),
      GrammarTrap("Je n'ai mangé pas.", "Je n'ai pas mangé.", 'pas goes right after the helper verb.'),
    ],
  ),
  'imparfait': GrammarTricks(
    'The background of the past: descriptions, feelings, habits and actions that were going on.',
    [
      MemoryTrick(
        'nous form − ons + endings',
        'Take the present "nous" form, remove -ons, add -ais, -ais, -ait, -ions, -iez, -aient. Only one exception: être → ét-.',
        ['nous finissons → je finissais', 'nous prenons → je prenais', "être → j'étais"],
      ),
      MemoryTrick(
        'The film trick',
        'Imparfait is the scenery (weather, time, feelings, what was going on). Passé composé is the action that happens on that scene.',
        ['Il pleuvait quand je suis sorti.', 'Je dormais quand le téléphone a sonné.'],
      ),
      MemoryTrick(
        'Habit words call the imparfait',
        "avant, autrefois, d'habitude, souvent, tous les jours, chaque été, quand j'étais petit…",
        ["Quand j'étais petit, je jouais au foot tous les jours."],
      ),
      MemoryTrick(
        'One sound for 4 forms',
        'je parlais, tu parlais, il parlait, ils parlaient all sound "parlè". Only nous and vous are different.',
        ['je parlais · il parlait · ils parlaient'],
      ),
    ],
    [
      GrammarTrap("Quand j'ai été petit, j'ai joué au parc.", "Quand j'étais petit, je jouais au parc.", 'A habit or a description in the past → imparfait.'),
      GrammarTrap('je mangais', 'je mangeais', 'Keep the e of "nous mangeons" so g sounds "j".'),
      GrammarTrap('Hier, nous étudions.', 'Hier, nous étudiions.', 'Verbs in -ier get two i with nous and vous: stem étudi- + -ions.'),
    ],
  ),
  'plus_que_parfait': GrammarTricks(
    'The past before the past: avoir or être in the imparfait + past participle.',
    [
      MemoryTrick(
        'Passé composé with the helper in imparfait',
        "Build the passé composé, then put avoir/être in the imparfait. j'ai → j'avais, je suis → j'étais.",
        ["j'ai mangé → j'avais mangé", "je suis parti → j'étais parti"],
      ),
      MemoryTrick(
        'The timeline trick',
        'Two actions in the past? The one that happened FIRST goes in the plus-que-parfait.',
        ['Quand je suis arrivé, le film avait déjà commencé.'],
      ),
      MemoryTrick(
        'Explaining why in the past',
        'After "parce que" when the cause happened earlier, and with déjà / avant.',
        ["J'étais fatigué parce que j'avais mal dormi."],
      ),
      MemoryTrick(
        'Same être verbs, same agreement',
        'The house of être and the agreements work exactly like in the passé composé.',
        ['Elle était déjà partie.', 'Ils étaient arrivés en retard.'],
      ),
    ],
    [
      GrammarTrap('Quand je suis arrivé, le film a déjà commencé.', 'Quand je suis arrivé, le film avait déjà commencé.', 'The film started before I arrived.'),
      GrammarTrap("J'avais allé…", "J'étais allé(e)…", 'aller uses être.'),
    ],
  ),
  'conditionnel': GrammarTricks(
    'Would / could / should: wishes, polite requests, advice and imaginary situations.',
    [
      MemoryTrick(
        'Future stem + imparfait endings',
        "Same stem as the futur simple (the infinitive or the irregular R-stem), with the imparfait endings -ais, -ais, -ait, -ions, -iez, -aient.",
        ['je parlerais · je finirais · je prendrais', "je serais · j'aurais · j'irais · je ferais · je pourrais · je voudrais"],
      ),
      MemoryTrick(
        'Will or would? Listen for the "s"',
        'je parlerai = I will speak (future). je parlerais = I would speak (conditional).',
        ['Demain, je parlerai au prof.', 'À ta place, je parlerais au prof.'],
      ),
      MemoryTrick(
        'The 3 polite magic words',
        'je voudrais, j\'aimerais, pourriez-vous… make any request polite.',
        ["Je voudrais un café, s'il vous plaît.", 'Pourriez-vous répéter ?'],
      ),
      MemoryTrick(
        'Giving advice',
        'tu devrais… / vous devriez… / à ta place, je…',
        ['Tu devrais dormir plus.', 'À votre place, je prendrais le train.'],
      ),
      MemoryTrick(
        'Si + imparfait → conditionnel',
        'The "si" part NEVER takes the conditional: si + imparfait, then the conditional in the result.',
        ["Si j'avais le temps, je voyagerais."],
      ),
    ],
    [
      GrammarTrap("Si j'aurais de l'argent…", "Si j'avais de l'argent…", 'Never conditional after si.'),
      GrammarTrap('Je voudrai un café.', 'Je voudrais un café.', '"voudrai" is the future (I will want).'),
    ],
  ),
  'negative_complex': GrammarTricks(
    'ne + verb + a second word: pas, plus, jamais, rien, personne, que, aucun.',
    [
      MemoryTrick(
        'Opposite pairs',
        'toujours ↔ ne… jamais · encore ↔ ne… plus · quelque chose ↔ ne… rien · quelqu\'un ↔ ne… personne.',
        ['Je mange toujours ici. → Je ne mange jamais ici.', 'Il fume encore. → Il ne fume plus.'],
      ),
      MemoryTrick(
        'The sandwich and the one that escapes',
        'ne + verb + jamais/rien/plus. In the passé composé the sandwich is around the helper, but PERSONNE goes after the participle.',
        ["Je n'ai rien vu.", "Je n'ai vu personne."],
      ),
      MemoryTrick(
        'ne… que is NOT negative',
        'ne… que = only.',
        ["Je n'ai que dix euros. (= only ten euros)"],
      ),
      MemoryTrick(
        'After a negation: un, une, du, des → de',
        'With quantities, the article becomes de (d\') after the negation. Not with être.',
        ["J'ai un chien. → Je n'ai pas de chien.", "Je bois du café. → Je ne bois pas de café."],
      ),
      MemoryTrick(
        'Rien and personne can start the sentence',
        'Then: Personne / Rien + ne + verb (no pas).',
        ["Personne n'est venu.", "Rien n'est facile."],
      ),
    ],
    [
      GrammarTrap("Je n'ai pas un chien.", "Je n'ai pas de chien.", 'un/une/des → de after a negation.'),
      GrammarTrap("Je n'ai personne vu.", "Je n'ai vu personne.", 'personne goes after the participle.'),
      GrammarTrap('Je ne vois pas rien.', 'Je ne vois rien.', 'One negative word only: rien replaces pas.'),
    ],
  ),
  'futur_proche': GrammarTricks(
    'aller in the present + infinitive: what is going to happen, often soon or planned.',
    [
      MemoryTrick(
        'aller + infinitive, nothing in between',
        'je vais, tu vas, il va, nous allons, vous allez, ils vont + infinitive. No "à".',
        ['Je vais manger.', 'Nous allons partir à 8 h.'],
      ),
      MemoryTrick(
        'Negation around aller',
        'The sandwich goes around the conjugated verb (aller).',
        ['Je ne vais pas sortir ce soir.'],
      ),
      MemoryTrick(
        'Pronouns stick to the infinitive',
        'le, la, lui, y, en, me, se… go just before the infinitive, not before aller.',
        ['Je vais le faire.', 'Je vais me coucher.', 'On va y aller.'],
      ),
      MemoryTrick(
        'Sure and near → futur proche',
        'For a plan or something that will surely happen soon. For far or less sure things, use the futur simple.',
        ['Attention, tu vas tomber !', 'Un jour, je parlerai bien français.'],
      ),
    ],
    [
      GrammarTrap('Je vais à manger.', 'Je vais manger.', 'No preposition between aller and the infinitive.'),
      GrammarTrap('Je le vais faire.', 'Je vais le faire.', 'The pronoun goes before the infinitive.'),
    ],
  ),
  'futur_simple': GrammarTricks(
    'will: infinitive (stem) + -ai, -as, -a, -ons, -ez, -ont.',
    [
      MemoryTrick(
        'The endings are the verb avoir',
        "j'ai, tu as, il a, nous (av)ons, vous (av)ez, ils ont → je parlerai, tu parleras, il parlera, nous parlerons, vous parlerez, ils parleront.",
        ['je parlerai · tu parleras · ils parleront'],
      ),
      MemoryTrick(
        'Stem = the whole infinitive',
        '-ER and -IR verbs keep the infinitive. -RE verbs just drop the final e.',
        ['parler → je parlerai', 'finir → je finirai', 'prendre → je prendrai'],
      ),
      MemoryTrick(
        'Irregular stems always end in R',
        'être → ser-, avoir → aur-, aller → ir-, faire → fer-, venir → viendr-, voir → verr-, pouvoir → pourr-, vouloir → voudr-, devoir → devr-, savoir → saur-, falloir → faudr-, envoyer → enverr-.',
        ['Je serai là.', "J'irai à Gand.", 'Il faudra partir.'],
      ),
      MemoryTrick(
        'Quand + future (unlike English)',
        'If the action is in the future, French uses the future after quand, dès que, lorsque.',
        ['Quand je serai en Belgique, je t\'appellerai.'],
      ),
    ],
    [
      GrammarTrap('Quand je suis grand, je serai médecin.', 'Quand je serai grand, je serai médecin.', 'Future after quand.'),
      GrammarTrap('je prenderai', 'je prendrai', '-RE verbs: just drop the e.'),
    ],
  ),
  'cod_coi': GrammarTricks(
    'Replace a thing or a person to avoid repeating it: le, la, les (COD) · lui, leur (COI) · en · y.',
    [
      MemoryTrick(
        'Ask the verb a question',
        'Verb + who/what directly? → COD: le, la, l\', les. Verb + "à" someone? → COI: lui, leur.',
        ['Je vois Marie. → Je la vois.', 'Je parle à Marie. → Je lui parle.'],
      ),
      MemoryTrick(
        'de, du, de la, des → EN',
        'When the thing comes after de / du / de la / des (or a number or quantity), replace it with EN.',
        ['Je mange du pain. → J\'en mange.', 'Je parle de mon travail. → J\'en parle.', "J'ai deux enfants. → J'en ai deux."],
      ),
      MemoryTrick(
        'à + a place or a thing → Y',
        'à (or another place word: en, chez, dans) + place or thing → Y. But à + a PERSON → lui / leur.',
        ['Je vais à Liège. → J\'y vais.', 'Je pense à mon examen. → J\'y pense.', 'Je parle à Karim. → Je lui parle.'],
      ),
      MemoryTrick(
        'Before the conjugated verb',
        'The pronoun sits just before the verb. With an infinitive (futur proche, pouvoir, vouloir…), before the infinitive.',
        ['Je le vois.', 'Je ne le vois pas.', 'Je vais le voir.'],
      ),
      MemoryTrick(
        'Two pronouns? Follow the queue',
        'me / te / se / nous / vous → le / la / les → lui / leur → y → en. "Il y en a" is the most famous example.',
        ['Je te le donne.', 'Je le lui donne.', 'Il y en a.'],
      ),
      MemoryTrick(
        'COD before avoir → the participle agrees',
        'In the passé composé, if le / la / les comes before avoir, the participle agrees with it.',
        ['Les fleurs ? Je les ai achetées.'],
      ),
    ],
    [
      GrammarTrap('Je la parle.', 'Je lui parle.', 'parler à quelqu\'un → COI.'),
      GrammarTrap('Je lui vais.', "J'y vais.", 'à + a place → y.'),
      GrammarTrap('Je lui aide.', "Je l'aide.", 'In French it is "aider quelqu\'un" (no à) → COD.'),
      GrammarTrap('Je vois le.', 'Je le vois.', 'The pronoun goes before the verb.'),
    ],
  ),
  'si_seulement': GrammarTricks(
    'If only…: si seulement + imparfait (a wish about now) or + plus-que-parfait (a regret about the past).',
    [
      MemoryTrick(
        'A wish about NOW → imparfait',
        'You want the present to be different.',
        ["Si seulement j'avais plus de temps !", 'Si seulement il faisait beau !'],
      ),
      MemoryTrick(
        'A regret about the PAST → plus-que-parfait',
        'You want the past to have been different.',
        ["Si seulement j'avais étudié !", 'Si seulement tu étais venu !'],
      ),
      MemoryTrick(
        'The 3 "si" chains',
        'si + présent → futur · si + imparfait → conditionnel · si + plus-que-parfait → conditionnel passé. Never conditional or future just after si.',
        ["Si j'ai le temps, je viendrai.", "Si j'avais le temps, je viendrais.", "Si j'avais eu le temps, je serais venu."],
      ),
    ],
    [
      GrammarTrap("Si seulement j'aurais su !", "Si seulement j'avais su !", 'Never the conditional after si.'),
      GrammarTrap('si il', "s'il", 'si + il / ils → s\'il, s\'ils (but "si elle" stays).'),
    ],
  ),
  'voix_passive': GrammarTricks(
    'The object becomes the subject: être (in the tense of the active verb) + past participle + par.',
    [
      MemoryTrick(
        'Flip the sentence',
        'Object → subject, être + participle, the old subject comes after par.',
        ['Le chat mange la souris. → La souris est mangée par le chat.'],
      ),
      MemoryTrick(
        'The tense lives in être',
        'Put être in the tense of the active verb; the participle never changes tense.',
        ['est construite (présent)', 'a été construite (passé composé)', 'sera construite (futur)', 'était construite (imparfait)'],
      ),
      MemoryTrick(
        'The participle agrees like an adjective',
        'With the new subject: +e, +s, +es.',
        ['La lettre est écrite par Paul.', 'Les maisons ont été vendues.'],
      ),
      MemoryTrick(
        'par for actions, de for feelings and states',
        'aimé de, respecté de, entouré de, couvert de…',
        ['Il est aimé de tous.', 'La ville est entourée de collines.'],
      ),
      MemoryTrick(
        'In daily French, ON does the job',
        'Instead of a passive without "par", people often use "on".',
        ['Mon vélo a été volé. = On a volé mon vélo.'],
      ),
    ],
    [
      GrammarTrap('La lettre est écrit par Paul.', 'La lettre est écrite par Paul.', 'Agree with the subject (la lettre).'),
      GrammarTrap('La maison a construite en 1990.', 'La maison a été construite en 1990.', 'Passé composé of the passive = a été + participle.'),
    ],
  ),
  'adverbes_ment': GrammarTricks(
    'The FEMININE adjective + -ment = an adverb (like "-ly" in English).',
    [
      MemoryTrick(
        'Feminine + ment',
        'Take the feminine form of the adjective and add -ment.',
        ['lent → lente → lentement', 'heureux → heureuse → heureusement', 'doux → douce → doucement'],
      ),
      MemoryTrick(
        'Ends in a vowel? Masculine + ment',
        'If the masculine adjective ends in a vowel, add -ment directly.',
        ['vrai → vraiment', 'poli → poliment', 'absolu → absolument'],
      ),
      MemoryTrick(
        '-ant → -amment, -ent → -emment',
        'Both sound "-amment". Remove -nt, add -mment.',
        ['courant → couramment', 'évident → évidemment', 'prudent → prudemment'],
      ),
      MemoryTrick(
        'The rebels',
        'bon → bien, mauvais → mal, gentil → gentiment, bref → brièvement.',
        ['Il parle bien français.', 'J\'ai mal dormi.'],
      ),
      MemoryTrick(
        'Place: after the verb',
        'After the conjugated verb. In the passé composé, short adverbs (bien, mal, déjà, vite) go between the helper and the participle.',
        ['Il parle lentement.', "J'ai bien dormi."],
      ),
    ],
    [
      GrammarTrap('lentment', 'lentement', 'Use the feminine: lente + ment.'),
      GrammarTrap('évidamment', 'évidemment', '-ent → -emment (even if it sounds "amment").'),
      GrammarTrap('Il parle bon français.', 'Il parle bien français.', 'bon is an adjective, bien is the adverb.'),
    ],
  ),
  'subjonctif': GrammarTricks(
    'After "que" when you WANT, FEEL, MUST or DOUBT something, and the subject changes.',
    [
      MemoryTrick(
        'Stem = "ils" form − ent',
        'Take ils/elles in the present, remove -ent, add -e, -es, -e, -ions, -iez, -ent. Nous and vous look like the imparfait.',
        ['ils finissent → que je finisse', 'ils prennent → que je prenne', 'que nous prenions · que vous preniez'],
      ),
      MemoryTrick(
        '4 triggers to remember: W.E.I.D.',
        'Wish (vouloir que, souhaiter que) · Emotion (content que, avoir peur que, regretter que) · Impersonal must (il faut que, il est important que) · Doubt (douter que, je ne pense pas que). Plus: pour que, avant que, bien que, à condition que.',
        ['Je veux que tu viennes.', 'Je suis content que tu sois là.', 'Il faut que je parte.'],
      ),
      MemoryTrick(
        'The 7 rebels to learn by heart',
        'être → que je sois · avoir → que j\'aie · aller → que j\'aille · faire → que je fasse · pouvoir → que je puisse · savoir → que je sache · vouloir → que je veuille.',
        ['Il faut que tu sois à l\'heure.', 'Bien qu\'il fasse froid, on sort.'],
      ),
      MemoryTrick(
        'Same person? No que, just the infinitive',
        'Je veux que JE… is impossible. Same subject → infinitive. Different subject → que + subjonctif.',
        ['Je veux partir.', 'Je veux que tu partes.'],
      ),
      MemoryTrick(
        'Sure = no subjonctif',
        'Certainty takes the normal indicative: je pense que, je suis sûr que, espérer que, après que.',
        ["Je pense qu'il vient.", "Je ne pense pas qu'il vienne.", "J'espère qu'il viendra."],
      ),
    ],
    [
      GrammarTrap('Il faut que tu viens.', 'Il faut que tu viennes.', 'il faut que → subjonctif.'),
      GrammarTrap('Je veux que je parte.', 'Je veux partir.', 'Same subject → infinitive.'),
      GrammarTrap("J'espère qu'il vienne.", "J'espère qu'il viendra.", 'espérer = you believe it → indicative.'),
    ],
  ),
  'comparatif': GrammarTricks(
    'plus (+) / moins (−) / aussi (=) + adjective or adverb + que.',
    [
      MemoryTrick(
        '+ − = with adjectives',
        'plus … que (+), moins … que (−), aussi … que (=). The adjective agrees as usual.',
        ['Liège est plus petite que Bruxelles.', 'Le bus est moins rapide que le train.', 'Elle est aussi grande que moi.'],
      ),
      MemoryTrick(
        'Nouns need DE: plus de, moins de, autant de',
        'With a noun, use plus de / moins de / autant de + noun (+ que). "Aussi" never goes with a noun.',
        ["J'ai autant de travail que toi.", 'Il y a moins de monde aujourd\'hui.'],
      ),
      MemoryTrick(
        'Verbs: plus, moins, autant after the verb',
        'verb + plus que / moins que / autant que.',
        ['Il travaille plus que moi.', 'Je dors autant que toi.'],
      ),
      MemoryTrick(
        'bon → meilleur, bien → mieux',
        'Never "plus bon" or "plus bien". meilleur is an adjective (a noun), mieux an adverb (a verb).',
        ['Ce gâteau est meilleur.', 'Elle chante mieux que moi.'],
      ),
      MemoryTrick(
        'After que: moi, toi, lui, elle, nous, vous, eux',
        'Use the strong pronouns after que.',
        ['Il est plus grand que moi.'],
      ),
    ],
    [
      GrammarTrap('Il est plus bon.', 'Il est meilleur.', 'bon → meilleur.'),
      GrammarTrap('plus grand que je', 'plus grand que moi', 'Strong pronoun after que.'),
      GrammarTrap("J'ai aussi de travail que toi.", "J'ai autant de travail que toi.", 'With nouns: autant de.'),
    ],
  ),
  'time_prepositions': GrammarTricks(
    'depuis (still going) · il y a (ago) · pendant (how long) · dans (in … from now) · en (time needed) · pour (planned stay).',
    [
      MemoryTrick(
        'DEPUIS = still true now',
        'It started in the past and is still going on → present tense.',
        ["J'habite à Liège depuis trois ans."],
      ),
      MemoryTrick(
        'IL Y A = ago',
        'A point in the past, finished → passé composé.',
        ['Je suis arrivé il y a trois ans.'],
      ),
      MemoryTrick(
        'PENDANT = a duration with a start and an end',
        'How long it lasted (or will last).',
        ["J'ai étudié pendant deux heures."],
      ),
      MemoryTrick(
        'DANS = from now, in the future',
        'dans + time = in … (from now).',
        ['Je pars dans dix minutes.'],
      ),
      MemoryTrick(
        'EN = the time you needed',
        'en + time = how long it took to do it.',
        ["J'ai fait l'exercice en cinq minutes."],
      ),
      MemoryTrick(
        'POUR = a planned stay',
        'With partir, aller, venir: the time you plan to stay.',
        ['Je pars pour une semaine.'],
      ),
    ],
    [
      GrammarTrap('Je suis ici pendant deux ans.', 'Je suis ici depuis deux ans.', 'Still here → depuis.'),
      GrammarTrap('Je pars en dix minutes.', 'Je pars dans dix minutes.', 'From now → dans.'),
    ],
  ),
  'connectors': GrammarTricks(
    'Little words that link ideas: cause, consequence, opposition, addition, order.',
    [
      MemoryTrick(
        'CAUSE: why?',
        'parce que (answers "pourquoi ?") · car (written) · comme (at the start of the sentence) · grâce à (good result) · à cause de (bad result).',
        ['Comme il pleut, je reste.', 'Grâce à toi, j\'ai réussi.', 'À cause de la grève, je suis en retard.'],
      ),
      MemoryTrick(
        'CONSEQUENCE: so…',
        'donc · alors · c\'est pourquoi · du coup (spoken).',
        ["J'étais malade, donc je suis resté chez moi."],
      ),
      MemoryTrick(
        'OPPOSITION: but…',
        'mais · pourtant · cependant · par contre · bien que + subjonctif · malgré + noun.',
        ["Bien qu'il soit fatigué, il travaille.", 'Malgré la pluie, on sort.'],
      ),
      MemoryTrick(
        'ORDER: the 4 steps',
        "d'abord → ensuite → puis → enfin. To add: de plus, en plus.",
        ["D'abord, je me lève. Ensuite, je prends un café. Enfin, je pars."],
      ),
    ],
    [
      GrammarTrap("Malgré qu'il pleut…", "Bien qu'il pleuve… / Malgré la pluie…", 'malgré + noun; bien que + subjonctif.'),
      GrammarTrap("À cause de toi, j'ai réussi !", "Grâce à toi, j'ai réussi !", 'Good result → grâce à.'),
    ],
  ),
  'imperatif': GrammarTricks(
    'Orders, advice and instructions: the present tense without the subject (tu, nous, vous).',
    [
      MemoryTrick(
        'Present minus the subject',
        'tu prends → Prends ! · nous partons → Partons ! · vous écoutez → Écoutez !',
        ['Prends ton manteau !', 'Partons maintenant !', 'Écoutez bien.'],
      ),
      MemoryTrick(
        '-ER verbs lose their s with tu',
        'tu parles → Parle ! · tu vas → Va ! The s comes back only before y and en: Vas-y !',
        ['Parle plus fort !', 'Mange !', 'Vas-y !'],
      ),
      MemoryTrick(
        'Positive: pronoun after, with a hyphen',
        'In the positive the pronoun goes after the verb (me → moi, te → toi). In the negative it goes back before.',
        ['Donne-moi le livre.', 'Lève-toi !', 'Ne me le donne pas.'],
      ),
      MemoryTrick(
        'The 4 rebels',
        'être → sois, soyons, soyez · avoir → aie, ayons, ayez · savoir → sache, sachons, sachez · vouloir → veuillez (very polite).',
        ['Soyez prudents !', "N'aie pas peur.", 'Veuillez patienter.'],
      ),
    ],
    [
      GrammarTrap('Parles plus fort !', 'Parle plus fort !', '-ER verbs: no s with tu.'),
      GrammarTrap('Me donne le livre.', 'Donne-moi le livre.', 'Positive order: pronoun after the verb.'),
      GrammarTrap('Lève-te !', 'Lève-toi !', 'te → toi after the verb.'),
    ],
  ),
  'discours_indirect': GrammarTricks(
    'Report what someone says: il dit que…, il demande si…, il demande où / ce que…, il dit de + infinitive.',
    [
      MemoryTrick(
        'A sentence → dire que',
        'Remove the quotes, add que, and change the people (je → il/elle, tu → je, mon → son…).',
        ['« Je suis malade. » → Il dit qu\'il est malade.'],
      ),
      MemoryTrick(
        'A yes/no question → demander si',
        'est-ce que and the inversion disappear: just si.',
        ['« Tu viens ? » → Il demande si je viens.', "« Il vient ? » → Elle demande s'il vient."],
      ),
      MemoryTrick(
        'Question words stay',
        'où, quand, comment, pourquoi, qui, combien stay, but the word order becomes normal.',
        ['« Où habites-tu ? » → Il demande où j\'habite.'],
      ),
      MemoryTrick(
        'qu\'est-ce que → ce que, qu\'est-ce qui → ce qui',
        'The "what" questions change.',
        ['« Qu\'est-ce que tu fais ? » → Il demande ce que je fais.', '« Qu\'est-ce qui se passe ? » → Il demande ce qui se passe.'],
      ),
      MemoryTrick(
        'An order → de + infinitive',
        'Imperative → dire / demander de + infinitive.',
        ['« Ferme la porte ! » → Il me dit de fermer la porte.'],
      ),
      MemoryTrick(
        'Present "dit" = no tense change',
        'When the reporting verb is in the present (il dit, il demande), the tenses stay the same.',
        ['« J\'ai fini. » → Il dit qu\'il a fini.'],
      ),
    ],
    [
      GrammarTrap('Il demande est-ce que tu viens.', 'Il demande si tu viens.', 'est-ce que → si.'),
      GrammarTrap("Il demande qu'est-ce que je fais.", 'Il demande ce que je fais.', "qu'est-ce que → ce que."),
      GrammarTrap('Il dit que fermer la porte.', 'Il dit de fermer la porte.', 'An order → de + infinitive.'),
    ],
  ),
  'superlatif': GrammarTricks(
    'The most / the least: le, la, les + plus / moins + adjective (+ de).',
    [
      MemoryTrick(
        'Comparative + article',
        'plus grand → le plus grand. The article agrees: le, la, les.',
        ['C\'est la plus grande ville de Belgique.'],
      ),
      MemoryTrick(
        'After the noun? Say the article twice',
        'Adjectives after the noun repeat the article: la ville la plus belle. Short adjectives before the noun: le plus beau jour.',
        ['le restaurant le plus cher', 'le plus beau jour de ma vie'],
      ),
      MemoryTrick(
        '"in / of" = DE',
        'English "in the world / of the class" → de, du, de la, des. Never dans.',
        ['le plus grand du monde', 'la plus jeune de la classe'],
      ),
      MemoryTrick(
        'The rebels',
        'bon → le meilleur · bien → le mieux · mauvais → le pire (or le plus mauvais).',
        ['C\'est le meilleur restaurant de Namur.', 'C\'est elle qui chante le mieux.'],
      ),
      MemoryTrick(
        'With a verb: le plus / le moins',
        'verb + le plus / le moins (always "le").',
        ["C'est lui qui travaille le plus."],
      ),
    ],
    [
      GrammarTrap('la plus bonne', 'la meilleure', 'bon → meilleur.'),
      GrammarTrap('la ville plus belle', 'la ville la plus belle', 'Repeat the article after the noun.'),
      GrammarTrap('le plus grand dans le monde', 'le plus grand du monde', 'Superlative + de.'),
    ],
  ),
  'temps_recit': GrammarTricks(
    'Now-words (hier, aujourd\'hui, demain) when speaking about now; story-words (la veille, ce jour-là, le lendemain) in a past story or reported speech.',
    [
      MemoryTrick(
        'Where is the reference point?',
        'If the point is TODAY → hier, demain. If the point is a moment in a story → la veille, le lendemain.',
        ['Demain, je pars.', 'Le 3 mai, je suis arrivé. Le lendemain, j\'ai visité Bruges.'],
      ),
      MemoryTrick(
        'The pairs',
        "hier → la veille · aujourd'hui → ce jour-là · demain → le lendemain · maintenant → à ce moment-là · la semaine dernière → la semaine précédente · la semaine prochaine → la semaine suivante · il y a 2 jours → 2 jours avant · dans 2 jours → 2 jours après.",
        ['la veille · ce jour-là · le lendemain'],
      ),
      MemoryTrick(
        'Reported speech in the past changes the time words',
        'What was "demain" for the speaker becomes "le lendemain" when you tell it later.',
        ['Il m\'a dit : « Je pars demain. » → Il m\'a dit qu\'il partait le lendemain.'],
      ),
      MemoryTrick(
        'veille = the day before (Christmas Eve too)',
        'la veille de Noël = Christmas Eve. le lendemain = the day after.',
        ['la veille de l\'examen', 'le lendemain de la fête'],
      ),
    ],
    [
      GrammarTrap("Le 3 mai, je suis arrivé. Demain, j'ai visité Bruges.", "Le 3 mai, je suis arrivé. Le lendemain, j'ai visité Bruges.", 'In a past story, the next day = le lendemain.'),
    ],
  ),
};

/// Custom topics (random ids) recognised by words of their title.
const Map<String, List<String>> _titleKeys = {
  'discours_indirect': ['discours indirect', 'discours rapporte', 'reported speech', 'indirect speech'],
  'superlatif': ['superlatif', 'superlative'],
  'temps_recit': ['lendemain', 'la veille', 'adverbes de temps'],
  'cod_coi': ['cod', 'coi', 'pronoms complements'],
  'subjonctif': ['subjonctif'],
  'comparatif': ['comparatif'],
  'imperatif': ['imperatif'],
  'conditionnel': ['conditionnel'],
  'imparfait': ['imparfait'],
  'plus_que_parfait': ['plus-que-parfait', 'plus que parfait'],
  'passe_compose': ['passe compose'],
  'futur_simple': ['futur simple'],
  'futur_proche': ['futur proche'],
  'voix_passive': ['voix passive', 'passif'],
};

String _plain(String s) {
  const from = 'àâäéèêëîïôöùûüçœ';
  const to = 'aaaeeeeiioouuuco';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i < 0 ? ch : to[i]);
  }
  return b.toString();
}

/// The hand-written tricks for a topic, by id or by its title.
GrammarTricks? curatedTricksFor(String id, String title) {
  final byId = curatedTricks[id];
  if (byId != null) return byId;
  final t = _plain(title);
  for (final e in _titleKeys.entries) {
    if (e.value.any((k) => RegExp('\\b${RegExp.escape(_plain(k))}\\b').hasMatch(t))) return curatedTricks[e.key];
  }
  return null;
}

/// Tricks saved inside a topic's content (made by the AI when the topic was created).
GrammarTricks? embeddedTricks(List<dynamic>? content) {
  for (final w in content ?? const []) {
    if (w is Map && w['type'] == GrammarTricks.widgetType) return GrammarTricks.fromJson(w);
  }
  return null;
}
