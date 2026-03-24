class GrammarTopic {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String description;

  const GrammarTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.description,
  });
}

// All grammar topics
final List<GrammarTopic> grammarTopics = [
  const GrammarTopic(
    id: 'present',
    title: 'Le Présent',
    subtitle: 'Present Tense',
    icon: '⌚',
    description: 'Master regular and irregular verbs in the present tense',
  ),
  const GrammarTopic(
    id: 'passe_compose',
    title: 'Passé Composé',
    subtitle: 'Past Tense with "have"',
    icon: '⏱️',
    description: 'Learn to talk about completed actions in the past',
  ),
  const GrammarTopic(
    id: 'imparfait',
    title: 'Imparfait',
    subtitle: 'Ongoing Past Actions',
    icon: '🎬',
    description: 'Describe ongoing situations and habits in the past',
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
  ),
  const GrammarTopic(
    id: 'comparatif',
    title: 'Le Comparatif',
    subtitle: 'More, Less & As ... As',
    icon: '⚖️',
    description: 'Compare people and things using plus, moins, and aussi',
  ),
];
