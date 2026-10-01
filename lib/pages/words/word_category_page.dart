import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/word_bank.dart';
import '../../services/global_scroll_manager.dart';
import '../../services/language_provider.dart';
import '../../services/word_decks.dart';
import '../../theme/app_theme.dart';
import '../../widgets/grammar_cards.dart';
import '../../widgets/translated_text.dart';
import '../../services/conjugator.dart';
import '../flashcards/flashcards_page.dart';
import '../verbs/verbs_page.dart';

/// One list of words or expressions, with audio, meanings in the learner's
/// language and a flashcards button.
class WordCategoryPage extends StatefulWidget {
  final WordCategory category;
  const WordCategoryPage({super.key, required this.category});

  @override
  State<WordCategoryPage> createState() => _WordCategoryPageState();
}

class _WordCategoryPageState extends State<WordCategoryPage> {
  final ScrollController _scrollController = ScrollController();
  List<WordGloss>? _glosses;
  AppLanguage? _language;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    GlobalScrollManager.register(_scrollController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Provider.of<LanguageProvider>(context).currentLanguage;
    if (language != _language) {
      _language = language;
      _loadGlosses(language);
    }
  }

  Future<void> _loadGlosses(AppLanguage language) async {
    setState(() => _loading = true);
    final glosses = await WordDecks.glosses(widget.category.items, language);
    if (!mounted || language != _language) return;
    setState(() {
      _glosses = glosses;
      _loading = false;
    });
  }

  @override
  void dispose() {
    GlobalScrollManager.unregister(_scrollController);
    _scrollController.dispose();
    super.dispose();
  }

  List<WordGloss> get _shownGlosses =>
      _glosses ?? [for (final w in widget.category.items) WordGloss(w.en, w.note)];

  void _openFlashcards() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardsPage(
          deckTitle: widget.category.title,
          deck: WordDecks.cards(widget.category, _shownGlosses),
        ),
      ),
    );
  }

  /// For verb lists: opens the full conjugation of the verb, if it is one.
  VoidCallback? _conjugateAction(String french) {
    if (widget.category.id != 'verbes' && widget.category.id != 'cog_verbs') return null;
    final verb = french.replaceFirst(RegExp(r' (de|à)$'), '');
    if (Conjugator.conjugate(verb) == null) return null;
    return () => Navigator.push(context, MaterialPageRoute(builder: (_) => VerbsPage(initialVerb: verb)));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    final glosses = _shownGlosses;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.title),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(18),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(c.icon, style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TranslatedText(c.subtitle,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                      ),
                    ],
                  ),
                  if (c.intro.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡 ', style: TextStyle(fontSize: 18)),
                          Expanded(
                            child: TranslatedText(c.intro,
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.45)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _openFlashcards,
                    icon: const Text('🎴'),
                    label: Text('Flashcards · ${c.items.length}'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < c.items.length; i++)
                    WordTile(
                      item: c.items[i],
                      meaning: glosses[i].meaning,
                      note: glosses[i].note,
                      cognate: c.cognate,
                      onConjugate: _conjugateAction(c.items[i].fr),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A French word or expression with its meaning, example and note.
class WordTile extends StatelessWidget {
  final WordItem item;
  final String meaning;
  final String note;
  final bool cognate;
  final VoidCallback? onConjugate;

  const WordTile({
    super.key,
    required this.item,
    required this.meaning,
    required this.note,
    this.cognate = false,
    this.onConjugate,
  });

  @override
  Widget build(BuildContext context) {
    final tag = WordDecks.tagLabel(item.tag);
    final tagColor = item.tag == 'vulgaire' ? AppTheme.error : AppTheme.warning;
    final gender = WordDecks.gender(item.fr);
    final genderColor = gender == 'm' ? WordDecks.masculine : (gender == 'f' ? WordDecks.feminine : null);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (genderColor ?? AppTheme.textPrimary).withValues(alpha: genderColor == null ? 0.06 : 0.45)),
        gradient: genderColor == null
            ? null
            : LinearGradient(colors: [genderColor.withValues(alpha: 0.14), AppTheme.surface.withValues(alpha: 0.85)], stops: const [0, 0.35]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.fr,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: genderColor ?? AppTheme.textPrimary)),
              ),
              if (gender != null)
                Text(gender == 'm' ? '♂' : '♀', style: TextStyle(color: genderColor, fontSize: 18, fontWeight: FontWeight.bold)),
              if (onConjugate != null)
                IconButton(
                  tooltip: 'Conjugaison',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.sync_alt_rounded, color: AppTheme.warning, size: 22),
                  onPressed: onConjugate,
                ),
              SpeakButton(item.fr),
            ],
          ),
          if (cognate) ...[
            Text('🇬🇧 ${item.en}',
                textDirection: TextDirection.ltr,
                style: TextStyle(color: AppTheme.warning, fontSize: 15, fontWeight: FontWeight.w600)),
            if (meaning != item.en)
              Text(meaning, style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          ] else
            Text(meaning, style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          if (tag.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(tag, style: TextStyle(color: tagColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
          if (item.example.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text('« ${item.example} »',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic, fontSize: 14)),
                  ),
                  SpeakButton(item.example, color: AppTheme.textTertiary),
                ],
              ),
            ),
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 6, end: 10),
              child: Text('💡 $note', style: TextStyle(color: AppTheme.textTertiary, fontSize: 13, height: 1.4)),
            ),
        ],
      ),
    );
  }
}
