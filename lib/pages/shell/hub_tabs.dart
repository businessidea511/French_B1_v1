import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/expressions_data.dart';
import '../../data/street_french_data.dart';
import '../../data/vocabulary_data.dart';
import '../../services/global_scroll_manager.dart';
import '../../services/language_provider.dart';
import '../../services/progress_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import '../ai_book/ai_book_page.dart';
import '../daily_phrases/daily_phrases_page.dart';
import '../exercises/exercises_page.dart';
import '../flashcards/flashcards_page.dart';
import '../games/conjugation_game_page.dart';
import '../games/dictee_page.dart';
import '../games/duel_page.dart';
import '../grammar/grammar_page.dart';
import '../lessons/lessons_page.dart';
import '../listening/listening_page.dart';
import '../missions/missions_page.dart';
import '../mistakes/mistakes_page.dart';
import '../roleplay/roleplay_page.dart';
import '../verbs/verbs_page.dart';
import '../words/photo_words_page.dart';
import '../words/word_section_page.dart';
import '../../services/ui_strings.dart';

void openPage(BuildContext context, Widget page) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));

/// Opens today's due flashcards (spaced repetition).
void openReviews(BuildContext context) {
  final due = context.read<ProgressService>().dueCards;
  if (due.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ ${tr(context, 'Nothing to review today. Study new cards!')}')),
    );
    openPage(context, const FlashcardsPage());
    return;
  }
  openPage(context, FlashcardsPage(deck: due, deckTitle: 'Révisions'));
}

/// A tab made of a title, an intro line and a grid of feature tiles.
class HubTab extends StatefulWidget {
  final String title;
  final String intro; // English, translated on screen
  final List<Widget> Function(BuildContext context) tiles;
  const HubTab({super.key, required this.title, required this.intro, required this.tiles});

  @override
  State<HubTab> createState() => _HubTabState();
}

class _HubTabState extends State<HubTab> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    GlobalScrollManager.register(_scroll);
  }

  @override
  void dispose() {
    GlobalScrollManager.unregister(_scroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: PageBody(
        controller: _scroll,
        children: [
          const SizedBox(height: 12),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (r) => AppTheme.primaryGradient.createShader(r),
            child: Text(widget.title, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          ),
          const SizedBox(height: 18),
          FeatureGrid(tiles: widget.tiles(context)),
        ],
      ),
    );
  }
}

class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    return HubTab(
      title: lp.translate('tab_learn'),
      intro: '',
      tiles: (context) => [
        FeatureTile(emoji: '📚', title: lp.translate('grammar'), subtitle: 'All the B1 rules, explained simply',
            color: AppTheme.primary, onTap: () => openPage(context, const GrammarPage())),
        FeatureTile(emoji: '📖', title: lp.translate('lessons'), subtitle: 'Themed lessons with exercises',
            color: Colors.purple, onTap: () => openPage(context, const LessonsPage())),
        FeatureTile(emoji: '🔄', title: lp.translate('verbs'), subtitle: 'Every verb in every tense',
            color: AppTheme.warning, onTap: () => openPage(context, const VerbsPage())),
        FeatureTile(emoji: '🗣️', title: lp.translate('daily_phrases'), subtitle: 'Ready-made sentences for daily life',
            color: Colors.indigo, onTap: () => openPage(context, const DailyPhrasesPage())),
        FeatureTile(emoji: '🎧', title: lp.translate('listening'), subtitle: 'Train your ear with real dialogues',
            color: Colors.teal, onTap: () => openPage(context, const ListeningPage())),
        FeatureTile(emoji: '✨', title: lp.translate('ai_book'), subtitle: 'A thrilling story, one chapter at a time',
            color: Colors.amber, onTap: () => openPage(context, const AIBookPage())),
      ],
    );
  }
}

class PracticeTab extends StatelessWidget {
  const PracticeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final progress = context.watch<ProgressService>();
    final due = progress.dueCount;
    final mistakes = progress.mistakes.length;
    return HubTab(
      title: lp.translate('tab_practice'),
      intro: '',
      tiles: (context) => [
        FeatureTile(emoji: '🔁', title: lp.translate('reviews'), subtitle: 'Smart flashcards at the right moment',
            color: AppTheme.success, badge: due > 0 ? '$due' : null, onTap: () => openReviews(context)),
        FeatureTile(emoji: '🎯', title: lp.translate('conj_game'), subtitle: '10 verbs, 20 seconds each, combos!',
            color: AppTheme.warning, onTap: () => openPage(context, const ConjugationGamePage())),
        FeatureTile(emoji: '🎭', title: lp.translate('roleplay'), subtitle: 'Talk with AI in real Belgian situations',
            color: AppTheme.secondary, onTap: () => openPage(context, const RoleplayPage())),
        FeatureTile(emoji: '🎧', title: lp.translate('dictee'), subtitle: 'Listen and write: spelling + ear',
            color: AppTheme.primary, onTap: () => openPage(context, const DicteePage())),
        FeatureTile(emoji: '⚔️', title: lp.translate('duel'), subtitle: 'Same 10 questions — who wins?',
            color: const Color(0xFFF97316), onTap: () => openPage(context, const DuelPage())),
        FeatureTile(emoji: '📒', title: lp.translate('mistakes'), subtitle: 'Fix your own mistakes',
            color: AppTheme.error, badge: mistakes > 0 ? '$mistakes' : null, onTap: () => openPage(context, const MistakesPage())),
        FeatureTile(emoji: '✍️', title: lp.translate('exercises'), subtitle: 'New exercises on any topic',
            color: AppTheme.accent, onTap: () => openPage(context, const ExercisesPage())),
        FeatureTile(emoji: '🎴', title: lp.translate('flashcards'), subtitle: 'Cards for every topic and word list',
            color: Colors.lightGreen, onTap: () => openPage(context, const FlashcardsPage())),
        FeatureTile(emoji: '🗺️', title: lp.translate('missions'), subtitle: 'Use your French in real life',
            color: Colors.cyan, onTap: () => openPage(context, const MissionsPage())),
      ],
    );
  }
}

class WordsTab extends StatelessWidget {
  const WordsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final saved = context.watch<ProgressService>().savedWords.length;
    return HubTab(
      title: lp.translate('tab_words'),
      intro: '',
      tiles: (context) => [
        FeatureTile(emoji: '📗', title: lp.translate('vocabulary'), subtitle: 'Daily words, verbs and English look-alikes',
            color: Colors.lightGreen, onTap: () => openPage(context, const WordSectionPage(section: vocabularySection))),
        FeatureTile(emoji: '💬', title: lp.translate('expressions'), subtitle: 'Speak like a local',
            color: Colors.orange, onTap: () => openPage(context, const WordSectionPage(section: expressionsSection))),
        FeatureTile(emoji: '🛹', title: lp.translate('street_french'), subtitle: 'Slang, verlan, SMS and Belgian French',
            color: Colors.cyan, onTap: () => openPage(context, const WordSectionPage(section: streetFrenchSection))),
        FeatureTile(emoji: '📸', title: lp.translate('photo_words'), subtitle: 'Take a photo, get the French words',
            color: AppTheme.secondary, onTap: () => openPage(context, const PhotoWordsPage())),
        FeatureTile(emoji: '⭐', title: lp.translate('my_words'), subtitle: 'The words you saved',
            color: AppTheme.warning, badge: saved > 0 ? '$saved' : null, onTap: () => openPage(context, const MyWordsPage())),
      ],
    );
  }
}
