import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/exam_kit.dart';
import '../../services/essay_service.dart';
import '../../services/exam_writing_service.dart';
import '../../services/language_provider.dart';
import '../../services/life_story_service.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../services/ui_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/french_meaning.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/photo_pages_sheet.dart';
import '../../widgets/ui_kit.dart';
import 'model_essay_page.dart';

String _focusLabel(BuildContext context, ExamFocus f) => switch (f) {
      ExamFocus.subjonctif => 'Subjonctif',
      ExamFocus.codCoi => 'COD / COI',
      ExamFocus.both => 'Subjonctif + COD / COI',
      ExamFocus.any => tr(context, 'Any grammar'),
    };

/// Writing practice like in the exam: a subject, a timer, then a correction
/// out of 20 with every mistake explained and a better version.
class WritingPracticePage extends StatefulWidget {
  const WritingPracticePage({super.key});

  @override
  State<WritingPracticePage> createState() => _WritingPracticePageState();
}

class _WritingPracticePageState extends State<WritingPracticePage> {
  ExamFocus _focus = ExamFocus.both;
  bool _makingSubject = false;
  bool _readingPapers = false;

  EssayService get _essays => EssayService.instance;

  @override
  void initState() {
    super.initState();
    _essays.load();
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  /// Photos of class papers → the essay questions on them.
  Future<void> _fromPapers() async {
    final request = await showPhotoPagesSheet(
      context,
      title: '📷 ${tr(context, 'Class papers')}',
      mode: PhotoImportMode.essayQuestions,
      askInstructions: false,
    );
    if (request == null || !mounted) return;
    setState(() => _readingPapers = true);
    try {
      final found = await _essays.readPapers(request.base64Images, request.mimeType);
      if (!mounted) return;
      final added = _essays.addAll(found);
      _snack(found.isEmpty
          ? tr(context, 'No essay question found on these photos. Try clearer photos, or type the question.')
          : tr(context, '{n} new question(s) added', {'n': added}));
    } catch (_) {
      if (mounted) _snack(tr(context, 'Could not read the photos. Try again.'));
    } finally {
      if (mounted) setState(() => _readingPapers = false);
    }
  }

  Future<void> _typeQuestion() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Type a question')),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(hintText: tr(ctx, 'The essay question, in French')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr(ctx, 'Back'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(tr(ctx, 'Add'))),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().length < 10 || !mounted) return;
    _essays.addTyped(text);
  }

  Future<void> _delete(EssayQuestion q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Delete this question?')),
        content: Text(q.title, textDirection: TextDirection.ltr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(ctx, 'Back'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr(ctx, 'Delete'))),
        ],
      ),
    );
    if (ok == true) _essays.remove(q.id);
  }

  Widget _classQuestions() {
    return ListenableBuilder(
      listenable: _essays,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle('📷 ${tr(context, 'My class questions')}'),
          Row(
            children: [
              Expanded(
                child: GlowButton(
                  label: _readingPapers ? tr(context, 'Reading…') : tr(context, 'Class papers'),
                  icon: Icons.photo_camera_rounded,
                  onPressed: _readingPapers ? null : _fromPapers,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlowButton(
                  label: tr(context, 'Type a question'),
                  icon: Icons.edit_note_rounded,
                  colors: [AppTheme.secondary, AppTheme.accent],
                  onPressed: _typeQuestion,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_essays.questions.isEmpty)
            TranslatedText(
              'Take photos of the essay questions from your class: they will be saved here, ready to practise.',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
            ),
          for (final q in _essays.questions)
            Padding(
              key: ValueKey(q.id),
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _write(q.subject),
                child: GlassCard(
                  radius: 20,
                  glow: AppTheme.success,
                  padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_essays.models.containsKey(q.subject.id) ? '✨' : '📄', style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q.title,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                            if (q.question != q.title) ...[
                              const SizedBox(height: 3),
                              Text(q.question,
                                textDirection: TextDirection.ltr,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.35)),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: tr(context, 'Delete'),
                        icon: Icon(Icons.delete_outline_rounded, color: AppTheme.textTertiary),
                        onPressed: () => _delete(q),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<ExamSubject> get _subjects => [
        for (final s in examSubjects)
          if (switch (_focus) {
            ExamFocus.any => true,
            ExamFocus.both => s.focus != ExamFocus.any,
            _ => s.focus == _focus || s.focus == ExamFocus.both,
          })
            s,
      ];

  void _write(ExamSubject subject) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => WritingEditorPage(subject: subject)));

  Future<void> _newSubject() async {
    setState(() => _makingSubject = true);
    try {
      final subject = await ExamWritingService.newSubject(_focus);
      if (mounted) _write(subject);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'Could not create a subject. Try again.'))),
        );
      }
    } finally {
      if (mounted) setState(() => _makingSubject = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('📝 ${tr(context, 'Writing practice')}')),
      body: PageBody(
        children: [
          TranslatedText(
            'Choose the grammar of your exam, then a subject. Write as in the exam (about 20 minutes), then get a correction like a teacher\'s.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          _classQuestions(),
          SectionTitle(tr(context, 'Grammar of the exam')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in ExamFocus.values)
                ChoiceChip(
                  label: Text(_focusLabel(context, f)),
                  selected: _focus == f,
                  onSelected: (_) => setState(() => _focus = f),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GlowButton(
            label: _makingSubject ? tr(context, 'Writing a new subject…') : tr(context, 'New subject (AI)'),
            icon: Icons.auto_awesome_rounded,
            colors: [AppTheme.accent, AppTheme.primary],
            onPressed: _makingSubject ? null : _newSubject,
          ),
          SectionTitle(tr(context, 'Likely exam subjects')),
          for (final (i, s) in _subjects.indexed)
            Entrance(
              key: ValueKey('${_focus.name}_${s.id}'),
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _write(s),
                  child: GlassCard(
                    radius: 20,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.title,
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                              const SizedBox(height: 3),
                              Text(s.instruction,
                                  textDirection: TextDirection.ltr,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.35)),
                              const SizedBox(height: 4),
                              Text(_focusLabel(context, s.focus),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Write the text for one subject, then see the correction.
class WritingEditorPage extends StatefulWidget {
  final ExamSubject subject;
  final Duration examTime;
  const WritingEditorPage({super.key, required this.subject, this.examTime = const Duration(minutes: 20)});

  @override
  State<WritingEditorPage> createState() => _WritingEditorPageState();
}

class _WritingEditorPageState extends State<WritingEditorPage> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  Timer? _ticker;
  Timer? _saveSoon;
  DateTime? _startedAt;
  bool _correcting = false;
  String? _error;
  String? _instructionTranslated;
  WritingFeedback? _feedback;
  bool _betterMeaning = false;

  ExamSubject get _subject => widget.subject;
  int get _words => ExamWritingService.wordCount(_text.text);

  @override
  void initState() {
    super.initState();
    ExamWritingService.draft(_subject.id).then((saved) {
      if (mounted && _text.text.isEmpty && saved.isNotEmpty) setState(() => _text.text = saved);
    });
    _text.addListener(_changed);
  }

  void _changed() {
    if (_startedAt == null && _text.text.trim().isNotEmpty) {
      _startedAt = DateTime.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
    }
    _saveSoon?.cancel();
    _saveSoon = Timer(const Duration(seconds: 1), () => ExamWritingService.saveDraft(_subject.id, _text.text));
    setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _saveSoon?.cancel();
    ExamWritingService.saveDraft(_subject.id, _text.text);
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Duration get _left {
    if (_startedAt == null) return widget.examTime;
    final left = widget.examTime - DateTime.now().difference(_startedAt!);
    return left.isNegative ? Duration.zero : left;
  }

  String get _clock {
    final l = _left;
    return '${l.inMinutes.toString().padLeft(2, '0')}:${(l.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _translateInstruction() async {
    if (_instructionTranslated != null) return setState(() => _instructionTranslated = null);
    final current = context.read<LanguageProvider>().currentLanguage;
    final language = current == AppLanguage.french ? 'English' : current.englishName;
    setState(() => _instructionTranslated = '…');
    try {
      final t = await LifeStoryService.instance.translate(_subject.instruction, language);
      if (mounted) setState(() => _instructionTranslated = t);
    } catch (_) {
      if (mounted) setState(() => _instructionTranslated = null);
    }
  }

  Future<void> _correct() async {
    if (_words < 20 || _correcting) return;
    _focus.unfocus();
    setState(() {
      _correcting = true;
      _error = null;
    });
    try {
      final language = context.read<LanguageProvider>().currentLanguage.englishName;
      final feedback = await ExamWritingService.correct(_subject, _text.text, language: language);
      if (!mounted) return;
      for (final m in feedback.mistakes) {
        ProgressService.instance.addMistake(
          source: 'Rédaction',
          question: '📝 ${_subject.title}',
          wrong: m.wrong,
          right: m.right,
          explanation: m.why,
        );
      }
      ProgressService.instance.addXp(10);
      _ticker?.cancel();
      setState(() => _feedback = feedback);
      if (feedback.score >= 14) Confetti.burst(context);
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (_) {
      if (mounted) setState(() => _error = 'The correction did not work. Check your connection and try again: your text is saved.');
    } finally {
      if (mounted) setState(() => _correcting = false);
    }
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text('🃏 ${tr(context, 'My joker phrases')}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            for (final p in jokerPhrases)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text('• ${p.french}', textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.textPrimary, height: 1.35)),
              ),
            const SizedBox(height: 14),
            Text('🗺️ ${tr(context, 'A plan for any story')}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            for (final (i, s) in storyPlan.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}. ${s.emoji} ', style: TextStyle(color: AppTheme.textPrimary)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText('${s.title} (${s.tense})', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                          Text(s.example, textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeUp = _startedAt != null && _left == Duration.zero;
    return Scaffold(
      appBar: AppBar(
        title: Text(_subject.title, textDirection: TextDirection.ltr, overflow: TextOverflow.ellipsis),
        actions: [
          if (_feedback == null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Center(
                child: Text('⏱ $_clock',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontWeight: FontWeight.w900, color: timeUp ? AppTheme.error : AppTheme.textPrimary)),
              ),
            ),
        ],
      ),
      body: PageBody(
        controller: _scroll,
        children: _feedback == null ? _editor(timeUp) : _results(_feedback!),
      ),
    );
  }

  Widget _subjectCard() {
    return GlassCard(
      glow: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_subject.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_subject.instruction,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, height: 1.4)),
              ),
              IconButton(
                tooltip: tr(context, 'Translate'),
                icon: Icon(Icons.translate_rounded, size: 20, color: AppTheme.textTertiary),
                onPressed: _translateInstruction,
              ),
            ],
          ),
          if (_instructionTranslated != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Text(_instructionTranslated!, style: TextStyle(color: AppTheme.textSecondary, height: 1.35)),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_focusLabel(context, _subject.focus)} · ${_subject.minWords}–${_subject.maxWords} ${tr(context, 'words')}',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ModelEssayPage(subject: _subject))),
                icon: const Text('✨'),
                label: Text(tr(context, 'AI model essay')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _editor(bool timeUp) {
    final words = _words;
    final enough = words >= _subject.minWords;
    return [
      _subjectCard(),
      const SizedBox(height: 12),
      if (timeUp)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TranslatedText('⏰ Time is up! In the exam you would hand in now. You can still finish.',
              style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700)),
        ),
      TextField(
        controller: _text,
        focusNode: _focus,
        minLines: 10,
        maxLines: 24,
        autocorrect: false,
        enableSuggestions: false,
        textDirection: TextDirection.ltr,
        style: TextStyle(fontSize: 17, height: 1.5, color: AppTheme.textPrimary),
        decoration: InputDecoration(hintText: tr(context, 'Write your text here…')),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: Text('$words / ${_subject.minWords}–${_subject.maxWords} ${tr(context, 'words')}',
                textDirection: TextDirection.ltr,
                style: TextStyle(fontWeight: FontWeight.w800, color: enough ? AppTheme.success : AppTheme.textTertiary)),
          ),
          TextButton.icon(
            onPressed: _showHelp,
            icon: const Text('🃏'),
            label: Text(tr(context, 'My phrases')),
          ),
        ],
      ),
      AccentBar(controller: _text, focusNode: _focus),
      const SizedBox(height: 16),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TranslatedText(_error!, style: TextStyle(color: AppTheme.error)),
        ),
      GlowButton(
        label: _correcting ? tr(context, 'The teacher is reading your text…') : tr(context, 'Correct it like a teacher'),
        icon: Icons.school_rounded,
        onPressed: words < 20 || _correcting ? null : _correct,
      ),
      if (words < 20)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: TranslatedText('Write at least 20 words to get a correction.',
              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
        ),
    ];
  }

  List<Widget> _results(WritingFeedback f) {
    final color = f.score >= 14
        ? AppTheme.success
        : f.score >= 10
            ? AppTheme.warning
            : AppTheme.error;
    return [
      Entrance(
        child: GlassCard(
          glow: color,
          child: Column(
            children: [
              Text('${f.score} / 20',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: color)),
              if (f.summary.isNotEmpty)
                Text(f.summary, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textPrimary, height: 1.4)),
              const SizedBox(height: 14),
              _criterion(tr(context, 'Answers the subject'), f.task),
              _criterion(tr(context, 'Grammar'), f.grammar),
              _criterion(tr(context, 'Vocabulary and spelling'), f.vocabulary),
              _criterion(tr(context, 'Organisation'), f.organisation),
            ],
          ),
        ),
      ),
      if (f.good.isNotEmpty) ...[
        SectionTitle('👍 ${tr(context, 'What you did well')}'),
        for (final g in f.good)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('✓ $g', style: TextStyle(color: AppTheme.success, height: 1.4)),
          ),
      ],
      if (f.mistakes.isNotEmpty) ...[
        SectionTitle('✏️ ${tr(context, 'Your mistakes')} (${f.mistakes.length})'),
        for (final m in f.mistakes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              radius: 16,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('❌ ${m.wrong}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: AppTheme.error, decoration: TextDecoration.lineThrough, decorationColor: AppTheme.error)),
                  Text('✅ ${m.right}', textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800)),
                  if (m.why.isNotEmpty) Text(m.why, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.35)),
                ],
              ),
            ),
          ),
      ],
      if (f.betterVersion.isNotEmpty) ...[
        SectionTitle('🌟 ${tr(context, 'A better version')}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: tr(context, 'Listen'),
                  icon: Icon(Icons.volume_up_rounded, color: AppTheme.primary),
                  onPressed: () => TtsService.instance.speak(f.betterVersion),
                ),
                TranslateButton(active: _betterMeaning, onPressed: () => setState(() => _betterMeaning = !_betterMeaning)),
              ],
            )),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(f.betterVersion,
                  textDirection: TextDirection.ltr, style: TextStyle(fontSize: 16, height: 1.55, color: AppTheme.textPrimary)),
              if (_betterMeaning)
                Padding(padding: const EdgeInsets.only(top: 10), child: FrenchMeaning(french: f.betterVersion)),
            ],
          ),
        ),
      ],
      if (f.nextTip.isNotEmpty) ...[
        const SizedBox(height: 14),
        GlassCard(
          glow: AppTheme.warning,
          padding: const EdgeInsets.all(14),
          child: Text('💡 ${f.nextTip}', style: TextStyle(color: AppTheme.textPrimary, height: 1.4)),
        ),
      ],
      const SizedBox(height: 18),
      GlowButton(
        label: tr(context, 'Improve my text'),
        icon: Icons.edit_rounded,
        onPressed: () => setState(() => _feedback = null),
      ),
      const SizedBox(height: 10),
      GlowButton(
        label: tr(context, 'Another subject'),
        icon: Icons.refresh_rounded,
        colors: [AppTheme.secondary, AppTheme.accent],
        onPressed: () => Navigator.pop(context),
      ),
    ];
  }

  Widget _criterion(String label, int mark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: AppTheme.textSecondary))),
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Icon(i < mark ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 20, color: i < mark ? AppTheme.warning : AppTheme.textTertiary),
            ),
          SizedBox(width: 34, child: Text(' ${max(0, mark)}/5', textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.textTertiary, fontSize: 12))),
        ],
      ),
    );
  }
}
