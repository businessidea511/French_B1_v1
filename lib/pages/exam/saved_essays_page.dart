import 'package:flutter/material.dart';
import '../../services/essay_service.dart';
import '../../services/tts_service.dart';
import '../../services/ui_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/french_meaning.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';

/// "💾 Save this essay" → "✓ Saved": keeps an essay in My saved essays.
class SaveEssayButton extends StatelessWidget {
  final String text; // the French essay
  final VoidCallback onSave;
  const SaveEssayButton({super.key, required this.text, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final essays = EssayService.instance;
    return ListenableBuilder(
      listenable: essays,
      builder: (context, _) {
        final kept = essays.savedWithText(text) != null;
        return OutlinedButton.icon(
          icon: Icon(kept ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
              color: kept ? AppTheme.success : AppTheme.primary),
          label: Text(kept ? tr(context, 'Saved in My saved essays') : tr(context, 'Save this essay'),
              style: TextStyle(fontWeight: FontWeight.w800, color: kept ? AppTheme.success : AppTheme.primary)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: (kept ? AppTheme.success : AppTheme.primary).withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: kept
              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedEssaysPage()))
              : onSave,
        );
      },
    );
  }
}

/// The essays the learner kept: AI model essays and corrected texts.
class SavedEssaysPage extends StatelessWidget {
  const SavedEssaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    final essays = EssayService.instance;
    essays.load();
    return Scaffold(
      appBar: AppBar(title: Text('💾 ${tr(context, 'My saved essays')}')),
      body: ListenableBuilder(
        listenable: essays,
        builder: (context, _) => PageBody(
          children: [
            if (essays.saved.isEmpty)
              TranslatedText(
                'Save a model essay or a corrected text: it will be kept here, to read again before the exam.',
                style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
              ),
            for (final s in essays.saved)
              Padding(
                key: ValueKey(s.id),
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SavedEssayPage(essay: s))),
                  child: GlassCard(
                    radius: 20,
                    glow: s.corrected ? AppTheme.success : AppTheme.primary,
                    padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.corrected ? '✅' : '✨', style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.title,
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  s.corrected ? tr(context, 'Corrected essay') : tr(context, 'Model essay'),
                                  if (s.score != null) '${s.score}/20',
                                  _date(s.savedAt),
                                ].join(' · '),
                                style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                              ),
                              const SizedBox(height: 4),
                              Text(s.text,
                                  textDirection: TextDirection.ltr,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.35)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: tr(context, 'Delete'),
                          icon: Icon(Icons.delete_outline_rounded, color: AppTheme.textTertiary),
                          onPressed: () => _delete(context, s),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static Future<void> _delete(BuildContext context, SavedEssay s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Delete this essay?')),
        content: Text(s.title, textDirection: TextDirection.ltr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(ctx, 'Back'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr(ctx, 'Delete'))),
        ],
      ),
    );
    if (ok == true) EssayService.instance.unkeep(s.id);
  }
}

/// One saved essay: the question, the essay (listen, translate), and for a
/// corrected essay the learner's own text and mistakes.
class SavedEssayPage extends StatefulWidget {
  final SavedEssay essay;
  const SavedEssayPage({super.key, required this.essay});

  @override
  State<SavedEssayPage> createState() => _SavedEssayPageState();
}

class _SavedEssayPageState extends State<SavedEssayPage> {
  bool _meaning = false;
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.essay;
    return Scaffold(
      appBar: AppBar(title: Text(s.title, textDirection: TextDirection.ltr)),
      body: PageBody(
        children: [
          if (s.question.isNotEmpty)
            GlassCard(
              glow: AppTheme.primary,
              padding: const EdgeInsets.all(14),
              child: Text(s.question,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, height: 1.4)),
            ),
          SectionTitle(
            '${s.corrected ? '🌟' : '📖'} ${s.corrected ? tr(context, 'A better version') : tr(context, 'The essay')}'
            '${s.score != null ? ' · ${s.score}/20' : ''}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: tr(context, 'Listen'),
                  icon: Icon(Icons.volume_up_rounded, color: AppTheme.primary),
                  onPressed: () => TtsService.instance.speak(s.text),
                ),
                TranslateButton(active: _meaning, onPressed: () => setState(() => _meaning = !_meaning)),
              ],
            ),
          ),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(s.text,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 17, height: 1.6, color: AppTheme.textPrimary)),
                if (_meaning) Padding(padding: const EdgeInsets.only(top: 12), child: FrenchMeaning(french: s.text)),
              ],
            ),
          ),
          if (s.notes.isNotEmpty) ...[
            SectionTitle('🔎 ${tr(context, 'Grammar in this essay')}'),
            for (final n in s.notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  radius: 16,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.french,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      if (n.point.isNotEmpty) TranslatedText(n.point, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
          if (s.mistakes.isNotEmpty) ...[
            SectionTitle('✏️ ${tr(context, 'Mistakes')} (${s.mistakes.length})'),
            for (final (wrong, right, why) in s.mistakes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  radius: 16,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('❌ $wrong',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(color: AppTheme.error, decoration: TextDecoration.lineThrough, decorationColor: AppTheme.error)),
                      Text('✅ $right',
                          textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800)),
                      if (why.isNotEmpty) Text(why, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.35)),
                    ],
                  ),
                ),
              ),
          ],
          if (s.original.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _showOriginal = !_showOriginal),
              icon: Icon(_showOriginal ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              label: Text('📝 ${tr(context, 'My text')}'),
            ),
            if (_showOriginal)
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: SelectableText(s.original,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 15, height: 1.55, color: AppTheme.textSecondary)),
              ),
          ],
        ],
      ),
    );
  }
}
