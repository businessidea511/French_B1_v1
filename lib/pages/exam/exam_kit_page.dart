import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/exam_kit.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../services/ui_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/french_meaning.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';
import '../games/dictee_page.dart';
import 'writing_practice_page.dart';

const _colors = [0xFF5B6CF0, 0xFF23A07F, 0xFFE0604A, 0xFFC98A0E, 0xFF9B59D0, 0xFF3D8BE0, 0xFFE0457B];

/// "✍️ Exam writing kit": phrases that fit any text, a plan for any story,
/// the check before handing in, and the ways to practise them.
class ExamKitPage extends StatelessWidget {
  const ExamKitPage({super.key});

  void _open(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('✍️ ${tr(context, 'Exam writing kit')}')),
      body: PageBody(
        children: [
          TranslatedText(
            'Learn these phrases and this plan by heart: they fit any subject and already show the grammar the teacher looks for.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            emoji: '🧠',
            title: tr(context, 'Learn the phrases by heart'),
            subtitle: 'Find the missing word, 10 questions',
            color: AppTheme.primary,
            onTap: () => _open(context, const PhraseGamePage()),
          ),
          _ActionCard(
            emoji: '📝',
            title: tr(context, 'Writing practice'),
            subtitle: 'An exam subject, a timer, and a correction out of 20',
            color: AppTheme.success,
            onTap: () => _open(context, const WritingPracticePage()),
          ),
          _ActionCard(
            emoji: '🎧',
            title: tr(context, "Today's dictation"),
            subtitle: '6 new sentences every day with the exam grammar',
            color: AppTheme.secondary,
            onTap: () => _open(
              context,
              DicteePage(sentences: dailyDictation(ProgressService.now()), title: tr(context, "Today's dictation")),
            ),
          ),
          SectionTitle('🃏 ${tr(context, 'My joker phrases')}'),
          for (final (i, p) in jokerPhrases.indexed)
            Entrance(index: i, child: _PhraseCard(number: i + 1, phrase: p, color: Color(_colors[i % _colors.length]))),
          SectionTitle('🗺️ ${tr(context, 'A plan for any story')}'),
          for (final (i, step) in storyPlan.indexed) Entrance(index: i, child: _StepCard(number: i + 1, step: step)),
          SectionTitle('✅ ${tr(context, 'The 2-minute check')}'),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, item) in examChecklist.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}.', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary)),
                        const SizedBox(width: 8),
                        Expanded(child: TranslatedText(item, style: TextStyle(color: AppTheme.textPrimary, height: 1.4))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.emoji, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Tilt3D(
        maxTilt: 0.08,
        onTap: onTap,
        child: GlassCard(
          glow: color,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                    TranslatedText(subtitle, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhraseCard extends StatefulWidget {
  final int number;
  final JokerPhrase phrase;
  final Color color;
  const _PhraseCard({required this.number, required this.phrase, required this.color});

  @override
  State<_PhraseCard> createState() => _PhraseCardState();
}

class _PhraseCardState extends State<_PhraseCard> {
  bool _meaning = false;

  int get number => widget.number;
  JokerPhrase get phrase => widget.phrase;
  Color get color => widget.color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        glow: color,
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text(number > 6 ? '★' : '$number', style: TextStyle(color: AppTheme.onColor, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phrase.french,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.35)),
                  if (_meaning)
                    Padding(padding: const EdgeInsets.only(top: 4), child: FrenchMeaning(french: phrase.french, english: phrase.english)),
                  const SizedBox(height: 6),
                  TranslatedText(phrase.where, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.35)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(phrase.grammar,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: tr(context, 'Listen'),
                  icon: Icon(Icons.volume_up_rounded, color: color),
                  onPressed: () => TtsService.instance.speak(phrase.french),
                ),
                TranslateButton(active: _meaning, color: color, onPressed: () => setState(() => _meaning = !_meaning)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatefulWidget {
  final int number;
  final StoryStep step;
  const _StepCard({required this.number, required this.step});

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _meaning = false;

  int get number => widget.number;
  StoryStep get step => widget.step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(step.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: TranslatedText('$number. ${step.title}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      Text(step.tense,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(step.example,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, fontStyle: FontStyle.italic, height: 1.35)),
                  if (_meaning)
                    Padding(padding: const EdgeInsets.only(top: 4), child: FrenchMeaning(french: step.example, english: step.english)),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: tr(context, 'Listen'),
                  icon: Icon(Icons.volume_up_rounded, color: AppTheme.primary),
                  onPressed: () => TtsService.instance.speak(step.example),
                ),
                TranslateButton(active: _meaning, onPressed: () => setState(() => _meaning = !_meaning)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One question of the game: a phrase with a blank and 4 choices.
class PhraseQuestion {
  final JokerPhrase phrase;
  final PhraseGap gap;
  final List<String> options;
  const PhraseQuestion(this.phrase, this.gap, this.options);

  static List<PhraseQuestion> round(Random random, {int count = 10}) {
    final all = [
      for (final p in jokerPhrases)
        for (final g in p.gaps) (p, g),
    ]..shuffle(random);
    return [
      for (final (p, g) in all.take(count)) PhraseQuestion(p, g, ([g.answer, ...g.wrong.take(3)]..shuffle(random))),
    ];
  }
}

/// Learn the joker phrases by heart: find the missing word.
class PhraseGamePage extends StatefulWidget {
  final Random? random;
  const PhraseGamePage({super.key, this.random});

  @override
  State<PhraseGamePage> createState() => _PhraseGamePageState();
}

class _PhraseGamePageState extends State<PhraseGamePage> {
  late List<PhraseQuestion> _questions;
  int _index = 0;
  int _score = 0;
  String? _chosen;
  bool _meaning = false;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _questions = PhraseQuestion.round(widget.random ?? Random());
    _index = 0;
    _score = 0;
    _chosen = null;
  }

  void _choose(String option) {
    if (_chosen != null) return;
    final q = _questions[_index];
    final right = option == q.gap.answer;
    setState(() {
      _chosen = option;
      if (right) _score++;
    });
    ProgressService.instance.addXp(right ? 2 : 1);
    if (!right) {
      ProgressService.instance.addMistake(
        source: 'Exam kit',
        question: q.phrase.withBlank(q.gap),
        wrong: option,
        right: q.gap.answer,
        explanation: q.gap.why,
      );
    }
    TtsService.instance.speak(q.phrase.french);
  }

  void _next() {
    setState(() {
      _index++;
      _chosen = null;
      _meaning = false;
    });
    if (_index >= _questions.length && _score >= 8) Confetti.burst(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🧠 ${tr(context, 'Learn the phrases by heart')}')),
      body: _index >= _questions.length ? _end() : _question(),
    );
  }

  Widget _end() {
    return PageBody(
      children: [
        const SizedBox(height: 30),
        Center(child: Text(_score >= 8 ? '🏆' : '💪', style: const TextStyle(fontSize: 72))),
        const SizedBox(height: 10),
        Center(
          child: Text('$_score / ${_questions.length}',
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
        ),
        const SizedBox(height: 10),
        TranslatedText(
          _score >= 8
              ? 'Excellent! Now write a text and use them.'
              : 'Read the phrases once more and play again: repetition puts them in your memory.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 22),
        GlowButton(label: tr(context, 'Play again'), icon: Icons.replay_rounded, onPressed: () => setState(_newRound)),
      ],
    );
  }

  Widget _question() {
    final q = _questions[_index];
    final answered = _chosen != null;
    return PageBody(
      key: ValueKey(_index),
      children: [
        Row(
          children: [
            Text('${_index + 1} / ${_questions.length}',
                textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.textTertiary, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('⭐ $_score', textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          glow: AppTheme.primary,
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      answered ? q.phrase.french : q.phrase.withBlank(q.gap),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.4),
                    ),
                  ),
                  TranslateButton(active: _meaning, onPressed: () => setState(() => _meaning = !_meaning)),
                ],
              ),
              if (_meaning) FrenchMeaning(french: q.phrase.french, english: q.phrase.english),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TranslatedText(q.phrase.where, style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
        const SizedBox(height: 18),
        for (final option in q.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionButton(
              label: option,
              state: !answered
                  ? null
                  : option == q.gap.answer
                      ? true
                      : option == _chosen
                          ? false
                          : null,
              onTap: () => _choose(option),
            ),
          ),
        if (answered) ...[
          const SizedBox(height: 4),
          GlassCard(
            glow: _chosen == q.gap.answer ? AppTheme.success : AppTheme.warning,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text(_chosen == q.gap.answer ? '✅ ' : '💡 ', style: const TextStyle(fontSize: 18)),
                Expanded(child: TranslatedText(q.gap.why, style: TextStyle(color: AppTheme.textPrimary, height: 1.35))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlowButton(
            label: tr(context, _index + 1 >= _questions.length ? 'Results' : 'Next'),
            icon: Icons.arrow_forward_rounded,
            onPressed: _next,
          ),
        ],
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final bool? state; // true: right answer, false: wrong choice
  final VoidCallback onTap;
  const _OptionButton({required this.label, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = state == true
        ? AppTheme.success
        : state == false
            ? AppTheme.error
            : AppTheme.fg.withValues(alpha: 0.25);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: state == null ? AppTheme.surface : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(label,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ),
    );
  }
}
