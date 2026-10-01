import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/missions_data.dart';
import '../../data/word_bank.dart';
import '../../services/global_scroll_manager.dart';
import '../../services/language_provider.dart';
import '../../services/practice_logic.dart';
import '../../services/progress_service.dart';
import '../../services/story_service.dart';
import '../../services/tts_service.dart';
import '../../services/word_decks.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';
import '../ai_book/ai_book_page.dart';
import '../games/conjugation_game_page.dart';
import '../games/dictee_page.dart';
import '../games/duel_page.dart';
import '../missions/missions_page.dart';
import '../mistakes/mistakes_page.dart';
import '../roleplay/roleplay_page.dart';
import 'hub_tabs.dart';

/// The home tab: daily goal, streak, reviews, word of the day, mission and
/// quick games.
class TodayTab extends StatefulWidget {
  final VoidCallback onOpenLanguage;
  const TodayTab({super.key, required this.onOpenLanguage});

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  final _scroll = ScrollController();
  StorySeries? _story;

  @override
  void initState() {
    super.initState();
    GlobalScrollManager.register(_scroll);
    StoryService.loadAll().then((all) {
      if (mounted && all.isNotEmpty) setState(() => _story = all.first);
    });
  }

  @override
  void dispose() {
    GlobalScrollManager.unregister(_scroll);
    _scroll.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 5 || h >= 18 ? 'Bonsoir !' : 'Bonjour !';
  }

  static const _days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
  static const _months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final p = context.watch<ProgressService>();
    final now = DateTime.now();
    final mission = missionsOfWeek(DateTime.parse(ProgressService.weekKey())).firstWhere(
      (m) => !p.missionDone(m.id),
      orElse: () => missionsOfWeek(DateTime.parse(ProgressService.weekKey())).first,
    );

    return SafeArea(
      bottom: false,
      child: PageBody(
        controller: _scroll,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Floating(
                distance: 3,
                child: Image.asset('assets/logo.png', width: 48, height: 48, filterQuality: FilterQuality.medium),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (r) => AppTheme.primaryGradient.createShader(r),
                      child: Text(_greeting(),
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                    ),
                    Text('${_days[now.weekday - 1]} ${now.day} ${_months[now.month - 1]}',
                        style: TextStyle(color: AppTheme.textTertiary, fontSize: 15)),
                  ],
                ),
              ),
              _StreakBadge(streak: p.streak),
              IconButton(onPressed: widget.onOpenLanguage, icon: Icon(Icons.language_rounded, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 18),
          Entrance(child: _goalCard(lp, p)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Entrance(
                  index: 1,
                  child: SizedBox(
                    height: 150,
                    child: FeatureTile(
                      emoji: '🔁',
                      title: p.dueCount > 0 ? '${p.dueCount} ${lp.translate('cards_to_review')}' : lp.translate('all_reviewed'),
                      subtitle: 'Spaced repetition: each card comes back just before you forget it',
                      color: AppTheme.success,
                      onTap: () => openReviews(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Entrance(
                  index: 2,
                  child: SizedBox(
                    height: 150,
                    child: FeatureTile(
                      emoji: '📒',
                      title: '${p.mistakes.length} · ${lp.translate('mistakes')}',
                      subtitle: 'Turn your mistakes into progress',
                      color: AppTheme.error,
                      onTap: () => openPage(context, const MistakesPage()),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SectionTitle(lp.translate('word_of_day')),
          Entrance(index: 3, child: _WordOfDayCard(word: WordOfTheDay.forDay(now))),
          SectionTitle(
            lp.translate('missions'),
            trailing: TextButton(onPressed: () => openPage(context, const MissionsPage()), child: const Text('→')),
          ),
          Entrance(index: 4, child: MissionCard(mission: mission)),
          if (_story != null) ...[
            SectionTitle(lp.translate('continue_story')),
            Entrance(
              index: 5,
              child: Tilt3D(
                maxTilt: 0.1,
                onTap: () => openPage(context, const AIBookPage()),
                child: GlassCard(
                  glow: Colors.amber,
                  child: Row(
                    children: [
                      Text(storyGenres[_story!.genre]?.$1 ?? '📖', style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_story!.title,
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            Text('Chapitre ${_story!.chapters.length + 1} · « ${_story!.teaser} »',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_circle_fill_rounded, color: Colors.amber, size: 36),
                    ],
                  ),
                ),
              ),
            ),
          ],
          SectionTitle(lp.translate('quick_play')),
          FeatureGrid(tiles: [
            FeatureTile(emoji: '🎯', title: lp.translate('conj_game'), subtitle: '10 verbs against the clock',
                color: AppTheme.warning, onTap: () => openPage(context, const ConjugationGamePage())),
            FeatureTile(emoji: '🎭', title: lp.translate('roleplay'), subtitle: 'Real situations with AI',
                color: AppTheme.secondary, onTap: () => openPage(context, const RoleplayPage())),
            FeatureTile(emoji: '🎧', title: lp.translate('dictee'), subtitle: 'Listen and write',
                color: AppTheme.primary, onTap: () => openPage(context, const DicteePage())),
            FeatureTile(emoji: '⚔️', title: lp.translate('duel'), subtitle: 'Challenge your classmate',
                color: const Color(0xFFF97316), onTap: () => openPage(context, const DuelPage())),
          ]),
        ],
      ),
    );
  }

  Widget _goalCard(LanguageProvider lp, ProgressService p) {
    final done = p.todayXp >= p.dailyGoal;
    return GlassCard(
      glow: done ? AppTheme.success : AppTheme.primary,
      child: Row(
        children: [
          GoalRing(
            progress: p.goalProgress,
            size: 116,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(done ? '🏆' : '${p.todayXp}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                Text('/ ${p.dailyGoal} XP', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lp.translate('daily_goal'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                TranslatedText(
                  done ? 'Goal reached! Bravo, see you tomorrow to keep your streak.' : 'Every card, game and exercise gives you XP.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 12),
                GlowButton(
                  label: lp.translate('start_now'),
                  icon: Icons.bolt_rounded,
                  onPressed: () => p.dueCount > 0 ? openReviews(context) : openPage(context, const ConjugationGamePage()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    final lit = streak > 0;
    return Floating(
      distance: 3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: lit ? [const Color(0xFFF97316), AppTheme.warning] : [AppTheme.surface, AppTheme.surfaceLight],
          ),
          borderRadius: BorderRadius.circular(100),
          boxShadow: lit ? [BoxShadow(color: const Color(0xFFF97316).withValues(alpha: 0.5), blurRadius: 16)] : null,
        ),
        child: Text('🔥 $streak', style: TextStyle(fontWeight: FontWeight.w900, color: lit ? AppTheme.onColor : AppTheme.textPrimary, fontSize: 16)),
      ),
    );
  }
}

/// Flip card: the French word on the front, its meaning on the back.
class _WordOfDayCard extends StatefulWidget {
  final WordItem word;
  const _WordOfDayCard({required this.word});

  @override
  State<_WordOfDayCard> createState() => _WordOfDayCardState();
}

class _WordOfDayCardState extends State<_WordOfDayCard> {
  bool _flipped = false;
  WordGloss? _gloss;
  AppLanguage? _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = context.watch<LanguageProvider>().currentLanguage;
    if (language != _language) {
      _language = language;
      WordDecks.glosses([widget.word], language).then((g) {
        if (mounted) setState(() => _gloss = g.first);
      });
    }
  }

  Map<String, String> get _card => {
        'front': widget.word.fr,
        'back': _gloss?.meaning ?? widget.word.en,
        'example': widget.word.example,
        'tip': _gloss?.note ?? widget.word.note,
      };

  @override
  Widget build(BuildContext context) {
    final w = widget.word;
    final inReviews = context.watch<ProgressService>().inReviews(w.fr);
    return GestureDetector(
      onTap: () => setState(() => _flipped = !_flipped),
      child: SizedBox(
        height: 190,
        child: Flip3D(
          flipped: _flipped,
          front: _face(
            gradient: [AppTheme.primary, AppTheme.accent],
            children: [
              Text(w.fr,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.onColor)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.volume_up_rounded, color: AppTheme.onColor),
                    onPressed: () => TtsService.instance.speak(w.fr),
                  ),
                  Text('Touche pour retourner', style: TextStyle(color: AppTheme.onColor.withValues(alpha: 0.6))),
                ],
              ),
            ],
          ),
          back: _face(
            gradient: [AppTheme.secondary, Color(0xFFF97316)],
            children: [
              Text(_gloss?.meaning ?? w.en,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.onColor)),
              if (w.example.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('« ${w.example} »',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: AppTheme.onColor, fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: inReviews ? null : () => context.read<ProgressService>().addToReviews(_card),
                icon: Icon(inReviews ? Icons.check_rounded : Icons.add_rounded, color: AppTheme.onColor),
                label: Text(inReviews ? 'Dans tes révisions' : 'Ajouter aux révisions',
                    style: TextStyle(color: AppTheme.onColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _face({required List<Color> gradient, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: gradient.first.withValues(alpha: 0.45), blurRadius: 26, offset: const Offset(0, 12))],
      ),
      child: Center(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: children))),
    );
  }
}
