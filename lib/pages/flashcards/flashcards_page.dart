import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/deepseek_service.dart';
import '../../services/language_provider.dart';
import '../../services/lessons_provider.dart';
import '../../services/global_scroll_manager.dart';
import '../../services/topic_context.dart';
import '../../widgets/grammar_cards.dart';

class FlashcardsPage extends StatefulWidget {
  final String? initialTopic;
  const FlashcardsPage({super.key, this.initialTopic});

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

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    GlobalScrollManager.register(_scrollController);
    if (widget.initialTopic != null) {
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

  Future<void> _startAIFlashcards(String topic) async {
    setState(() {
      selectedTopic = topic;
      _isLoading = true;
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
          const SnackBar(content: Text('Could not create flashcards. Please try again.')),
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
          Text('Professeur AI is making your cards…', style: Theme.of(context).textTheme.bodyLarge),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.5),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('12 cards from this lesson',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.auto_awesome, color: AppTheme.secondary, size: 20),
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
                tooltip: 'Back to topics',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => selectedTopic = null),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_roundNumber > 1 ? 'Review · ' : ''}${_index + 1} / ${_round.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textTertiary),
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
                tooltip: 'Shuffle',
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
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
                        icon: const Icon(Icons.replay_rounded, color: AppTheme.error),
                        label: const Text('À revoir'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: AppTheme.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _answer(true),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Je savais'),
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
                  label: const Text('Show answer'),
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
        Text('FRANÇAIS',
            style: TextStyle(letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.6))),
        const SizedBox(height: 24),
        Text(card['front']!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        SpeakButton(card['front']!, color: Colors.white),
        const SizedBox(height: 16),
        Text('Tap to flip', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
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
            style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 12),
        Text(card['back']!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        if (example.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text('« $example »',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white)),
              ),
              SpeakButton(example, color: Colors.white),
            ],
          ),
        ],
        if (tip.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            // The tip is in the learner's language, which may be right-to-left.
            child: Directionality(
              textDirection: Directionality.of(context),
              child: Text('💡 $tip',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4)),
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
          Text('✓ $_known of $total known   ·   ✗ ${_missed.length} to review',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
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
              label: Text('Review the ${_missed.length} card(s) I missed'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _startAIFlashcards(selectedTopic!),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('New cards for this topic'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => selectedTopic = null),
            child: const Text('Back to topics'),
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
        style: const TextStyle(
          letterSpacing: 1.5,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textTertiary,
        ),
      ),
    );
  }
}
