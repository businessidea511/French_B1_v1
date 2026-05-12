class GrammarTopic {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String description;
  final List<dynamic>? content;

  const GrammarTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.description,
    this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'description': description,
      'content': content,
    };
  }

  factory GrammarTopic.fromJson(Map<String, dynamic> json) {
    return GrammarTopic(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      icon: json['icon'],
      description: json['description'],
      content: json['content'],
    );
  }
}

// All grammar topics
final List<GrammarTopic> grammarTopics = [
  const GrammarTopic(
    id: 'present',
    title: 'Le Présent',
    subtitle: 'Present Tense',
    icon: '⌚',
    description: 'Master regular and irregular verbs in the present tense',
    content: [
      {"type": "section_title", "emoji": "⏰", "title": "L'usage du Présent"},
      {"type": "text", "content": "The present tense is used to describe current actions, general truths, or habitual actions. It is the foundation of French communication."},
      
      {"type": "section_title", "emoji": "📋", "title": "Les Verbes en -ER (1er Groupe)"},
      {"type": "tipbox", "title": "Règle de formation", "content": "Remove the '-er' and add: -e, -es, -e, -ons, -ez, -ent.", "color": "green"},
      {"type": "table", "headers": ["Sujet", "Terminaison", "Parler (to speak)"], "rows": [
        ["Je", "-e", "Je parle"],
        ["Tu", "-es", "Tu parles"],
        ["Il/Elle", "-e", "Il/Elle parle"],
        ["Nous", "-ons", "Nous parlions"],
        ["Vous", "-ez", "Vous parlez"],
        ["Ils/Elles", "-ent", "Ils/Elles parlent"]
      ]},
      
      {"type": "section_title", "emoji": "🌟", "title": "Les Auxiliaires Essentiels"},
      {"type": "french_tipbox", "title": "Être (To be)", "frenchText": "Je suis\nTu es\nIl/Elle est\nNous sommes\nVous êtes\nIls/Elles sont", "color": "blue"},
      {"type": "french_tipbox", "title": "Avoir (To have)", "frenchText": "J'ai\nTu as\nIl/Elle a\nNous avons\nVous avez\nIls/Elles ont", "color": "purple"}
    ],
  ),
  const GrammarTopic(
    id: 'passe_compose',
    title: 'Passé Composé',
    subtitle: 'Past Tense with "have"',
    icon: '⏱️',
    description: 'Learn to talk about completed actions in the past',
    content: [
      {"type": "section_title", "emoji": "🎬", "title": "Formation du Passé Composé"},
      {"type": "text", "content": "The Passé Composé is formed using two parts: the auxiliary (avoir or être) + the past participle."},
      {"type": "example", "french": "J'ai mangé une pomme.", "translation": "I ate an apple."},
      
      {"type": "section_title", "emoji": "🏗️", "title": "Les Participes Passés"},
      {"type": "table", "headers": ["Infinitif", "Participe Passé", "Exemple"], "rows": [
        ["-er", "-é", "Parlé"],
        ["-ir", "-i", "Fini"],
        ["-re", "-u", "Vendu"]
      ]},
      
      {"type": "section_title", "emoji": "🏠", "title": "L'auxiliaire ÊTRE (DR & MRS VANDERTRAMPP)"},
      {"type": "tipbox", "title": "Attention !", "content": "Most verbs use 'Avoir'. However, movement verbs and reflexive verbs use 'Être'.", "color": "red"},
      {"type": "french_tipbox", "title": "Exemples avec ÊTRE", "frenchText": "Je suis allé(e)\nTu es venu(e)\nIl est mort\nElle est née\nNous sommes partis", "color": "yellow"}
    ],
  ),
  const GrammarTopic(
    id: 'imparfait',
    title: 'Imparfait',
    subtitle: 'Ongoing Past Actions',
    icon: '🎬',
    description: 'Describe ongoing situations and habits in the past',
    content: [
      {"type": "section_title", "emoji": "🕰️", "title": "C'est quoi l'Imparfait ?"},
      {"type": "text", "content": "L'imparfait (the imperfect tense) is used to describe ongoing states, habits, or repeated actions in the past. Think of it as the \"was doing\" or \"used to do\" tense."},
      {"type": "example", "french": "Quand j'étais petit, je mangeais des pommes.", "translation": "When I was little, I used to eat apples."},
      
      {"type": "section_title", "emoji": "📝", "title": "Formation de l'Imparfait"},
      {"type": "tipbox", "title": "La Méthode", "content": "1. Start with the 'nous' form of the present tense.\n2. Remove the '-ons' ending.\n3. Add the Imperfect endings: -ais, -ais, -ait, -ions, -iez, -aient.", "color": "blue"},
      {"type": "table", "headers": ["Pronom", "Terminaison", "Exemple (Parler)"], "rows": [
        ["Je", "-ais", "Je parlais"],
        ["Tu", "-ais", "Tu parlais"],
        ["Il / Elle", "-ait", "Il parlait"],
        ["Nous", "-ions", "Nous parlions"],
        ["Vous", "-iez", "Vous parliez"],
        ["Ils / Elles", "-aient", "Ils parlaient"]
      ]},
      
      {"type": "section_title", "emoji": "⚠️", "title": "L'Exception Unique"},
      {"type": "tipbox", "title": "Le verbe ÊTRE", "content": "The only verb that doesn't follow the 'nous' rule is 'être'. Its stem is 'ét-'.", "color": "red"},
      {"type": "example", "french": "J'étais, Tu étais, Il était, Nous étions, Vous étiez, Ils étaient.", "translation": "I was, You were, He was, We were, You were, They were."}
    ],
  ),
  const GrammarTopic(
    id: 'plus_que_parfait',
    title: 'Plus-que-parfait',
    subtitle: 'Past Perfect Tense',
    icon: '⏪',
    description: 'Talk about actions that happened before other past actions',
  ),
  const GrammarTopic(
    id: 'conditionnel',
    title: 'Conditionnel',
    subtitle: 'Would/Could/Should',
    icon: '🤔',
    description: 'Express wishes, politeness, and hypothetical situations',
    content: [
      {"type": "section_title", "emoji": "💭", "title": "C'est quoi le Conditionnel ?"},
      {"type": "text", "content": "The conditional mood is used to express wishes, possibilities, and polite requests. It often translates to \"would\" or \"could\" in English."},
      {"type": "example", "french": "Je voudrais un café, s'il vous plaît.", "translation": "I would like a coffee, please."},
      
      {"type": "section_title", "emoji": "🏗️", "title": "Formation du Conditionnel"},
      {"type": "tipbox", "title": "Règle Simple", "content": "The stem is the same as the Futur Simple (usually the whole infinitive), and the endings are the same as the Imparfait.", "color": "blue"},
      {"type": "table", "headers": ["Pronom", "Terminaison", "Exemple (Aimer)"], "rows": [
        ["Je", "-ais", "J'aimerais"],
        ["Tu", "-ais", "Tu aimerais"],
        ["Il/Elle", "-ait", "Il aimerait"],
        ["Nous", "-ions", "Nous aimerions"],
        ["Vous", "-iez", "Vous aimeriez"],
        ["Ils/Elles", "-aient", "Ils aimeraient"]
      ]}
    ],
  ),
  const GrammarTopic(
    id: 'negative_complex',
    title: 'Complex Negation',
    subtitle: 'Never, Nothing, Nobody',
    icon: '⛔',
    description: 'Master complex negative structures in French',
  ),
  const GrammarTopic(
    id: 'futur_proche',
    title: 'Futur Proche',
    subtitle: 'Going to (Near Future)',
    icon: '🔜',
    description: 'Talk about things that will happen soon',
  ),
  const GrammarTopic(
    id: 'futur_simple',
    title: 'Futur Simple',
    subtitle: 'Will (Future Tense)',
    icon: '🔮',
    description: 'Discuss future plans and predictions',
    content: [
      {"type": "section_title", "emoji": "🔮", "title": "Le Futur Simple"},
      {"type": "text", "content": "The futur simple is used to talk about things that WILL happen. Unlike the futur proche (going to), it is more formal and often used for long-term plans or predictions."},
      {"type": "example", "french": "J'irai en France l'année prochaine.", "translation": "I will go to France next year."},
      
      {"type": "section_title", "emoji": "📝", "title": "Formation"},
      {"type": "tipbox", "title": "La Règle", "content": "For regular verbs, take the infinitive and add: -ai, -as, -a, -ons, -ez, -ont.", "color": "purple"},
      {"type": "table", "headers": ["Pronom", "Terminaison", "Manger"], "rows": [
        ["Je", "-ai", "Je mangerai"],
        ["Tu", "-as", "Tu mangeras"],
        ["Il/Elle", "-a", "Il mangera"],
        ["Nous", "-ons", "Nous mangerons"],
        ["Vous", "-ez", "Vous mangerez"],
        ["Ils/Elles", "-ont", "Ils mangeront"]
      ]}
    ],
  ),
  const GrammarTopic(
    id: 'cod_coi',
    title: 'COD / COI',
    subtitle: 'Direct & Indirect Objects',
    icon: '🎯',
    description: 'Understand object pronouns: le, la, lui, leur',
  ),
  const GrammarTopic(
    id: 'si_seulement',
    title: 'Si seulement',
    subtitle: '"If only" Phrases',
    icon: '💭',
    description: 'Express regrets and wishes with "si seulement"',
  ),
  const GrammarTopic(
    id: 'voix_passive',
    title: 'La Voix Passive',
    subtitle: 'Passive Voice',
    icon: '🔄',
    description: 'Learn how to form and use the passive voice in French',
  ),
  const GrammarTopic(
    id: 'adverbes_ment',
    title: 'Les Adverbes en -ment',
    subtitle: 'Adverbs ending in -ment',
    icon: '🏃',
    description: 'Master the formation of adverbs from adjectives',
  ),
  const GrammarTopic(
    id: 'subjonctif',
    title: 'Le Subjonctif',
    subtitle: 'Wishes, Doubts & Emotions',
    icon: '🌀',
    description:
        'Master the subjunctive mood for emotions, wishes, and uncertainty',
    content: [
      {"type": "section_title", "emoji": "🌀", "title": "Le Subjonctif : Pourquoi ?"},
      {"type": "text", "content": "The subjunctive is NOT a tense, it is a MOOD. It is used to express subjectivity, doubt, necessity, or emotion. It almost always follows \"que\"."},
      {"type": "example", "french": "Il faut que je parte.", "translation": "It is necessary that I leave."},
      
      {"type": "section_title", "emoji": "🏗️", "title": "Formation Régulière"},
      {"type": "tipbox", "title": "La Recette", "content": "Take the 'ils' form of the present tense, drop '-ent', and add: -e, -es, -e, -ions, -iez, -ent.", "color": "purple"},
      {"type": "table", "headers": ["Sujet", "Terminaison", "Finir"], "rows": [
        ["Que je", "-e", "finisse"],
        ["Que tu", "-es", "finisses"],
        ["Qu'il", "-e", "finisse"],
        ["Que nous", "-ions", "finissions"],
        ["Que vous", "-iez", "finissiez"],
        ["Qu'ils", "-ent", "finissent"]
      ]}
    ],
  ),
  const GrammarTopic(
    id: 'comparatif',
    title: 'Le Comparatif',
    subtitle: 'More, Less & As ... As',
    icon: '⚖️',
    description: 'Compare people and things using plus, moins, and aussi',
  ),
  const GrammarTopic(
    id: 'time_prepositions',
    title: 'Mots de Temps',
    subtitle: 'Depuis, pendant, il y a...',
    icon: '🕰️',
    description: 'Master time prepositions: depuis, pendant, il y a, en, dans',
  ),
  const GrammarTopic(
    id: 'connectors',
    title: 'Les Connecteurs',
    subtitle: 'Mais, donc, parce que...',
    icon: '🔗',
    description: 'Learn logical connectors: mais, donc, parce que, cependant, malgré',
  ),
];
