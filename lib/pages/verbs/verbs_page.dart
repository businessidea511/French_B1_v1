import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/deepseek_service.dart';

class VerbsPage extends StatefulWidget {
  const VerbsPage({super.key});

  @override
  State<VerbsPage> createState() => _VerbsPageState();
}

class _VerbsPageState extends State<VerbsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String selectedVerb = 'parler';
  String selectedTense = 'Présent';

  final List<String> verbs = [
    'parler',
    'finir',
    'être',
    'avoir',
    'aller',
    'faire',
    'vouloir',
    'pouvoir',
    'devoir',
    'savoir',
    'venir',
    'dire',
    'prendre',
    'voir',
    'croire',
    'mettre',
    'tenir',
    'penser',
    'donner',
    'passer',
    'falloir',
    'comprendre',
    'sortir',
    'partir',
    'arriver',
    'apprendre',
    'attendre',
    'répondre',
    'recevoir',
    'perdre',
    'vivre',
    'aimer',
    'choisir',
    'rendre',
    'connaître',
    'paraître',
    'sentir',
    'retenir',
    'devenir',
    'remettre',
    'servir',
    'prévoir',
    'écrire',
    'permettre',
    'offrir',
    'appeler',
    'aider',
    'chercher',
    'commencer',
    'jouer',
    'travailler',
    'entendre',
    'marcher',
    'manger',
    'mourir',
    'naître',
    'ouvrir',
    'compter',
    'descendre',
    'revenir',
    'lire',
    'espérer',
    'envoyer',
    'payer',
    'dormir',
    'craindre',
    'battre',
    'vendre',
    'conduire',
    'suivre',
    'boire',
    'plaire',
    'taire',
    'rire',
    'cuire',
    'naître',
    'suffire',
    'valoir',
    'fuir',
    'rompre',
    'vaincre',
    'moudre',
    'clore',
    'absoudre',
    'conclure',
    'coudre',
    'traire',
    'réussir',
    'obtenir',
    'produire',
    'acheter',
    'assurer',
    'demander',
    'utiliser',
    'rester',
    'occuper',
    'sembler',
    'porter',
    'montrer',
    'changer',
    'continuer',
    'proposer',
    'considérer',
    'mener',
    'expliquer',
    'préparer',
    'décider',
    'rencontrer',
    'représenter',
    'terminer',
    'réaliser',
    'ajouter',
    'gagner',
    'abandonner',
    'indiquer',
    'profiter',
    'tenter',
    'apprécier',
    'organiser',
    'créer',
    'intéresser',
    'accepter',
    'refuser',
    'prouver',
    'rapporter',
    'constituer',
    'former',
    'définir',
    'établir',
    'reprendre',
    'agir',
    'traiter',
    'réunir',
    'fixer',
    'disposer',
    'installer',
    'procéder',
    'publier',
    'relever',
    'concerner',
    'supposer',
    'protéger',
    'exprimer',
    'évoquer',
    'favoriser',
    'limiter',
    'lier',
    'engager',
    'rechercher',
    'analyser',
    'bénéficier',
    'interroger',
    'situer',
    'rappeler',
    'orienter',
    'consulter',
    'observer',
    'soutenir',
    'faciliter',
    'manquer',
    'imposer',
    'maintenir',
    'respecter',
    'accompagner',
    'adopter',
    'évaluer',
    'identifier',
    'découvrir',
    'transformer',
    'associer',
    'participer',
    'contribuer',
    'garantir',
    'partager',
    's\'appeler',
    's\'occuper',
    'se souvenir',
    'se tromper',
    'se lever',
    'se coucher',
    'se laver',
    's\'habiller',
    'se promener',
    'se sentir'
  ].toSet().toList();
  final List<String> tenses = [
    'Présent',
    'Passé Composé',
    'Imparfait',
    'Plus-que-parfait',
    'Conditionnel',
    'Futur Proche',
    'Futur Simple',
  ];

  final Map<String, Map<String, List<String>>> conjugations = {
    'parler': {
      'Présent': [
        'je parle',
        'tu parles',
        'il/elle parle',
        'nous parlons',
        'vous parliez',
        'ils/elles parlent',
      ],
      'Passé Composé': [
        'j\'ai parlé',
        'tu as parlé',
        'il/elle a parlé',
        'nous avons parlé',
        'vous avez parlé',
        'ils/elles ont parlé',
      ],
      'Imparfait': [
        'je parlais',
        'tu parlais',
        'il/elle parlait',
        'nous parlions',
        'vous parliez',
        'ils/elles parlaient',
      ],
      'Plus-que-parfait': [
        'j\'avais parlé',
        'tu avais parlé',
        'il/elle avait parlé',
        'nous avions parlé',
        'vous aviez parlé',
        'ils/elles avaient parlé',
      ],
      'Futur Proche': [
        'je vais parler',
        'tu vas parler',
        'il/elle va parler',
        'nous allons parler',
        'vous allez parler',
        'ils/elles vont parler',
      ],
      'Futur Simple': [
        'je parlerai',
        'tu parleras',
        'il/elle parlera',
        'nous parlerons',
        'vous parlerez',
        'ils/elles parleront',
      ],
      'Conditionnel': [
        'je parlerais',
        'tu parlerais',
        'il/elle parlerait',
        'nous parlerions',
        'vous parleriez',
        'ils/elles parleraient',
      ],
    },
    'finir': {
      'Présent': [
        'je finis',
        'tu finis',
        'il/elle finit',
        'nous finissons',
        'vous finissez',
        'ils/elles finissent',
      ],
      'Passé Composé': [
        'j\'ai fini',
        'tu as fini',
        'il/elle a fini',
        'nous avons fini',
        'vous avez fini',
        'ils/elles ont fini',
      ],
      'Imparfait': [
        'je finissais',
        'tu finissais',
        'il/elle finissait',
        'nous finissions',
        'vous finissiez',
        'ils/elles finissaient',
      ],
      'Plus-que-parfait': [
        'j\'avais fini',
        'tu avais fini',
        'il/elle avait fini',
        'nous avions fini',
        'vous aviez fini',
        'ils/elles avaient fini',
      ],
      'Futur Proche': [
        'je vais finir',
        'tu vas finir',
        'il/elle va finir',
        'nous allons finir',
        'vous allez finir',
        'ils/elles vont finir',
      ],
      'Futur Simple': [
        'je finirai',
        'tu finiras',
        'il/elle finira',
        'nous finirons',
        'vous finirez',
        'ils/elles finiront',
      ],
      'Conditionnel': [
        'je finirais',
        'tu finirais',
        'il/elle finirait',
        'nous finirions',
        'vous finiriez',
        'ils/elles finiraient',
      ],
    },
    'être': {
      'Présent': [
        'je suis',
        'tu es',
        'il/elle est',
        'nous sommes',
        'vous êtes',
        'ils/elles sont',
      ],
      'Passé Composé': [
        'j\'ai été',
        'tu as été',
        'il/elle a été',
        'nous avons été',
        'vous avez été',
        'ils/elles ont été',
      ],
      'Imparfait': [
        'j\'étais',
        'tu étais',
        'il/elle était',
        'nous étions',
        'vous étiez',
        'ils/elles étaient',
      ],
      'Plus-que-parfait': [
        'j\'avais été',
        'tu avais été',
        'il/elle avait été',
        'nous avions été',
        'vous aviez été',
        'ils/elles avaient été',
      ],
      'Futur Proche': [
        'je vais être',
        'tu vas être',
        'il/elle va être',
        'nous allons être',
        'vous allez être',
        'ils/elles vont être',
      ],
      'Futur Simple': [
        'je serai',
        'tu seras',
        'il/elle sera',
        'nous serons',
        'vous serez',
        'ils/elles seront',
      ],
      'Conditionnel': [
        'je serais',
        'tu serais',
        'il/elle serait',
        'nous serions',
        'vous seriez',
        'ils/elles seraient',
      ],
    },
    'avoir': {
      'Présent': [
        'j\'ai',
        'tu as',
        'il/elle a',
        'nous avons',
        'vous avez',
        'ils/elles ont',
      ],
      'Passé Composé': [
        'j\'ai eu',
        'tu as eu',
        'il/elle a eu',
        'nous avons eu',
        'vous avez eu',
        'ils/elles ont eu',
      ],
      'Imparfait': [
        'j\'avais',
        'tu avais',
        'il/elle avait',
        'nous avions',
        'vous aviez',
        'ils/elles avaient',
      ],
      'Plus-que-parfait': [
        'j\'avais eu',
        'tu avais eu',
        'il/elle avait eu',
        'nous avions eu',
        'vous aviez eu',
        'ils/elles avaient eu',
      ],
      'Futur Proche': [
        'je vais avoir',
        'tu vas avoir',
        'il/elle va avoir',
        'nous allons avoir',
        'vous allez avoir',
        'ils/elles vont avoir',
      ],
      'Futur Simple': [
        'j\'aurai',
        'tu auras',
        'il/elle aura',
        'nous aurons',
        'vous aurez',
        'ils/elles auront',
      ],
      'Conditionnel': [
        'j\'aurais',
        'tu aurais',
        'il/elle aurait',
        'nous aurions',
        'vous auriez',
        'ils/elles auraient',
      ],
    },
    'aller': {
      'Présent': [
        'je vais',
        'tu vas',
        'il/elle va',
        'nous allons',
        'vous allez',
        'ils/elles vont',
      ],
      'Passé Composé': [
        'je suis allé(e)',
        'tu es allé(e)',
        'il/elle est allé(e)',
        'nous sommes allé(e)s',
        'vous êtes allé(e)s',
        'ils/elles sont allé(e)s',
      ],
      'Imparfait': [
        'j\'allais',
        'tu allais',
        'il/elle allait',
        'nous allions',
        'vous alliez',
        'ils/elles allaient',
      ],
      'Plus-que-parfait': [
        'j\'étais allé(e)',
        'tu étais allé(e)',
        'il/elle était allé(e)',
        'nous étions allé(e)s',
        'vous étiez allé(e)s',
        'ils/elles étaient allé(e)s',
      ],
      'Futur Proche': [
        'je vais aller',
        'tu vas aller',
        'il/elle va aller',
        'nous allons aller',
        'vous allez aller',
        'ils/elles vont aller',
      ],
      'Futur Simple': [
        'j\'irai',
        'tu iras',
        'il/elle ira',
        'nous irons',
        'vous irez',
        'ils/elles iront',
      ],
      'Conditionnel': [
        'j\'irais',
        'tu irais',
        'il/elle irait',
        'nous irions',
        'vous iriez',
        'ils/elles iraient',
      ],
    },
    'faire': {
      'Présent': [
        'je fais',
        'tu fais',
        'il/elle fait',
        'nous faisons',
        'vous faites',
        'ils/elles font',
      ],
      'Passé Composé': [
        'j\'ai fait',
        'tu as fait',
        'il/elle a fait',
        'nous avons fait',
        'vous avez fait',
        'ils/elles ont fait',
      ],
      'Imparfait': [
        'je faisais',
        'tu faisais',
        'il/elle faisait',
        'nous faisions',
        'vous faisiez',
        'ils/elles faisaient',
      ],
      'Plus-que-parfait': [
        'j\'avais fait',
        'tu avais fait',
        'il/elle avait fait',
        'nous avions fait',
        'vous aviez fait',
        'ils/elles avaient fait',
      ],
      'Futur Proche': [
        'je vais faire',
        'tu vas faire',
        'il/elle va faire',
        'nous allons faire',
        'vous allez faire',
        'ils/elles vont faire',
      ],
      'Futur Simple': [
        'je ferai',
        'tu feras',
        'il/elle fera',
        'nous ferons',
        'vous ferez',
        'ils/elles feront',
      ],
      'Conditionnel': [
        'je ferais',
        'tu ferais',
        'il/elle ferait',
        'nous ferions',
        'vous feriez',
        'ils/elles feraient',
      ],
    },
  };

  Future<void> _fetchAIConjugation(String verb) async {
    if (verb.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final result = await DeepSeekService.conjugateVerb(verb.toLowerCase());
      setState(() {
        conjugations[verb.toLowerCase()] = result;
        selectedVerb = verb.toLowerCase();
        if (!verbs.contains(verb.toLowerCase())) {
          verbs.add(verb.toLowerCase());
        }
        _isLoading = false;
        _searchController.clear();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not find conjugations for this verb. Please check your API key.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verb Conjugator'),
      ),
      body: Focus(
        autofocus: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildVerbSearchAndSelect(),
                  const SizedBox(height: 24),
                  _buildTenseSelector(),
                  const SizedBox(height: 24),
                  _buildConjugationResults(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerbSearchAndSelect() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search or Select Verb',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return verbs.take(10); // Show first 10 by default
                    }
                    final filtered = verbs.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    }).toList();

                    // If no direct matches, or even if there are, allow user to custom conjugate
                    if (!filtered
                            .contains(textEditingValue.text.toLowerCase()) &&
                        textEditingValue.text.isNotEmpty) {
                      return [
                        ...filtered,
                        'Conjugate "${textEditingValue.text}" with AI...'
                      ];
                    }
                    return filtered;
                  },
                  onSelected: (String selection) {
                    if (selection.startsWith('Conjugate "')) {
                      // Extract the verb from the special string
                      final verb = selection.split('"')[1].toLowerCase();
                      _fetchAIConjugation(verb);
                    } else {
                      setState(() => selectedVerb = selection);
                      if (!conjugations.containsKey(selection)) {
                        _fetchAIConjugation(selection);
                      }
                    }
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Type a verb (e.g. vouloir)',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _fetchAIConjugation(value);
                        }
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxHeight: 300, maxWidth: 400),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              final isSpecial =
                                  option.startsWith('Conjugate "');
                              return ListTile(
                                leading: Icon(
                                  isSpecial
                                      ? Icons.auto_awesome
                                      : Icons.menu_book,
                                  color: isSpecial ? AppTheme.primary : null,
                                  size: 20,
                                ),
                                title: Text(
                                  option,
                                  style: TextStyle(
                                    fontWeight: isSpecial
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSpecial ? AppTheme.primary : null,
                                  ),
                                ),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: AppTheme.surface.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenseSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tenses', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tenses.map((tense) {
                final isSelected = tense == selectedTense;
                return ChoiceChip(
                  label: Text(tense),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => selectedTense = tense);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConjugationResults() {
    final verbData = conjugations[selectedVerb];
    if (verbData == null) {
      return const Center(child: Text('Click "Go" or select a common verb.'));
    }

    final tenseData = verbData[selectedTense];
    if (tenseData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.info_outline,
                  size: 48, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text('Tense "$selectedTense" not found for "$selectedVerb".'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${selectedVerb.toUpperCase()} - $selectedTense',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 4,
          ),
          itemCount: tenseData.length,
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tenseData[index],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
