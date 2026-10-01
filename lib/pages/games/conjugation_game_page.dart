import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/verb_list.dart';
import '../../services/practice_logic.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';
import '../../services/ui_strings.dart';

/// Timed conjugation game: 10 verbs, 20 seconds each, combos and records.
class ConjugationGamePage extends StatefulWidget {
  const ConjugationGamePage({super.key});

  @override
  State<ConjugationGamePage> createState() => _ConjugationGamePageState();
}

enum _Phase { setup, question, feedback, end }

class _ConjugationGamePageState extends State<ConjugationGamePage> with SingleTickerProviderStateMixin {
  static const int _rounds = 10;
  static const int _seconds = 20;

  final _random = Random();
  final _input = TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _timer =
      AnimationController(vsync: this, duration: const Duration(seconds: _seconds))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed && _phase == _Phase.question) _submit(timeUp: true);
        });

  _Phase _phase = _Phase.setup;
  String _level = 'Facile';
  late ConjQuestion _q;
  int _round = 0;
  int _score = 0;
  int _correct = 0;
  int _combo = 0;
  int _gained = 0;
  AnswerResult? _result;
  bool _newRecord = false;
  final List<(ConjQuestion, String)> _misses = [];

  @override
  void dispose() {
    _timer.dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _recordKey => 'conj_$_level';

  void _start() {
    setState(() {
      _round = 0;
      _score = 0;
      _correct = 0;
      _combo = 0;
      _misses.clear();
    });
    _next();
  }

  void _next() {
    if (_round >= _rounds) return _finish();
    setState(() {
      _q = ConjugationQuiz.make(_random, _level);
      _round++;
      _phase = _Phase.question;
      _result = null;
      _input.clear();
    });
    _timer.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _submit({bool timeUp = false}) {
    if (_phase != _Phase.question) return;
    _timer.stop();
    final result = timeUp ? AnswerResult.wrong : ConjugationQuiz.check(_input.text, _q.answer);
    final timeLeft = ((1 - _timer.value) * _seconds).round();
    var gained = 0;
    if (result == AnswerResult.wrong) {
      _combo = 0;
      _misses.add((_q, _input.text.trim()));
      ProgressService.instance.addMistake(
        source: 'Conjugaison',
        question: '${_q.verb} · ${_q.tenseLabel} · ${_q.prefix} ___',
        wrong: _input.text.trim().isEmpty ? '—' : _input.text.trim(),
        right: _q.answer,
      );
    } else {
      _combo++;
      _correct++;
      final multiplier = min(_combo, 3);
      gained = ((result == AnswerResult.correct ? 10 : 5) + timeLeft ~/ 2) * multiplier;
      _score += gained;
      ProgressService.instance.addXp(2);
    }
    setState(() {
      _result = result;
      _gained = gained;
      _phase = _Phase.feedback;
    });
    TtsService.instance.speak(_q.fullForm);
    if (result == AnswerResult.correct) {
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (mounted && _phase == _Phase.feedback) _next();
      });
    }
  }

  void _finish() {
    _timer.stop();
    final record = ProgressService.instance.saveRecord(_recordKey, _score);
    setState(() {
      _phase = _Phase.end;
      _newRecord = record;
    });
    if (record || _correct >= 8) Confetti.burst(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🎯 ${tr(context, 'Conjugation game')}')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: switch (_phase) {
          _Phase.setup => _buildSetup(),
          _Phase.end => _buildEnd(),
          _ => _buildPlay(),
        },
      ),
    );
  }

  Widget _buildSetup() {
    return PageBody(
      key: const ValueKey('setup'),
      children: [
        const SizedBox(height: 12),
        const Center(child: Floating(child: Text('🎯', style: TextStyle(fontSize: 72)))),
        const SizedBox(height: 12),
        TranslatedText(
          'Conjugate 10 verbs as fast as you can. 20 seconds per verb. Answers in a row multiply your points (×2, ×3)!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.4),
        ),
        SectionTitle(tr(context, 'Level')),
        for (final level in ConjugationQuiz.levels.keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Tilt3D(
              maxTilt: 0.1,
              onTap: () => setState(() => _level = level),
              child: GlassCard(
                glow: _level == level ? AppTheme.warning : null,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(switch (level) { 'Facile' => '🌱', 'Moyen' => '🔥', _ => '🚀' }, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(UiStrings.level(context, level), style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          Text(ConjugationQuiz.levels[level]!.map((t) => t.$1 == 'Indicatif' ? t.$2 : '${t.$1} ${t.$2.toLowerCase()}').join(' · '),
                              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Text('🏆 ${ProgressService.instance.recordOf('conj_$level')}',
                        style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        GlowButton(label: tr(context, 'Play!'), icon: Icons.play_arrow_rounded, onPressed: _start,
            colors: [AppTheme.warning, Color(0xFFF97316)]),
      ],
    );
  }

  Widget _buildPlay() {
    final meaning = commonVerbs[_q.verb];
    final feedback = _phase == _Phase.feedback;
    final color = !feedback
        ? AppTheme.primary
        : switch (_result!) { AnswerResult.correct => AppTheme.success, AnswerResult.accents => AppTheme.warning, _ => AppTheme.error };
    return PageBody(
      key: const ValueKey('play'),
      children: [
        Row(
          children: [
            Text('$_round / $_rounds', textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.textTertiary, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_combo >= 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.secondary, borderRadius: BorderRadius.circular(100)),
                child: Text('🔥 ×${min(_combo, 3)}', style: TextStyle(color: AppTheme.onColor, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 10),
            Text('$_score pts', textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.warning, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _timer,
          builder: (context, _) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 1 - _timer.value,
              minHeight: 8,
              backgroundColor: AppTheme.fg.withValues(alpha: 0.08),
              color: _timer.value > 0.75 ? AppTheme.error : AppTheme.success,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Flip3D(
          flipped: feedback,
          front: _questionCard(meaning),
          back: _feedbackCard(color),
        ),
        const SizedBox(height: 16),
        if (!feedback) ...[
          AccentBar(controller: _input, focusNode: _focus),
          const SizedBox(height: 16),
          GlowButton(label: tr(context, 'Check'), icon: Icons.check_rounded, onPressed: () => _submit()),
        ] else if (_result != AnswerResult.correct)
          GlowButton(label: tr(context, _round >= _rounds ? 'Results' : 'Next'), icon: Icons.arrow_forward_rounded, onPressed: _next),
      ],
    );
  }

  Widget _questionCard(String? meaning) {
    return GlassCard(
      glow: AppTheme.primary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(100)),
              child: Text(_q.tenseLabel, style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(_q.verb, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            if (meaning != null)
              Directionality(
                textDirection: Directionality.of(context),
                child: TranslatedText(meaning, style: TextStyle(color: AppTheme.textTertiary)),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(_q.prefix, style: TextStyle(fontSize: 22, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _input,
                    focusNode: _focus,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: TextStyle(fontSize: 22, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(hintText: '…'),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedbackCard(Color color) {
    final r = _result;
    return GlassCard(
      glow: color,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            Text(switch (r) { AnswerResult.correct => '✅', AnswerResult.accents => '🟡', _ => '❌' },
                style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            if (r == AnswerResult.accents)
              Text(tr(context, 'Almost! Watch the accents.'), style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)),
            if (r == AnswerResult.wrong && _input.text.trim().isNotEmpty)
              Text('${_q.prefix} ${_input.text.trim()}',
                  style: TextStyle(color: AppTheme.error, decoration: TextDecoration.lineThrough, fontSize: 18)),
            const SizedBox(height: 6),
            Text(_q.fullForm.replaceAll('il/elle', _q.prefix.contains('elle') ? 'elle' : 'il'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
            Text('${_q.verb} · ${_q.tenseLabel}', style: TextStyle(color: AppTheme.textTertiary)),
            if (_gained > 0) ...[
              const SizedBox(height: 8),
              Text('+$_gained', style: TextStyle(color: AppTheme.warning, fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnd() {
    return PageBody(
      key: const ValueKey('end'),
      children: [
        const SizedBox(height: 10),
        Center(child: Floating(child: Text(_newRecord ? '🏆' : (_correct >= 7 ? '🎉' : '💪'), style: const TextStyle(fontSize: 80)))),
        Center(
          child: Text('$_score points',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.warning)),
        ),
        Center(
          child: Text('$_correct / $_rounds · ${_newRecord ? tr(context, 'New record!') : tr(context, 'Record: {n}', {'n': ProgressService.instance.recordOf(_recordKey)})}', textDirection: TextDirection.ltr,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ),
        if (_misses.isNotEmpty) ...[
          SectionTitle(tr(context, 'To review')),
          for (final (q, typed) in _misses)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${q.verb} · ${q.tenseLabel}', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                            if (typed.isNotEmpty)
                              Text('❌ ${q.prefix} $typed', style: TextStyle(color: AppTheme.error)),
                            Text('✅ ${q.prefix} ${q.answer}',
                                style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.volume_up_rounded, color: AppTheme.primary),
                        onPressed: () => TtsService.instance.speak(q.fullForm),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 20),
        GlowButton(label: tr(context, 'Play again'), icon: Icons.replay_rounded, onPressed: _start,
            colors: [AppTheme.warning, Color(0xFFF97316)]),
        const SizedBox(height: 10),
        TextButton(onPressed: () => setState(() => _phase = _Phase.setup), child: Text(tr(context, 'Change level'))),
      ],
    );
  }
}
