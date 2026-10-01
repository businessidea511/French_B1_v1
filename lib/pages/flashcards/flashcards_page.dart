import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/deepseek_service.dart';
import '../../services/language_provider.dart';
import '../../services/lessons_provider.dart';
import '../../services/global_scroll_manager.dart';
import '../../services/topic_context.dart';
import '../../services/word_decks.dart';
import '../../services/progress_service.dart';
import '../../data/word_bank.dart';
import '../../widgets/grammar_cards.dart';
import '../../services/ui_strings.dart';

class FlashcardsPage extends StatefulWidget {
  final String? initialTopic;

  /// A ready-made deck (e.g. a vocabulary list) to study straight away.
  final List<Map<String, String>>? deck;
  final String? deckTitle;

  const FlashcardsPage({super.key, this.initialTopic, this.deck, this.deckTitle});

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> {
  String? selectedTopic;
  bool _isLoading = false;

  /// Cards of the current round, and what the learner answered for each.
  List<Map<String, String>> _round = [];
  final List<Map<String, String>> _missed = [];
  int _index = 0;
  int _known = 0;
  bool _flipped = false;
  int _roundNumber = 1;

  /// Set when studying a fixed word list instead of AI cards. Big lists are
  /// studied [_roundSize] cards at a time; [_queue] holds the cards not seen yet.
  List<Map<String, String>>? _staticDeck;
  List<Map<String, String>> _queue = [];
  static const int _roundSize = 20;
  String _loadingText = 'Professeur AI is making your cards…';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    GlobalScrollManager.register(_scrollController);
    if (widget.deck != null) {
      selectedTopic = widget.deckTitle ?? 'Flashcards';
      _startStatic(widget.deck!);
    } else if (widget.initialTopic != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAIFlashcards(widget.initialTopic!);
      });
    }
  }

  @override
  void dispose() {
    GlobalScrollManager.unregister(_scrollController);
    _scrollController.dispose();
    super.dispose();
  }

  void _startStatic(List<Map<String, String>> cards) {
    _staticDeck = cards;
    _queue = List.of(cards)..shuffle();
    _roundNumber = 1;
    _nextBatch();
  }

  void _nextBatch() {
    final batch = _queue.take(_roundSize).toList();
    _queue = _queue.skip(_roundSize).toList();
    _startRound(batch);
  }

  Future<void> _openWordDeck(WordCategory category) async {
    setState(() {
      _isLoading = true;
      _loadingText = 'Preparing your cards…';
    });
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final glosses = await WordDecks.glosses(category.items, language);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      selectedTopic = category.title;
      _startStatic(WordDecks.cards(category, glosses));
    });
  }

  void _backToTopics() {
    if (widget.deck != null) {
      Navigator.pop(context);
    } else {
      setState(() => selectedTopic = null);
    }
  }

  Future<void> _startAIFlashcards(String topic) async {
    setState(() {
      selectedTopic = topic;
      _isLoading = true;
      _staticDeck = null;
      _loadingText = 'Professeur AI is making your cards…';
    });

    try {
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      final topicContent = TopicContext.forTitle(Provider.of<LessonsProvider>(context, listen: false), topic);
      final cards = await DeepSeekService.generateFlashcards(
        topic,
        lp.currentLanguage.englishName,
        topicContent: topicContent,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _roundNumber = 1;
          _startRound(cards);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          selectedTopic = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'Could not create flashcards. Please try again.'))),
        );
      }
    }
  }

  void _startRound(List<Map<String, String>> cards) {
    _round = List.of(cards);
    _missed.clear();
    _index = 0;
    _known = 0;
    _flipped = false;
  }

  void _answer(bool knewIt) {
    ProgressService.instance.recordCard(_round[_index], knewIt);
    setState(() {
      if (knewIt) {
        _known++;
      } else {
        _missed.add(_round[_index]);
      }
      _index++;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(selectedTopic ?? 'Flashcards')),
      body: _isLoading
          ? _buildLoadingState()
          : selectedTopic == null
              ? _buildTopicSelection()
              : _index >= _round.length
                  ? _buildRoundSummary()
                  : _buildStudy(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(_loadingText, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  // ── Topic list ─────────────────────────────────────────────────────────────

  Widget _buildTopicSelection() {
    final lessonsProvider = Provider.of<LessonsProvider>(context);
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        for (final section in WordDecks.sections)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
            child: ExpansionTile(
              shape: const Border(),
              leading: Text(section.icon, style: const TextStyle(fontSize: 26)),
              title: Text(section.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
              subtitle: Text(tr(context, '{decks} decks · {cards} cards', {'decks': section.categories.length, 'cards': section.wordCount}),
                  style: TextStyle(color: AppTheme.fg.withValues(alpha: 0.4), fontSize: 13)),
              children: [
                for (final c in section.categories)
                  ListTile(
                    leading: Text(c.icon, style: const TextStyle(fontSize: 22)),
                    title: Text(c.title, textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.textPrimary)),
                    trailing: Text('${c.items.length}', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                    onTap: () => _openWordDeck(c),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        const SectionHeader('GRAMMAR FLASHCARDS'),
        ...lessonsProvider.allGrammar.map((t) => _buildTopicTile(t.title, t.icon)),
        const SizedBox(height: 24),
        const SectionHeader('LESSON FLASHCARDS'),
        ...lessonsProvider.allLessons.map((t) => _buildTopicTile(t.title, t.icon)),
      ],
    );
  }

  Widget _buildTopicTile(String title, String icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.fg.withValues(alpha: 0.05), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startAIFlashcards(title),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
                      const SizedBox(height: 2),
                      Text(tr(context, '{n} cards from this lesson', {'n': 12}),
                          style: TextStyle(color: AppTheme.fg.withValues(alpha: 0.4), fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.auto_awesome, color: AppTheme.secondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Study ──────────────────────────────────────────────────────────────────

  Widget _buildStudy() {
    final card = _round[_index];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: tr(context, 'Back to topics'),
                icon: const Icon(Icons.close),
                onPressed: _backToTopics,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_roundNumber > 1 ? 'Review · ' : ''}${_index + 1} / ${_round.length}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textTertiary),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _index / _round.length,
                        minHeight: 6,
                        backgroundColor: AppTheme.surface,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: tr(context, 'Shuffle'),
                icon: const Icon(Icons.shuffle),
                onPressed: () => setState(() {
                  final rest = _round.sublist(_index)..shuffle();
                  _round = [..._round.sublist(0, _index), ...rest];
                  _flipped = false;
                }),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('✓ $_known   ✗ ${_missed.length}',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: _flipped ? pi : 0),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                builder: (context, angle, _) {
                  final showBack = angle > pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: showBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(pi),
                            child: _buildBack(card),
                          )
                        : _buildFront(card),
                  );
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: _flipped
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _answer(false),
                        icon: Icon(Icons.replay_rounded, color: AppTheme.error),
                        label: Text(tr(context, 'To review')),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: BorderSide(color: AppTheme.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _answer(true),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(tr(context, 'I knew it')),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                )
              : ElevatedButton.icon(
                  onPressed: () => setState(() => _flipped = true),
                  icon: const Icon(Icons.flip_rounded),
                  label: Text(tr(context, 'Show answer')),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
        ),
      ],
    );
  }

  Widget _cardShell({required Gradient gradient, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }

  Widget _buildFront(Map<String, String> card) {
    return _cardShell(
      gradient: AppTheme.studyFrontGradient,
      children: [
        Text(switch (WordDecks.gender(card['front']!)) { 'm' => 'FRANÇAIS · ♂ MASCULIN', 'f' => 'FRANÇAIS · ♀ FÉMININ', _ => 'FRANÇAIS' },
            style: TextStyle(letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.onColor.withValues(alpha: 0.6))),
        const SizedBox(height: 24),
        Text(card['front']!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.onColor)),
        const SizedBox(height: 12),
        SpeakButton(card['front']!, color: AppTheme.onColor),
        const SizedBox(height: 16),
        Text(tr(context, 'Tap to flip'), style: TextStyle(color: AppTheme.onColor.withValues(alpha: 0.5), fontSize: 13)),
      ],
    );
  }

  Widget _buildBack(Map<String, String> card) {
    final example = card['example'] ?? '';
    final tip = card['tip'] ?? '';
    return _cardShell(
      gradient: AppTheme.studyBackGradient,
      children: [
        Text(card['front']!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppTheme.onColor.withValues(alpha: 0.7))),
        const SizedBox(height: 12),
        Text(card['back']!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.onColor)),
        if (example.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text('« $example »',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: AppTheme.onColor)),
              ),
              SpeakButton(example, color: AppTheme.onColor),
            ],
          ),
        ],
        if (tip.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.onColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            // The tip is in the learner's language, which may be right-to-left.
            child: Directionality(
              textDirection: Directionality.of(context),
              child: Text('💡 $tip',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppTheme.onColor, height: 1.4)),
            ),
          ),
        ],
      ],
    );
  }

  // ── End of a round ─────────────────────────────────────────────────────────

  Widget _buildRoundSummary() {
    final total = _round.length;
    final allKnown = _missed.isEmpty;
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(allKnown ? '🏆' : '💪', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(allKnown ? 'Bravo ! You know all of them.' : 'Round complete',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text('✓ ${tr(context, '{known} of {total} known', {'known': _known, 'total': total})}   ·   ✗ ${tr(context, '{n} to review', {'n': _missed.length})}',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          if (!allKnown) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final c in _missed)
                  Chip(label: Text('${c['front']} → ${c['back']}', style: const TextStyle(fontSize: 13))),
              ],
            ),
          ],
          const SizedBox(height: 32),
          if (!allKnown)
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _roundNumber++;
                _startRound(List.of(_missed)..shuffle());
              }),
              icon: const Icon(Icons.replay_rounded),
              label: Text(tr(context, 'Review the {n} cards I missed', {'n': _missed.length})),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          const SizedBox(height: 12),
          if (_staticDeck == null)
            OutlinedButton.icon(
              onPressed: () => _startAIFlashcards(selectedTopic!),
              icon: const Icon(Icons.auto_awesome),
              label: Text(tr(context, 'New cards for this topic')),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            )
          else if (_queue.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _roundNumber = 1;
                _nextBatch();
              }),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(tr(context, 'Next {n} cards ({left} left)', {'n': min(_roundSize, _queue.length), 'left': _queue.length})),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            )
          else
            OutlinedButton.icon(
              onPressed: () => setState(() => _startStatic(_staticDeck!)),
              icon: const Icon(Icons.shuffle_rounded),
              label: Text(tr(context, 'Start again with all {n} cards', {'n': _staticDeck!.length})),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _backToTopics,
            child: Text(widget.deck != null ? 'Back to the list' : 'Back to topics'),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 8),
      child: Text(
        title,
        style: TextStyle(
          letterSpacing: 1.5,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textTertiary,
        ),
      ),
    );
  }
}
