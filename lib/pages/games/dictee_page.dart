import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/practice_logic.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';
import '../../services/ui_strings.dart';

/// Dictée: listen to a French sentence and write it; every word is checked.
class DicteePage extends StatefulWidget {
  const DicteePage({super.key});

  @override
  State<DicteePage> createState() => _DicteePageState();
}

class _DicteePageState extends State<DicteePage> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  String? _level;
  List<String> _sentences = [];
  int _index = 0;
  bool _checked = false;
  final List<int> _scores = [];

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _sentence => _sentences[_index];

  void _start(String level) {
    setState(() {
      _level = level;
      _sentences = Dictee.sentences(level, Random());
      _index = 0;
      _scores.clear();
      _checked = false;
      _input.clear();
    });
    Future.delayed(const Duration(milliseconds: 600), _play);
  }

  void _play({bool slow = false}) {
    if (_sentences.isEmpty) return;
    TtsService.instance.speak(_sentence, rate: slow ? 0.5 : 0.85);
    _focus.requestFocus();
  }

  void _check() {
    if (_checked || _input.text.trim().isEmpty) return;
    final score = Dictee.score(_input.text, _sentence);
    _scores.add(score);
    if (score < 100) {
      ProgressService.instance.addMistake(
        source: 'Dictée',
        question: '🎧 Dictée',
        wrong: _input.text.trim(),
        right: _sentence,
      );
    }
    ProgressService.instance.addXp(score >= 80 ? 3 : 1);
    setState(() => _checked = true);
  }

  void _next() {
    if (_index + 1 >= _sentences.length) {
      setState(() => _index++);
      if (_average >= 80) Confetti.burst(context);
      return;
    }
    setState(() {
      _index++;
      _checked = false;
      _input.clear();
    });
    Future.delayed(const Duration(milliseconds: 300), _play);
  }

  int get _average => _scores.isEmpty ? 0 : (_scores.reduce((a, b) => a + b) / _scores.length).round();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🎧 ${tr(context, 'Dictation')}')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _level == null
            ? _buildSetup()
            : _index >= _sentences.length
                ? _buildEnd()
                : _buildSentence(),
      ),
    );
  }

  Widget _buildSetup() {
    return PageBody(
      key: const ValueKey('setup'),
      children: [
        const SizedBox(height: 12),
        const Center(child: Floating(child: Text('🎧', style: TextStyle(fontSize: 72)))),
        const SizedBox(height: 12),
        TranslatedText(
          'Listen to a sentence and write exactly what you hear. You can listen again and slowly. Great for spelling and listening at the same time.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.4),
        ),
        SectionTitle(tr(context, 'Level')),
        for (final (i, level) in Dictee.levels.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Entrance(
              index: i,
              child: Tilt3D(
                maxTilt: 0.1,
                onTap: () => _start(level),
                child: GlassCard(
                  glow: [AppTheme.success, AppTheme.primary, AppTheme.secondary][i],
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Text(['🌱', '🔥', '🚀'][i], style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(UiStrings.level(context, level), style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            Text(tr(context, ['up to 5 words', '6 – 9 words', '10+ words'][i]),
                                style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
                          ],
                        ),
                      ),
                      Icon(Icons.play_circle_fill_rounded, color: AppTheme.textSecondary, size: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSentence() {
    return PageBody(
      key: ValueKey('s$_index'),
      children: [
        Row(
          children: [
            Text('${_index + 1} / ${_sentences.length}', textDirection: TextDirection.ltr,
                style: TextStyle(color: AppTheme.textTertiary, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_scores.isNotEmpty) Text(tr(context, 'Average: {n} %', {'n': _average}), style: TextStyle(color: AppTheme.warning)),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _soundButton('🔊', tr(context, 'Listen'), () => _play()),
            const SizedBox(width: 18),
            _soundButton('🐢', tr(context, 'Slowly'), () => _play(slow: true)),
          ],
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _input,
          focusNode: _focus,
          enabled: !_checked,
          minLines: 2,
          maxLines: 4,
          autocorrect: false,
          enableSuggestions: false,
          textDirection: TextDirection.ltr,
          style: TextStyle(fontSize: 19, color: AppTheme.textPrimary),
          decoration: InputDecoration(hintText: tr(context, 'Write the sentence here…')),
          onSubmitted: (_) => _check(),
        ),
        const SizedBox(height: 12),
        if (!_checked) ...[
          AccentBar(controller: _input, focusNode: _focus),
          const SizedBox(height: 16),
          GlowButton(label: tr(context, 'Correct it'), icon: Icons.spellcheck_rounded, onPressed: _check),
        ] else ...[
          _buildCorrection(),
          const SizedBox(height: 16),
          GlowButton(
            label: tr(context, _index + 1 >= _sentences.length ? 'Results' : 'Next sentence'),
            icon: Icons.arrow_forward_rounded,
            onPressed: _next,
          ),
        ],
      ],
    );
  }

  Widget _soundButton(String emoji, String label, VoidCallback onTap) {
    return Tilt3D(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
              boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCorrection() {
    final marks = Dictee.compare(_input.text, _sentence);
    final score = _scores.last;
    return Entrance(
      child: GlassCard(
        glow: score == 100 ? AppTheme.success : (score >= 70 ? AppTheme.warning : AppTheme.error),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(score == 100 ? '🎉 Parfait !' : '$score %', textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final w in marks)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: switch (w.mark) {
                          WordMark.ok => AppTheme.success,
                          WordMark.accent => AppTheme.warning,
                          _ => AppTheme.error,
                        }.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(w.word,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: switch (w.mark) {
                              WordMark.ok => AppTheme.success,
                              WordMark.accent => AppTheme.warning,
                              _ => AppTheme.error,
                            },
                          )),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(tr(context, 'DICTEE_KEY'),
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
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
        Center(child: Floating(child: Text(_average >= 80 ? '🏆' : '💪', style: const TextStyle(fontSize: 80)))),
        Center(
          child: Text('$_average %', textDirection: TextDirection.ltr, style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: AppTheme.warning)),
        ),
        Center(child: Text(tr(context, 'success'), style: TextStyle(color: AppTheme.textSecondary))),
        const SizedBox(height: 24),
        GlowButton(label: tr(context, 'Another dictation'), icon: Icons.replay_rounded, onPressed: () => _start(_level!)),
        const SizedBox(height: 10),
        TextButton(onPressed: () => setState(() => _level = null), child: Text(tr(context, 'Change level'))),
      ],
    );
  }
}
