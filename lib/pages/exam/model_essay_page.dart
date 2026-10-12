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
import 'saved_essays_page.dart';

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
    _essays.load().then((_) async {
      if (!mounted || _model != null) return;
      // First model essay: ask the country once, so essays about culture are about it.
      if (_essays.country.isEmpty && !_askedCountry) {
        _askedCountry = true;
        await _pickCountry();
        if (!mounted) return;
      }
      _write();
    });
  }

  static bool _askedCountry = false; // once per visit of the app

  Future<bool?> _pickCountry() => showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => const _CountrySheet(),
      );

  Future<void> _chooseCountry() async {
    final changed = await _pickCountry();
    // A new country: the model essay is written again for it.
    if (changed == true && mounted && (_model?.country ?? '') != _essays.country) _write();
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
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _writing ? null : _chooseCountry,
            child: GlassCard(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Text('🌍', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _essays.country.isEmpty
                          ? tr(context, 'Choose your country: essays about culture and fêtes will be about it')
                          : '${tr(context, 'Written for')}: ${_essays.country}${_essays.traditions.isEmpty ? '' : ' · ${_essays.traditions}'}',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.35),
                    ),
                  ),
                  Text(tr(context, 'Change'), style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
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
            SaveEssayButton(
              text: model.essay,
              onSave: () => _essays.keep(
                corrected: false,
                title: widget.subject.title,
                question: widget.subject.instruction,
                text: model.essay,
                notes: model.notes,
              ),
            ),
            const SizedBox(height: 10),
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

/// Choose the learner's country (and traditions) for essays about culture.
class _CountrySheet extends StatefulWidget {
  const _CountrySheet();

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final _other = TextEditingController();
  final _traditions = TextEditingController();
  late String _country;

  EssayService get _essays => EssayService.instance;

  @override
  void initState() {
    super.initState();
    _country = _essays.country;
    if (_country.isNotEmpty && !EssayService.countries.contains(_country)) _other.text = _country;
    _traditions.text = _essays.traditions;
  }

  @override
  void dispose() {
    _other.dispose();
    _traditions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final country = _other.text.trim().isNotEmpty ? _other.text.trim() : _country;
    await _essays.setCulture(country, _traditions.text);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌍 ${tr(context, 'My country')}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            TranslatedText(
              'For essays about culture, fêtes, food and traditions, the model essay talks about your country.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in EssayService.countries)
                  ChoiceChip(
                    label: Text(c),
                    selected: _country == c && _other.text.trim().isEmpty,
                    onSelected: (_) => setState(() {
                      _country = c;
                      _other.clear();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _other,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: tr(context, 'Another country')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _traditions,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: tr(context, 'My traditions (optional)'),
                hintText: "musulman : l'Aïd el-Fitr, l'Aïd el-Adha",
              ),
            ),
            const SizedBox(height: 18),
            GlowButton(
              label: tr(context, 'Save'),
              icon: Icons.check_rounded,
              onPressed: _country.isEmpty && _other.text.trim().isEmpty ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
