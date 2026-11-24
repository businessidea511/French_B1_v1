import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/homework_service.dart';
import '../../services/language_provider.dart';
import '../../services/tts_service.dart';
import '../../services/ui_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/photo_pages_sheet.dart';
import '../../widgets/ui_kit.dart';

/// Homework help: photograph a class sheet → its translation, the hard words
/// and the answers, solved and then checked a second time.
class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  final _service = HomeworkService.instance;
  HomeworkStep? _step; // null when not working

  @override
  void initState() {
    super.initState();
    _service.load();
  }

  Future<void> _photograph() async {
    final request = await showPhotoPagesSheet(
      context,
      title: '📸 ${tr(context, 'My homework')}',
      mode: PhotoImportMode.homework,
    );
    if (request == null || !mounted) return;
    final language = context.read<LanguageProvider>().currentLanguage;
    setState(() => _step = HomeworkStep.reading);
    try {
      final homework = await _service.solve(
        request.base64Images,
        request.mimeType,
        language,
        instructions: request.instructions,
        onStep: (step) {
          if (mounted) setState(() => _step = step);
        },
      );
      if (!mounted) return;
      _open(homework);
    } on HomeworkNotFound {
      _snack(tr(context, 'No exercise found on these photos. Take clearer photos, flat and with good light.'));
    } catch (e) {
      debugPrint('Homework failed: $e');
      if (mounted) _snack(tr(context, 'Could not read the photos. Try again.'));
    } finally {
      if (mounted) setState(() => _step = null);
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _open(Homework h) => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeworkResultPage(homework: h)));

  Future<void> _delete(Homework h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Delete this homework?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(ctx, 'Back'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr(ctx, 'Delete'))),
        ],
      ),
    );
    if (ok == true) _service.remove(h.id);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == null, // do not lose a homework that is being solved
      child: Scaffold(
        appBar: AppBar(title: Text('📸 ${tr(context, 'Homework help')}')),
        body: ListenableBuilder(
          listenable: _service,
          builder: (context, _) => PageBody(
            children: [
              Text(
                tr(context,
                    'Take a photo of your homework sheet. You get its translation, the hard words, and the answers with the grammar rule. Every answer is checked twice.'),
                style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              if (_step == null)
                GlowButton(
                  label: tr(context, 'Photograph my homework'),
                  icon: Icons.photo_camera_rounded,
                  onPressed: _photograph,
                )
              else
                _Progress(step: _step!),
              if (_service.history.isNotEmpty) ...[
                SectionTitle(tr(context, 'My homework')),
                for (final h in _service.history)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 4),
                        leading: const Text('📄', style: TextStyle(fontSize: 26)),
                        title: Text(h.title,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        subtitle: Text(
                          '${h.date.day}/${h.date.month}/${h.date.year} · ${tr(context, '{n} answers', {'n': h.answers.length})}',
                          style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                        ),
                        trailing: IconButton(
                          tooltip: tr(context, 'Delete'),
                          icon: Icon(Icons.delete_outline_rounded, color: AppTheme.textTertiary),
                          onPressed: () => _delete(h),
                        ),
                        onTap: () => _open(h),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The three steps, with the current one turning.
class _Progress extends StatelessWidget {
  final HomeworkStep step;
  const _Progress({required this.step});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (HomeworkStep.reading, tr(context, 'Reading the sheet')),
      (HomeworkStep.solving, tr(context, 'Translating and solving')),
      (HomeworkStep.checking, tr(context, 'Checking every answer a second time')),
    ];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (s, label) in steps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: s.index < step.index
                        ? Icon(Icons.check_circle_rounded, color: AppTheme.success)
                        : s == step
                            ? const Padding(padding: EdgeInsets.all(3), child: CircularProgressIndicator(strokeWidth: 2.5))
                            : Icon(Icons.circle_outlined, color: AppTheme.textTertiary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                          color: s.index > step.index ? AppTheme.textTertiary : AppTheme.textPrimary,
                          fontWeight: s == step ? FontWeight.w800 : FontWeight.normal,
                        )),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(tr(context, 'This takes about one minute. Keep this page open.'),
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }
}

/// A solved homework: translation, hard words, answers, and what was read.
class HomeworkResultPage extends StatelessWidget {
  final Homework homework;
  const HomeworkResultPage({super.key, required this.homework});

  @override
  Widget build(BuildContext context) {
    final h = homework;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(h.title, textDirection: TextDirection.ltr, overflow: TextOverflow.ellipsis),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: '🌍 ${tr(context, 'Translation')}'),
              Tab(text: '🔤 ${tr(context, 'Hard words')}'),
              Tab(text: '✅ ${tr(context, 'Answers')}'),
              Tab(text: '📄 ${tr(context, 'The sheet')}'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TranslationTab(h),
            _WordsTab(h),
            _AnswersTab(h),
            _SheetTab(h),
          ],
        ),
      ),
    );
  }
}

/// French text: always left to right and selectable.
class _French extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const _French(this.text, {this.style});

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: SelectableText(text, style: style ?? TextStyle(color: AppTheme.textPrimary, height: 1.5)),
      );
}

class _TranslationTab extends StatelessWidget {
  final Homework h;
  const _TranslationTab(this.h);

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    return PageBody(
      children: [
        GlassCard(
          child: h.translation.isEmpty
              ? Text(tr(context, 'No translation: the app language is French.'),
                  style: TextStyle(color: AppTheme.textSecondary))
              : Directionality(
                  textDirection: lp.isRTL ? TextDirection.rtl : TextDirection.ltr,
                  child: SelectableText(h.translation, style: TextStyle(color: AppTheme.textPrimary, height: 1.6, fontSize: 15)),
                ),
        ),
      ],
    );
  }
}

class _WordsTab extends StatelessWidget {
  final Homework h;
  const _WordsTab(this.h);

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    return PageBody(
      children: [
        if (h.words.isEmpty) Text(tr(context, 'No hard words on this sheet.'), style: TextStyle(color: AppTheme.textSecondary)),
        for (final w in h.words)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 10, 6, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _French(w['fr'] ?? '',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      ),
                      IconButton(
                        tooltip: tr(context, 'Listen'),
                        icon: Icon(Icons.volume_up_rounded, color: AppTheme.primary),
                        onPressed: () => TtsService.instance.speak(w['fr'] ?? ''),
                      ),
                    ],
                  ),
                  Directionality(
                    textDirection: lp.isRTL ? TextDirection.rtl : TextDirection.ltr,
                    child: Text(w['meaning'] ?? '', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                  ),
                  if ((w['example'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _French(w['example']!,
                        style: TextStyle(color: AppTheme.textTertiary, fontStyle: FontStyle.italic, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AnswersTab extends StatelessWidget {
  final Homework h;
  const _AnswersTab(this.h);

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final groups = h.byExercise;
    final checked = h.answers.where((a) => a.student != 'none').toList();
    final right = checked.where((a) => a.student == 'correct').length;
    return PageBody(
      children: [
        if (checked.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              glow: right == checked.length ? AppTheme.success : AppTheme.warning,
              child: Text(
                tr(context, 'Your answers: {right} / {total} right', {'right': right, 'total': checked.length}),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
              ),
            ),
          ),
        if (h.answers.isEmpty)
          Text(tr(context, 'No exercise to solve on this sheet.'), style: TextStyle(color: AppTheme.textSecondary)),
        for (final MapEntry(key: label, value: items) in groups.entries) ...[
          SectionTitle(label.isEmpty ? tr(context, 'Answers') : label),
          if (h.instructionOf(label).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: _French(h.instructionOf(label),
                  style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
            ),
          for (final a in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnswerCard(a, rtl: lp.isRTL),
            ),
        ],
        const SizedBox(height: 8),
        Text(
          tr(context, 'The AI read your photo: check in « The sheet » that nothing was misread. Learn the rule, do not just copy.'),
          style: TextStyle(color: AppTheme.textTertiary, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final HomeworkAnswer a;
  final bool rtl;
  const _AnswerCard(this.a, {required this.rtl});

  @override
  Widget build(BuildContext context) {
    final wrong = a.student == 'wrong';
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 14),
      glow: wrong ? AppTheme.error : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${a.n}. ', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textTertiary)),
                Expanded(child: SelectableText(a.question, style: TextStyle(color: AppTheme.textSecondary, height: 1.4))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(a.answer,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.success)),
                ),
                IconButton(
                  tooltip: tr(context, 'Copy'),
                  icon: Icon(Icons.copy_rounded, size: 20, color: AppTheme.textTertiary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: a.sentence.isEmpty ? a.answer : a.sentence));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'Copied'))));
                  },
                ),
                IconButton(
                  tooltip: tr(context, 'Listen'),
                  icon: Icon(Icons.volume_up_rounded, size: 22, color: AppTheme.primary),
                  onPressed: () => TtsService.instance.speak(a.sentence.isEmpty ? a.answer : a.sentence),
                ),
              ],
            ),
          ),
          if (a.sentence.isNotEmpty && a.sentence != a.answer)
            _French(a.sentence, style: TextStyle(color: AppTheme.textPrimary, height: 1.4)),
          if (a.student != 'none') ...[
            const SizedBox(height: 8),
            Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                wrong
                    ? '❌ ${tr(context, 'You wrote: {answer}', {'answer': a.studentAnswer})}'
                    : '✅ ${tr(context, 'Your answer is right')}',
                style: TextStyle(fontWeight: FontWeight.w700, color: wrong ? AppTheme.error : AppTheme.success),
              ),
            ),
          ],
          if (a.why.isNotEmpty) ...[
            const SizedBox(height: 8),
            Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: Text('💡 ${a.why}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.45)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SheetTab extends StatelessWidget {
  final Homework h;
  const _SheetTab(this.h);

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        Text(tr(context, 'What the AI read on your photos. If something is wrong, take a clearer photo.'),
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 12, height: 1.4)),
        if (h.unreadable.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('⚠️ ${tr(context, 'Hard to read:')} ${h.unreadable.join(' · ')}',
              style: TextStyle(color: AppTheme.warning, fontSize: 13)),
        ],
        if (h.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          GlassCard(child: _French(h.text)),
        ],
        for (final e in h.exercises) ...[
          SectionTitle('${e['label'] ?? ''}'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if ('${e['instruction'] ?? ''}'.isNotEmpty)
                  _French('${e['instruction']}', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                for (final item in (e['items'] as List? ?? const []))
                  if (item is Map)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _French(
                        '${item['n'] ?? ''}. ${item['question'] ?? ''}'
                        '${(item['options'] as List? ?? const []).isEmpty ? '' : '\n   (${(item['options'] as List).join(' / ')})'}'
                        '${'${item['student_answer'] ?? ''}'.isEmpty ? '' : '\n   ✏️ ${item['student_answer']}'}',
                      ),
                    ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
