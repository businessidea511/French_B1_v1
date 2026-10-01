import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/word_bank.dart';
import '../../services/deepseek_service.dart';
import '../../services/global_scroll_manager.dart';
import '../../services/language_provider.dart';
import '../../services/word_decks.dart';
import '../../theme/app_theme.dart';
import '../../widgets/translated_text.dart';
import 'word_category_page.dart';
import '../../services/ui_strings.dart';

/// Home of a word section (Vocabulary, Expressions, Street French): its
/// categories grouped by theme, and a search over every word.
class WordSectionPage extends StatefulWidget {
  final WordSection section;
  const WordSectionPage({super.key, required this.section});

  @override
  State<WordSectionPage> createState() => _WordSectionPageState();
}

class _WordSectionPageState extends State<WordSectionPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  List<(WordItem, bool)> _results = [];
  List<WordGloss>? _resultGlosses;
  Map<String, String> _subtitles = {};
  AppLanguage? _language;

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
      _translateSubtitles(language);
    }
  }

  /// All category subtitles in one request instead of one per tile.
  Future<void> _translateSubtitles(AppLanguage language) async {
    final subtitles = [for (final c in widget.section.categories) c.subtitle];
    if (language == AppLanguage.english) {
      setState(() => _subtitles = {});
      return;
    }
    final translated = await DeepSeekService.translateBatch(subtitles, language.name);
    if (!mounted || language != _language) return;
    setState(() => _subtitles = {for (var i = 0; i < subtitles.length; i++) subtitles[i]: translated[i]});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    GlobalScrollManager.unregister(_scrollController);
    _scrollController.dispose();
    _search.dispose();
    super.dispose();
  }

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = _fold(query.trim());
      if (q.isEmpty) {
        setState(() => _results = []);
        return;
      }
      final results = <(WordItem, bool)>[
        for (final c in widget.section.categories)
          for (final w in c.items)
            if (_fold(w.fr).contains(q) || _fold(w.en).contains(q)) (w, c.cognate),
      ].take(30).toList();
      setState(() {
        _results = results;
        _resultGlosses = null;
      });
      final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      final glosses = await WordDecks.glosses([for (final r in results) r.$1], language);
      if (mounted && identical(results, _results)) setState(() => _resultGlosses = glosses);
    });
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final groups = <String, List<WordCategory>>{};
    for (final c in section.categories) {
      groups.putIfAbsent(c.group, () => []).add(c);
    }
    final searching = _search.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text('${section.icon} ${section.title}')),
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
                  TranslatedText(section.intro,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.45)),
                  const SizedBox(height: 6),
                  Text(tr(context, '{c} themes · {w} words and expressions', {'c': section.categories.length, 'w': section.wordCount}),
                      style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _search,
                    onChanged: (v) {
                      setState(() {});
                      _onSearch(v);
                    },
                    decoration: InputDecoration(
                      hintText: tr(context, 'Search in French or English…'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searching
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                _onSearch('');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (searching) ..._buildResults() else
                    for (final entry in groups.entries) ...[
                      if (entry.key.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                          child: Text(entry.key.toUpperCase(),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                  letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textTertiary)),
                        ),
                      for (final c in entry.value) _categoryTile(c),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResults() {
    if (_results.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.all(24),
          child: Text(tr(context, 'No word found.'), textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textTertiary)),
        ),
      ];
    }
    return [
      for (var i = 0; i < _results.length; i++)
        WordTile(
          item: _results[i].$1,
          meaning: _resultGlosses?[i].meaning ?? _results[i].$1.en,
          note: _resultGlosses?[i].note ?? _results[i].$1.note,
          cognate: _results[i].$2,
        ),
    ];
  }

  Widget _categoryTile(WordCategory c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.fg.withValues(alpha: 0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WordCategoryPage(category: c))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(c.icon, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary)),
                      const SizedBox(height: 2),
                      Text(_subtitles[c.subtitle] ?? c.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('${c.items.length}', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                Icon(Icons.chevron_right, color: AppTheme.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
