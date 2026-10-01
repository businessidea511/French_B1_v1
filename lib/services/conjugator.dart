// French verb conjugation by rule, for every mood and tense.
//
// Regular verbs follow their group (-er, -ir like finir, -re like vendre),
// including the -er spelling changes (commencer, manger, lever, préférer,
// appeler, payer). Irregular verbs are described by their principal parts in
// [_irregular]; a prefixed verb (devenir, comprendre, découvrir…) uses the
// pattern of the verb it ends with.

class VerbTense {
  final String mood;
  final String name;
  final List<String> forms;

  /// Only for the non-personal forms (participe, gérondif…): the label of each form.
  final List<String>? labels;

  const VerbTense(this.mood, this.name, this.forms, {this.labels});
}

class VerbTable {
  final String infinitive;
  final String auxiliary; // avoir | être
  final String group;
  final List<String> notes;
  final List<VerbTense> tenses;

  const VerbTable({
    required this.infinitive,
    required this.auxiliary,
    required this.group,
    required this.notes,
    required this.tenses,
  });

  VerbTense? find(String mood, String name) {
    for (final t in tenses) {
      if (t.mood == mood && t.name == name) return t;
    }
    return null;
  }
}

/// Principal parts of an irregular verb, as endings added after the root
/// (the part of the infinitive before the pattern). '-' marks a missing form.
class _Irr {
  final String pres; // 6 forms separated by |
  final String fut;
  final String pp;
  final String ps; // passé simple stem ('' = none)
  final String? subj; // "stem1|stem2" or 6 forms
  final String? imp;
  final String? ppr;
  final String? impv; // "tu|nous|vous", or 'none'
  final bool psA; // passé simple in -a (aller)
  final bool impersonal;

  const _Irr(this.pres, this.fut, this.pp, this.ps,
      {this.subj, this.imp, this.ppr, this.impv, this.psA = false, this.impersonal = false});
}

class _Parts {
  final List<String> pres;
  final String imp;
  final String fut;
  final String pp;
  final List<String> subj;
  final String ps;
  final bool psA;
  final String ppr;
  final List<String>? impv;
  final bool impersonal;
  final String Function(String stem, String ending) join;

  _Parts({
    required this.pres,
    required this.imp,
    required this.fut,
    required this.pp,
    required this.subj,
    required this.ps,
    required this.psA,
    required this.ppr,
    required this.impv,
    required this.join,
    this.impersonal = false,
  });
}

class Conjugator {
  static const persons = ['je', 'tu', 'il/elle', 'nous', 'vous', 'ils/elles'];
  static const _reflexive = ['me', 'te', 'se', 'nous', 'vous', 'se'];

  static const moods = ['Indicatif', 'Subjonctif', 'Conditionnel', 'Impératif', 'Participe & infinitif'];

  // Mood → its tenses, in the order they are shown.
  static const tensesByMood = {
    'Indicatif': [
      'Présent', 'Passé composé', 'Imparfait', 'Plus-que-parfait', 'Futur simple',
      'Futur proche', 'Passé récent', 'Futur antérieur', 'Passé simple', 'Passé antérieur',
    ],
    'Subjonctif': ['Présent', 'Passé', 'Imparfait', 'Plus-que-parfait'],
    'Conditionnel': ['Présent', 'Passé'],
    'Impératif': ['Présent', 'Passé'],
    'Participe & infinitif': ['Formes'],
  };

  /// Verbs conjugated with être (besides all pronominal verbs).
  static const _etreVerbs = {
    'aller', 'venir', 'devenir', 'revenir', 'parvenir', 'intervenir', 'survenir', 'provenir',
    'arriver', 'partir', 'repartir', 'sortir', 'ressortir', 'entrer', 'rentrer', 'rester',
    'tomber', 'retomber', 'naître', 'renaître', 'mourir', 'décéder', 'monter', 'remonter',
    'descendre', 'redescendre', 'retourner', 'advenir',
  };

  /// être verbs that take avoir when they have a direct object.
  static const _bothAux = {'monter', 'descendre', 'sortir', 'rentrer', 'retourner', 'passer', 'remonter', 'redescendre', 'ressortir'};

  static const _aspiratedH = {
    'hurler', 'heurter', 'hacher', 'hanter', 'harceler', 'hausser', 'hisser', 'huer', 'hâter', 'hasarder', 'haïr', 'héler', 'hennir',
  };

  /// -eler / -eter verbs that double the consonant (j'appelle, je jette).
  static const _doubling = {
    'appeler', 'rappeler', 'épeler', 'renouveler', 'jeter', 'rejeter', 'projeter', 'feuilleter',
    'étinceler', 'ruisseler', 'ficeler', 'épousseter', 'interjeter', 'cacheter',
  };

  static const Map<String, _Irr> _irregular = {
    'être': _Irr('suis|es|est|sommes|êtes|sont', 'ser', 'été', 'fu',
        subj: 'sois|sois|soit|soyons|soyez|soient', imp: 'ét', ppr: 'étant', impv: 'sois|soyons|soyez'),
    'avoir': _Irr('ai|as|a|avons|avez|ont', 'aur', 'eu', 'eu',
        subj: 'aie|aies|ait|ayons|ayez|aient', ppr: 'ayant', impv: 'aie|ayons|ayez'),
    'aller': _Irr('vais|vas|va|allons|allez|vont', 'ir', 'allé', 'all', subj: 'aill|all', psA: true),
    'faire': _Irr('fais|fais|fait|faisons|faites|font', 'fer', 'fait', 'fi', subj: 'fass|fass'),
    'vouloir': _Irr('veux|veux|veut|voulons|voulez|veulent', 'voudr', 'voulu', 'voulu',
        subj: 'veuill|voul', impv: 'veuille|veuillons|veuillez'),
    'pouvoir': _Irr('peux|peux|peut|pouvons|pouvez|peuvent', 'pourr', 'pu', 'pu', subj: 'puiss|puiss', impv: 'none'),
    'devoir': _Irr('dois|dois|doit|devons|devez|doivent', 'devr', 'dû', 'du'),
    'savoir': _Irr('sais|sais|sait|savons|savez|savent', 'saur', 'su', 'su',
        subj: 'sach|sach', ppr: 'sachant', impv: 'sache|sachons|sachez'),
    'valoir': _Irr('vaux|vaux|vaut|valons|valez|valent', 'vaudr', 'valu', 'valu', subj: 'vaill|val'),
    'falloir': _Irr('-|-|faut|-|-|-', 'faudr', 'fallu', 'fallu',
        subj: '-|-|faille|-|-|-', imp: 'fall', ppr: '-', impv: 'none', impersonal: true),
    'pleuvoir': _Irr('-|-|pleut|-|-|-', 'pleuvr', 'plu', 'plu',
        subj: '-|-|pleuve|-|-|-', imp: 'pleuv', ppr: 'pleuvant', impv: 'none', impersonal: true),
    'venir': _Irr('viens|viens|vient|venons|venez|viennent', 'viendr', 'venu', 'vin'),
    'tenir': _Irr('tiens|tiens|tient|tenons|tenez|tiennent', 'tiendr', 'tenu', 'tin'),
    'dire': _Irr('dis|dis|dit|disons|dites|disent', 'dir', 'dit', 'di'),
    'interdire': _Irr('interdis|interdis|interdit|interdisons|interdisez|interdisent', 'interdir', 'interdit', 'interdi'),
    'prédire': _Irr('prédis|prédis|prédit|prédisons|prédisez|prédisent', 'prédir', 'prédit', 'prédi'),
    'contredire': _Irr('contredis|contredis|contredit|contredisons|contredisez|contredisent', 'contredir', 'contredit', 'contredi'),
    'prendre': _Irr('prends|prends|prend|prenons|prenez|prennent', 'prendr', 'pris', 'pri'),
    'voir': _Irr('vois|vois|voit|voyons|voyez|voient', 'verr', 'vu', 'vi'),
    'prévoir': _Irr('prévois|prévois|prévoit|prévoyons|prévoyez|prévoient', 'prévoir', 'prévu', 'prévi'),
    'croire': _Irr('crois|crois|croit|croyons|croyez|croient', 'croir', 'cru', 'cru'),
    'mettre': _Irr('mets|mets|met|mettons|mettez|mettent', 'mettr', 'mis', 'mi'),
    'battre': _Irr('bats|bats|bat|battons|battez|battent', 'battr', 'battu', 'batti'),
    'partir': _Irr('pars|pars|part|partons|partez|partent', 'partir', 'parti', 'parti'),
    'sortir': _Irr('sors|sors|sort|sortons|sortez|sortent', 'sortir', 'sorti', 'sorti'),
    'sentir': _Irr('sens|sens|sent|sentons|sentez|sentent', 'sentir', 'senti', 'senti'),
    'mentir': _Irr('mens|mens|ment|mentons|mentez|mentent', 'mentir', 'menti', 'menti'),
    'dormir': _Irr('dors|dors|dort|dormons|dormez|dorment', 'dormir', 'dormi', 'dormi'),
    'servir': _Irr('sers|sers|sert|servons|servez|servent', 'servir', 'servi', 'servi'),
    'courir': _Irr('cours|cours|court|courons|courez|courent', 'courr', 'couru', 'couru'),
    'mourir': _Irr('meurs|meurs|meurt|mourons|mourez|meurent', 'mourr', 'mort', 'mouru'),
    'ouvrir': _Irr('ouvre|ouvres|ouvre|ouvrons|ouvrez|ouvrent', 'ouvrir', 'ouvert', 'ouvri'),
    'ffrir': _Irr('ffre|ffres|ffre|ffrons|ffrez|ffrent', 'ffrir', 'ffert', 'ffri'),
    'cueillir': _Irr('cueille|cueilles|cueille|cueillons|cueillez|cueillent', 'cueiller', 'cueilli', 'cueilli'),
    'quérir': _Irr('quiers|quiers|quiert|quérons|quérez|quièrent', 'querr', 'quis', 'qui'),
    'fuir': _Irr('fuis|fuis|fuit|fuyons|fuyez|fuient', 'fuir', 'fui', 'fui'),
    'naître': _Irr('nais|nais|naît|naissons|naissez|naissent', 'naîtr', 'né', 'naqui'),
    'renaître': _Irr('renais|renais|renaît|renaissons|renaissez|renaissent', 'renaîtr', 'rené', 'renaqui'),
    'aître': _Irr('ais|ais|aît|aissons|aissez|aissent', 'aîtr', 'u', 'u'),
    'lire': _Irr('lis|lis|lit|lisons|lisez|lisent', 'lir', 'lu', 'lu'),
    'crire': _Irr('cris|cris|crit|crivons|crivez|crivent', 'crir', 'crit', 'crivi'),
    'rire': _Irr('ris|ris|rit|rions|riez|rient', 'rir', 'ri', 'ri'),
    'suffire': _Irr('suffis|suffis|suffit|suffisons|suffisez|suffisent', 'suffir', 'suffi', 'suffi'),
    'vivre': _Irr('vis|vis|vit|vivons|vivez|vivent', 'vivr', 'vécu', 'vécu'),
    'suivre': _Irr('suis|suis|suit|suivons|suivez|suivent', 'suivr', 'suivi', 'suivi'),
    'boire': _Irr('bois|bois|boit|buvons|buvez|boivent', 'boir', 'bu', 'bu'),
    'plaire': _Irr('plais|plais|plaît|plaisons|plaisez|plaisent', 'plair', 'plu', 'plu'),
    'taire': _Irr('tais|tais|tait|taisons|taisez|taisent', 'tair', 'tu', 'tu'),
    'traire': _Irr('trais|trais|trait|trayons|trayez|traient', 'trair', 'trait', ''),
    'uire': _Irr('uis|uis|uit|uisons|uisez|uisent', 'uir', 'uit', 'uisi'),
    'nuire': _Irr('nuis|nuis|nuit|nuisons|nuisez|nuisent', 'nuir', 'nui', 'nuisi'),
    'aindre': _Irr('ains|ains|aint|aignons|aignez|aignent', 'aindr', 'aint', 'aigni'),
    'eindre': _Irr('eins|eins|eint|eignons|eignez|eignent', 'eindr', 'eint', 'eigni'),
    'oindre': _Irr('oins|oins|oint|oignons|oignez|oignent', 'oindr', 'oint', 'oigni'),
    'cevoir': _Irr('çois|çois|çoit|cevons|cevez|çoivent', 'cevr', 'çu', 'çu'),
    'asseoir': _Irr('assieds|assieds|assied|asseyons|asseyez|asseyent', 'assiér', 'assis', 'assi'),
    'rompre': _Irr('romps|romps|rompt|rompons|rompez|rompent', 'rompr', 'rompu', 'rompi'),
    'vaincre': _Irr('vaincs|vaincs|vainc|vainquons|vainquez|vainquent', 'vaincr', 'vaincu', 'vainqui'),
    'moudre': _Irr('mouds|mouds|moud|moulons|moulez|moulent', 'moudr', 'moulu', 'moulu'),
    'coudre': _Irr('couds|couds|coud|cousons|cousez|cousent', 'coudr', 'cousu', 'cousi'),
    'clore': _Irr('clos|clos|clôt|closons|closez|closent', 'clor', 'clos', ''),
    'clure': _Irr('clus|clus|clut|cluons|cluez|cluent', 'clur', 'clu', 'clu'),
    'inclure': _Irr('inclus|inclus|inclut|incluons|incluez|incluent', 'inclur', 'inclus', 'inclu'),
    'résoudre': _Irr('résous|résous|résout|résolvons|résolvez|résolvent', 'résoudr', 'résolu', 'résolu'),
    'absoudre': _Irr('absous|absous|absout|absolvons|absolvez|absolvent', 'absoudr', 'absous', ''),
    'dissoudre': _Irr('dissous|dissous|dissout|dissolvons|dissolvez|dissolvent', 'dissoudr', 'dissous', ''),
  };

  /// Patterns that only match the whole verb (aller must not match installer).
  static const _exactOnly = {'être', 'avoir', 'aller', 'naître', 'devoir', 'pouvoir', 'savoir', 'vouloir'};

  /// Conjugates [input] ("parler", "se lever", "s'appeler"). Returns null when
  /// it is not a French infinitive the rules can handle.
  static VerbTable? conjugate(String input) {
    var verb = input.trim().toLowerCase().replaceAll('’', "'").replaceAll(RegExp(r'\s+'), ' ');
    var pronominal = false;
    if (verb.startsWith('se ')) {
      pronominal = true;
      verb = verb.substring(3);
    } else if (verb.startsWith("s'")) {
      pronominal = true;
      verb = verb.substring(2).trim();
    }
    if (!RegExp(r"^[a-zàâäçéèêëîïôöùûüœ\-]+$").hasMatch(verb)) return null;

    final notes = <String>[];
    final built = _build(verb, notes);
    if (built == null) return null;
    final (parts, group) = built;

    final aux = pronominal || _etreVerbs.contains(verb) ? 'être' : 'avoir';
    if (!pronominal && _bothAux.contains(verb)) {
      notes.add(aux == 'être'
          ? 'Uses être, but avoir when it has a direct object: « J\'ai ${verb == 'monter' ? 'monté les valises' : verb == 'descendre' ? 'descendu la poubelle' : verb == 'sortir' ? 'sorti le chien' : '${parts.pp} les clés'} ».'
          : 'Uses avoir, but être when it means "to pass by / through": « Je suis passé(e) chez toi. »');
    }
    if (parts.impersonal) notes.add('Impersonal verb: only used with « il ».');
    if (parts.ps.isEmpty) notes.add('This verb has no passé simple (and no subjonctif imparfait).');

    return VerbTable(
      infinitive: pronominal ? _reflexiveInfinitive(verb) : verb,
      auxiliary: aux,
      group: group,
      notes: notes,
      tenses: _tenses(verb, parts, aux, pronominal),
    );
  }

  // ── Principal parts ────────────────────────────────────────────────────────

  static (_Parts, String)? _build(String verb, List<String> notes) {
    // Longest matching irregular pattern wins (devenir → venir, comprendre → prendre).
    String? key;
    for (final k in _irregular.keys) {
      if (_exactOnly.contains(k) ? verb == k : verb.endsWith(k)) {
        if (key == null || k.length > key.length) key = k;
      }
    }
    if (key != null) {
      return (_fromIrregular(verb.substring(0, verb.length - key.length), _irregular[key]!), '3e groupe (irregular)');
    }
    if (verb.endsWith('er') && verb.length > 2) return (_er(verb, notes), '1er groupe (-er, regular)');
    if (verb.endsWith('ir') && !verb.endsWith('oir') && verb.length > 2) return (_ir(verb), '2e groupe (-ir like finir)');
    if (verb.endsWith('re') && verb.length > 3) return (_re(verb), '3e groupe (-re like vendre)');
    return null;
  }

  static String _je(String form) => _startsWithVowel(form) ? "j'$form" : 'je $form';

  static String _plainJoin(String stem, String ending) => stem + ending;

  static _Parts _fromIrregular(String root, _Irr d) {
    List<String> six(String s) => s.split('|').map((f) => f == '-' ? '' : root + f).toList();
    final pres = six(d.pres);
    String ending(String form, String e) => form.endsWith(e) ? form.substring(0, form.length - e.length) : form;
    final nousStem = d.imp != null ? root + d.imp! : ending(pres[3], 'ons');
    List<String> subj;
    if (d.subj != null && d.subj!.split('|').length == 6) {
      subj = six(d.subj!);
    } else {
      final stems = d.subj?.split('|');
      final s1 = stems != null ? root + stems[0] : ending(pres[5], 'ent');
      final s2 = stems != null ? root + stems[1] : nousStem;
      subj = ['${s1}e', '${s1}es', '${s1}e', '${s2}ions', '${s2}iez', '${s1}ent'];
    }
    List<String>? impv;
    if (d.impv == 'none' || d.impersonal) {
      impv = null;
    } else if (d.impv != null) {
      impv = d.impv!.split('|').map((f) => root + f).toList();
    } else {
      var tu = pres[1];
      if (tu.endsWith('es') || tu.endsWith('vas')) tu = tu.substring(0, tu.length - 1);
      impv = [tu, pres[3], pres[4]];
    }
    final ppr = d.ppr == '-' ? '' : (d.ppr != null ? root + d.ppr! : '${nousStem}ant');
    return _Parts(
      pres: pres,
      imp: nousStem,
      fut: root + d.fut,
      pp: root + d.pp,
      subj: subj,
      ps: d.ps.isEmpty ? '' : root + d.ps,
      psA: d.psA,
      ppr: ppr,
      impv: impv,
      impersonal: d.impersonal,
      join: _plainJoin,
    );
  }

  static final _eChange = RegExp(r'e(ch|gn|[bcdfgptv][rl]|[bcdfghjklmnpqrstvz])$');
  static final _acuteChange = RegExp(r'é(ch|gn|[bcdfgptv][rl]|[bcdfghjklmnpqrstvz])$');

  static _Parts _er(String verb, List<String> notes) {
    final weak = verb.substring(0, verb.length - 2);
    var strong = weak;
    var futStem = '${weak}er';

    String join(String stem, String ending) {
      final soft = ending.isNotEmpty && 'aâoô'.contains(ending[0]);
      if (verb.endsWith('cer') && stem.endsWith('c') && soft) return '${stem.substring(0, stem.length - 1)}ç$ending';
      if (verb.endsWith('ger') && stem.endsWith('g') && soft) return '${stem}e$ending';
      return stem + ending;
    }


    if (_doubling.contains(verb)) {
      strong = weak + weak[weak.length - 1];
      futStem = '${strong}er';
      notes.add('Spelling: the consonant doubles before a silent e: ${_je('${strong}e')}, but nous ${join(weak, 'ons')}.');
    } else if (weak.endsWith('y') && !weak.endsWith('ey')) {
      strong = '${weak.substring(0, weak.length - 1)}i';
      futStem = verb == 'envoyer' ? 'enverr' : verb == 'renvoyer' ? 'renverr' : '${strong}er';
      notes.add('Spelling: y becomes i before a silent e: ${_je('${strong}e')}, but nous ${join(weak, 'ons')}.');
    } else if (_eChange.hasMatch(weak)) {
      final m = _eChange.firstMatch(weak)!;
      strong = '${weak.substring(0, m.start)}è${weak.substring(m.start + 1)}';
      futStem = '${strong}er';
      notes.add('Spelling: e becomes è before a silent e: ${_je('${strong}e')}, but nous ${join(weak, 'ons')}.');
    } else if (_acuteChange.hasMatch(weak)) {
      final m = _acuteChange.firstMatch(weak)!;
      strong = '${weak.substring(0, m.start)}è${weak.substring(m.start + 1)}';
      notes.add('Spelling: é becomes è before a silent ending: ${_je('${strong}e')}, but nous ${join(weak, 'ons')} and ${_je('${weak}erai')}.');
    }

    if (verb.endsWith('cer')) notes.add('Spelling: c becomes ç before a and o to keep the "s" sound: nous ${join(weak, 'ons')}.');
    if (verb.endsWith('ger')) notes.add('Spelling: add e before a and o to keep the soft g: nous ${join(weak, 'ons')}.');

    return _Parts(
      pres: [
        '${strong}e', '${strong}es', '${strong}e', join(weak, 'ons'), '${weak}ez', '${strong}ent',
      ],
      imp: weak,
      fut: futStem,
      pp: '$weaké',
      subj: ['${strong}e', '${strong}es', '${strong}e', '${weak}ions', '${weak}iez', '${strong}ent'],
      ps: weak,
      psA: true,
      ppr: join(weak, 'ant'),
      impv: ['${strong}e', join(weak, 'ons'), '${weak}ez'],
      join: join,
    );
  }

  static _Parts _ir(String verb) {
    final s = verb.substring(0, verb.length - 2);
    return _Parts(
      pres: ['${s}is', '${s}is', '${s}it', '${s}issons', '${s}issez', '${s}issent'],
      imp: '${s}iss',
      fut: verb,
      pp: '${s}i',
      subj: ['${s}isse', '${s}isses', '${s}isse', '${s}issions', '${s}issiez', '${s}issent'],
      ps: '${s}i',
      psA: false,
      ppr: '${s}issant',
      impv: ['${s}is', '${s}issons', '${s}issez'],
      join: _plainJoin,
    );
  }

  static _Parts _re(String verb) {
    final s = verb.substring(0, verb.length - 2);
    final third = s.endsWith('d') || s.endsWith('t') ? s : '${s}t';
    return _Parts(
      pres: ['${s}s', '${s}s', third, '${s}ons', '${s}ez', '${s}ent'],
      imp: s,
      fut: '${s}r',
      pp: '${s}u',
      subj: ['${s}e', '${s}es', '${s}e', '${s}ions', '${s}iez', '${s}ent'],
      ps: '${s}i',
      psA: false,
      ppr: '${s}ant',
      impv: ['${s}s', '${s}ons', '${s}ez'],
      join: _plainJoin,
    );
  }

  // ── Simple tenses (forms without subject) ─────────────────────────────────

  static String _circ(String stem) {
    const plain = 'aeiou', hat = 'âêîôû';
    for (var i = stem.length - 1; i >= 0; i--) {
      final k = plain.indexOf(stem[i]);
      if (k >= 0) return stem.substring(0, i) + hat[k] + stem.substring(i + 1);
    }
    return stem;
  }

  static List<String> _simple(_Parts p, String tense) {
    switch (tense) {
      case 'pres':
        return p.pres;
      case 'imp':
        return [for (final e in ['ais', 'ais', 'ait', 'ions', 'iez', 'aient']) p.join(p.imp, e)];
      case 'fut':
        return [for (final e in ['ai', 'as', 'a', 'ons', 'ez', 'ont']) p.fut + e];
      case 'cond':
        return [for (final e in ['ais', 'ais', 'ait', 'ions', 'iez', 'aient']) p.fut + e];
      case 'subj':
        return p.subj;
      case 'ps':
        if (p.ps.isEmpty) return List.filled(6, '');
        if (p.psA) return [for (final e in ['ai', 'as', 'a', 'âmes', 'âtes', 'èrent']) p.join(p.ps, e)];
        return ['${p.ps}s', '${p.ps}s', '${p.ps}t', '${_circ(p.ps)}mes', '${_circ(p.ps)}tes', '${p.ps}rent'];
      case 'subjImp':
        if (p.ps.isEmpty) return List.filled(6, '');
        if (p.psA) return [for (final e in ['asse', 'asses', 'ât', 'assions', 'assiez', 'assent']) p.join(p.ps, e)];
        return ['${p.ps}sse', '${p.ps}sses', '${_circ(p.ps)}t', '${p.ps}ssions', '${p.ps}ssiez', '${p.ps}ssent'];
    }
    throw ArgumentError(tense);
  }


  // ── Assembling the tenses ─────────────────────────────────────────────────

  static bool _startsWithVowel(String word, {bool hAspirated = false}) {
    if (word.isEmpty) return false;
    if (word.startsWith('h')) return !hAspirated;
    return 'aeiouyàâäéèêëîïôöùûüœ'.contains(word[0]);
  }

  static String _reflexiveInfinitive(String verb) =>
      _startsWithVowel(verb, hAspirated: _aspiratedH.contains(verb)) ? "s'$verb" : 'se $verb';

  static List<VerbTense> _tenses(String verb, _Parts p, String aux, bool pronominal) {
    final hAsp = _aspiratedH.contains(verb);
    final auxParts = _fromIrregular('', _irregular[aux]!);
    final agree = aux == 'être';
    final ppS = p.pp.endsWith('s');
    String ppFor(int i) {
      if (!agree) return p.pp;
      if (i < 3) return '${p.pp}(e)';
      if (i == 4) return '${p.pp}(e)${ppS ? '' : '(s)'}';
      return '${p.pp}${ppS ? '(es)' : '(e)s'}';
    }

    String refl(int i, String next) {
      if (!pronominal) return next;
      if (i != 3 && i != 4 && _startsWithVowel(next, hAspirated: hAsp && next.startsWith('h'))) {
        return "${_reflexive[i][0]}'$next";
      }
      return '${_reflexive[i]} $next';
    }

    String subject(int i, String rest, {bool que = false}) {
      final pron = p.impersonal ? 'il' : persons[i];
      final s = i == 0 && _startsWithVowel(rest, hAspirated: hAsp && rest.startsWith('h')) ? "j'$rest" : '$pron $rest';
      if (!que) return s;
      return s.startsWith('il') ? "qu'$s" : 'que $s';
    }

    List<int> people() => p.impersonal ? [2] : [0, 1, 2, 3, 4, 5];

    List<String> simple(String tense, {bool que = false}) {
      final forms = _simple(p, tense);
      return [
        for (final i in people())
          if (forms[i].isNotEmpty) subject(i, refl(i, forms[i]), que: que)
      ];
    }

    List<String> compound(String auxTense, {bool que = false}) {
      final auxForms = _simple(auxParts, auxTense);
      return [for (final i in people()) subject(i, refl(i, '${auxForms[i]} ${ppFor(i)}'), que: que)];
    }

    final infinitive = pronominal ? _reflexiveInfinitive(verb) : verb;
    String inf(int i) => pronominal ? refl(i, verb) : verb;

    final aller = _fromIrregular('', _irregular['aller']!).pres;
    final venir = _fromIrregular('', _irregular['venir']!).pres;

    final hasPs = p.ps.isNotEmpty;
    final tenses = <VerbTense>[
      VerbTense('Indicatif', 'Présent', simple('pres')),
      VerbTense('Indicatif', 'Passé composé', compound('pres')),
      VerbTense('Indicatif', 'Imparfait', simple('imp')),
      VerbTense('Indicatif', 'Plus-que-parfait', compound('imp')),
      VerbTense('Indicatif', 'Futur simple', simple('fut')),
      VerbTense('Indicatif', 'Futur proche', [for (final i in people()) subject(i, '${aller[i]} ${inf(i)}')]),
      VerbTense('Indicatif', 'Passé récent', [
        for (final i in people())
          subject(i, '${venir[i]} ${_startsWithVowel(inf(i), hAspirated: hAsp) ? "d'${inf(i)}" : 'de ${inf(i)}'}')
      ]),
      VerbTense('Indicatif', 'Futur antérieur', compound('fut')),
      if (hasPs) VerbTense('Indicatif', 'Passé simple', simple('ps')),
      if (hasPs) VerbTense('Indicatif', 'Passé antérieur', compound('ps')),
      VerbTense('Subjonctif', 'Présent', simple('subj', que: true)),
      VerbTense('Subjonctif', 'Passé', compound('subj', que: true)),
      if (hasPs) VerbTense('Subjonctif', 'Imparfait', simple('subjImp', que: true)),
      VerbTense('Subjonctif', 'Plus-que-parfait', compound('subjImp', que: true)),
      VerbTense('Conditionnel', 'Présent', simple('cond')),
      VerbTense('Conditionnel', 'Passé', compound('cond')),
    ];

    if (p.impv != null) {
      final iv = p.impv!;
      tenses.add(VerbTense('Impératif', 'Présent', pronominal
          ? ['${iv[0]}-toi', '${iv[1]}-nous', '${iv[2]}-vous']
          : List.of(iv)));
      if (!pronominal) {
        final auxImpv = auxParts.impv!;
        tenses.add(VerbTense('Impératif', 'Passé', [
          '${auxImpv[0]} ${agree ? '${p.pp}(e)' : p.pp}',
          '${auxImpv[1]} ${agree ? '${p.pp}${ppS ? '(es)' : '(e)s'}' : p.pp}',
          '${auxImpv[2]} ${agree ? '${p.pp}(e)${ppS ? '' : '(s)'}' : p.pp}',
        ]));
      }
    }

    final auxInf = pronominal ? (_startsWithVowel(aux) ? "s'$aux" : 'se $aux') : aux;
    final labels = <String>['Infinitif', 'Infinitif passé', 'Participe passé'];
    final forms = <String>[infinitive, '$auxInf ${agree ? '${p.pp}(e)' : p.pp}', p.pp];
    if (p.ppr.isNotEmpty) {
      final ppr = pronominal ? refl(2, p.ppr) : p.ppr;
      labels.addAll(['Participe présent', 'Gérondif']);
      forms.addAll([ppr, 'en $ppr']);
    }
    tenses.add(VerbTense('Participe & infinitif', 'Formes', forms, labels: labels));
    return tenses;
  }

  /// Text for text-to-speech: "il/elle parle" → "il parle", "allé(e)s" → "allés".
  static String speakable(String form) => form
      .replaceAll('il/elle', 'il')
      .replaceAll('ils/elles', 'ils')
      .replaceAll(RegExp(r'\((e|s|es)\)'), '');
}
