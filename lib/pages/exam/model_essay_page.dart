import 'package:flutter/material.dart';
import '../../data/exam_kit.dart';
import '../../services/essay_service.dart';
import '../../services/tts_service.dart';
import '../../services/ui_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/french_meaning.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';

/// A model essay written by the AI for a subject: read it, listen to it,
/// see its grammar, and learn it. Kept on the device.
class ModelEssayPage extends StatefulWidget {
  final ExamSubject subject;
  const ModelEssayPage({super.key, required this.subject});

  @override
  State<ModelEssayPage> createState() => _ModelEssayPageState();
}

class _ModelEssayPageState extends State<ModelEssayPage> {
  bool _writing = false;
  bool _meaning = false;
  String? _error;

  EssayService get _essays => EssayService.instance;
  ModelEssay? get _model => _essays.models[widget.subject.id];

  @override
  void initState() {
    super.initState();
    _essays.load().then((_) {
      if (mounted && _model == null) _write();
    });
  }

  Future<void> _write() async {
    setState(() {
      _writing = true;
      _error = null;
      _meaning = false;
    });
    try {
      await _essays.writeModel(widget.subject);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not write the essay. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
    return Scaffold(
      appBar: AppBar(title: Text('✨ ${tr(context, 'AI model essay')}')),
      body: PageBody(
        children: [
          GlassCard(
            glow: AppTheme.primary,
            padding: const EdgeInsets.all(14),
            child: Text(widget.subject.instruction,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, height: 1.4)),
          ),
          const SizedBox(height: 14),
          if (_writing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(tr(context, 'Professeur AI is writing a model essay…'), style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )
          else if (model == null)
            Column(
              children: [
                if (_error != null) TranslatedText(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.error)),
                const SizedBox(height: 12),
                GlowButton(label: tr(context, 'Try again'), icon: Icons.refresh_rounded, onPressed: _write),
              ],
            )
          else ...[
            TranslatedText(
              'Read it, listen to it, then try to write it again without looking. Learn the sentences you like: they will help you in the exam.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
            SectionTitle(
              '📖 ${tr(context, 'The essay')}',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: tr(context, 'Listen'),
                    icon: Icon(Icons.volume_up_rounded, color: AppTheme.primary),
                    onPressed: () => TtsService.instance.speak(model.essay),
                  ),
                  TranslateButton(active: _meaning, onPressed: () => setState(() => _meaning = !_meaning)),
                ],
              ),
            ),
            Entrance(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(model.essay,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(fontSize: 17, height: 1.6, color: AppTheme.textPrimary)),
                    if (_meaning) Padding(padding: const EdgeInsets.only(top: 12), child: FrenchMeaning(french: model.essay)),
                  ],
                ),
              ),
            ),
            if (model.notes.isNotEmpty) ...[
              SectionTitle('🔎 ${tr(context, 'Grammar in this essay')}'),
              for (final n in model.notes)
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
            const SizedBox(height: 16),
            GlowButton(label: tr(context, 'Now write yours'), icon: Icons.edit_rounded, onPressed: () => Navigator.pop(context)),
            const SizedBox(height: 10),
            GlowButton(
              label: tr(context, 'Another model essay'),
              icon: Icons.auto_awesome_rounded,
              colors: [AppTheme.secondary, AppTheme.accent],
              onPressed: _write,
            ),
          ],
        ],
      ),
    );
  }
}
