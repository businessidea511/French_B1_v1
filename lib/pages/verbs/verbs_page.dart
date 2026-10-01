import 'package:flutter/material.dart';
import '../../data/verb_list.dart';
import '../../services/conjugator.dart';
import '../../services/global_scroll_manager.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/translated_text.dart';

/// What each tense is for, in simple English (translated on screen).
const Map<String, String> tenseExplanations = {
  'Indicatif|Présent': 'Now, habits and general truths. « Je travaille à Liège. »',
  'Indicatif|Passé composé':
      'A finished action in the past: what happened. Formula: avoir or être in the present + participe passé. « Hier, j\'ai mangé une gaufre. »',
  'Indicatif|Imparfait':
      'Descriptions, habits and background in the past: how it was, what used to happen. Formula: stem of « nous » in the present + -ais, -ais, -ait, -ions, -iez, -aient.',
  'Indicatif|Plus-que-parfait':
      'The past before another past (had done). Formula: avoir or être in the imparfait + participe passé. « Quand je suis arrivé, le train était parti. »',
  'Indicatif|Futur simple':
      'The future: plans, predictions and promises (will). Formula: infinitive (or an irregular stem) + -ai, -as, -a, -ons, -ez, -ont.',
  'Indicatif|Futur proche':
      'Something that is going to happen soon. Very common when speaking. Formula: aller in the present + infinitive.',
  'Indicatif|Passé récent': 'Something that has just happened. Formula: venir de + infinitive. « Je viens d\'arriver. »',
  'Indicatif|Futur antérieur':
      'A future action that will be finished before another future moment (will have done). « Quand tu rentreras, j\'aurai fini. »',
  'Indicatif|Passé simple':
      'The written past of books, stories and news. You will read it but almost never say it: when speaking, use the passé composé.',
  'Indicatif|Passé antérieur': 'Literary: the past just before a passé simple, after quand, dès que or après que.',
  'Subjonctif|Présent':
      'After « que » with wishes, feelings, doubt and necessity: « Il faut que tu viennes », « Je veux qu\'il parte ». Formula: stem of « ils » in the present + -e, -es, -e, -ions, -iez, -ent.',
  'Subjonctif|Passé':
      'The same triggers as the subjonctif présent, for an action that is already finished. « Je suis content que tu sois venu. »',
  'Subjonctif|Imparfait': 'Literary only (old books, very formal writing). Today people use the subjonctif présent instead.',
  'Subjonctif|Plus-que-parfait': 'Literary only. Today people use the subjonctif passé instead.',
  'Conditionnel|Présent':
      'Polite requests, wishes, advice and imagined situations (would). « Je voudrais un café. » « Si j\'avais le temps, je viendrais. » Formula: futur stem + -ais, -ais, -ait, -ions, -iez, -aient.',
  'Conditionnel|Passé':
      'Regrets and things that would have happened (would have). « Si j\'avais su, je serais venu. »',
  'Impératif|Présent': 'Orders, advice and instructions. No subject pronoun, and only three persons: tu, nous, vous.',
  'Impératif|Passé': 'Rare: an order to have something finished by a certain time. « Aie fini avant midi ! »',
  'Participe & infinitif|Formes':
      'Forms without a person. Participe passé: used in all compound tenses. Gérondif (en + -ant): two actions at the same time, « Il chante en cuisinant ». Participe présent: mostly written French.',
};

class VerbsPage extends StatefulWidget {
  final String initialVerb;
  const VerbsPage({super.key, this.initialVerb = 'parler'});

  @override
  State<VerbsPage> createState() => _VerbsPageState();
}

class _VerbsPageState extends State<VerbsPage> {
  final ScrollController _scrollController = ScrollController();
  late VerbTable _table;
  String _mood = 'Indicatif';
  String _tense = 'Présent';

  @override
  void initState() {
    super.initState();
    GlobalScrollManager.register(_scrollController);
    _table = Conjugator.conjugate(widget.initialVerb) ?? Conjugator.conjugate('parler')!;
  }

  @override
  void dispose() {
    GlobalScrollManager.unregister(_scrollController);
    _scrollController.dispose();
    super.dispose();
  }

  void _select(String verb) {
    final table = Conjugator.conjugate(verb);
    if (table == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('« ${verb.trim()} » is not a French verb I know. Type the infinitive, e.g. « prendre » or « se lever ».'),
      ));
      return;
    }
    setState(() {
      _table = table;
      // Keep the tense the learner was studying when the new verb has it.
      if (table.find(_mood, _tense) == null) {
        _mood = 'Indicatif';
        _tense = 'Présent';
      }
    });
    FocusScope.of(context).unfocus();
  }

  String? _meaning(String infinitive) {
    final m = commonVerbs[infinitive];
    return m == null || m.isEmpty ? null : m;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conjugaison')),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearch(),
                const SizedBox(height: 20),
                _buildVerbHeader(),
                const SizedBox(height: 20),
                _buildMoodAndTense(),
                const SizedBox(height: 16),
                _buildForms(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Autocomplete<String>(
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return commonVerbs.keys.take(12);
        return commonVerbs.keys.where((v) => v.contains(q) || commonVerbs[v]!.toLowerCase().contains(q)).take(20);
      },
      onSelected: _select,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Any French verb: prendre, se lever, envoyer…',
          prefixIcon: Icon(Icons.search),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) _select(v);
        },
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: AlignmentDirectional.topStart,
        child: Material(
          elevation: 8,
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320, maxWidth: 420),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final v in options)
                  ListTile(
                    dense: true,
                    title: Text(v, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(commonVerbs[v] ?? '', style: TextStyle(color: AppTheme.textSecondary)),
                    onTap: () => onSelected(v),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerbHeader() {
    final meaning = _meaning(_table.infinitive);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.warning.withValues(alpha: 0.18), AppTheme.surface]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_table.infinitive,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
              ),
              IconButton(
                tooltip: 'Écouter',
                icon: Icon(Icons.volume_up_rounded, color: AppTheme.warning),
                onPressed: () => TtsService.instance.speak(_table.infinitive),
              ),
            ],
          ),
          if (meaning != null)
            TranslatedText(meaning, style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(_table.group, AppTheme.primary),
              _chip('Auxiliaire : ${_table.auxiliary}', _table.auxiliary == 'être' ? AppTheme.secondary : AppTheme.success),
            ],
          ),
          for (final note in _table.notes) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 '),
                Expanded(child: TranslatedText(note, style: TextStyle(color: AppTheme.textPrimary, height: 1.4))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      );

  Widget _buildMoodAndTense() {
    final tenses = Conjugator.tensesByMood[_mood]!.where((t) => _table.find(_mood, t) != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final mood in Conjugator.moods)
                if (Conjugator.tensesByMood[mood]!.any((t) => _table.find(mood, t) != null))
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(mood),
                      selected: mood == _mood,
                      selectedColor: AppTheme.primary,
                      onSelected: (_) => setState(() {
                        _mood = mood;
                        _tense = Conjugator.tensesByMood[mood]!.firstWhere((t) => _table.find(mood, t) != null);
                      }),
                    ),
                  ),
            ],
          ),
        ),
        if (tenses.length > 1) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tenses)
                ChoiceChip(
                  label: Text(t),
                  selected: t == _tense,
                  selectedColor: AppTheme.warning,
                  labelStyle: TextStyle(
                    color: t == _tense ? Colors.black : AppTheme.textSecondary,
                    fontWeight: t == _tense ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _tense = t),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildForms() {
    final tense = _table.find(_mood, _tense)!;
    final explanation = tenseExplanations['$_mood|$_tense'];
    final wide = MediaQuery.of(context).size.width > 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (explanation != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tense.mood} · ${tense.name}',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TranslatedText(explanation, style: TextStyle(color: AppTheme.textPrimary, height: 1.45)),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = wide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                for (var i = 0; i < tense.forms.length; i++)
                  SizedBox(width: width, child: _formTile(tense, i)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _formTile(VerbTense tense, int i) {
    final form = tense.forms[i];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tense.labels != null)
                    Text(tense.labels![i], style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                  Text(form, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Écouter',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.volume_up_rounded, color: AppTheme.primary, size: 20),
            onPressed: () => TtsService.instance.speak(Conjugator.speakable(form)),
          ),
        ],
      ),
    );
  }
}
