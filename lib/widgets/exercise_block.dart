import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'translated_text.dart';
import '../services/ui_strings.dart';

/// Interactive exercise widget for lesson content (`"type": "exercise"`).
///
/// JSON shape:
/// {
///   "type": "exercise",
///   "title": "Exercice 1",
///   "instruction": "Complete with the passé composé.",   // explanation language
///   "items": [
///     {"question": "Je ___ au marché.", "options": ["vais", "va"], "correct": 0, "explanation": "..."},
///     {"question": "Hier, nous ___ (aller).", "answer": "sommes allés", "alternatives": ["sommes allées"], "explanation": "..."},
///     {"question": "Décrivez votre quartier.", "model_answer": "J'habite à Liège..."}
///   ]
/// }
/// Items with "options" are multiple choice, with "answer" are typed answers,
/// and with only "model_answer" are open questions with a revealable answer.
class ExerciseBlock extends StatefulWidget {
  final String title;
  final String instruction;
  final List<Map<String, dynamic>> items;

  const ExerciseBlock({
    super.key,
    required this.title,
    required this.instruction,
    required this.items,
  });

  /// Builds the block from lesson JSON, dropping malformed items.
  /// Returns null when nothing usable is left.
  static ExerciseBlock? fromJson(Map w) {
    final items = <Map<String, dynamic>>[];
    for (final raw in (w['items'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final question = (item['question'] ?? '').toString().trim();
      if (question.isEmpty) continue;

      final options = (item['options'] as List?)?.map((o) => o.toString()).toList();
      final correct = item['correct'];
      final answer = (item['answer'] ?? '').toString().trim();
      final model = (item['model_answer'] ?? '').toString().trim();

      if (options != null && options.length >= 2 && correct is num &&
          correct >= 0 && correct < options.length) {
        items.add({...item, 'options': options, 'correct': correct.toInt()});
      } else if (answer.isNotEmpty) {
        items.add({...item, 'options': null});
      } else if (model.isNotEmpty) {
        items.add({...item, 'options': null, 'answer': ''});
      }
    }
    if (items.isEmpty) return null;
    return ExerciseBlock(
      title: (w['title'] ?? 'Exercice').toString(),
      instruction: (w['instruction'] ?? '').toString(),
      items: items,
    );
  }

  @override
  State<ExerciseBlock> createState() => _ExerciseBlockState();
}

enum _Result { correct, accentsOnly, wrong }

class _ExerciseBlockState extends State<ExerciseBlock> {
  final Map<int, int> _chosen = {};
  final Map<int, _Result> _results = {};
  final Set<int> _revealed = {};
  late final List<TextEditingController> _controllers =
      List.generate(widget.items.length, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Answer checking ────────────────────────────────────────────────────────

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[’‘`´]"), "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s.,;:!?«»"]+|[\s.,;:!?«»"]+$'), '')
      .trim();

  static String _stripAccents(String s) {
    const from = 'àâäáãéèêëíìîïóòôöõúùûüçñœæ';
    const to = 'aaaaaeeeeiiiiooooouuuucnoa';
    final buffer = StringBuffer();
    for (final ch in s.split('')) {
      final i = from.indexOf(ch);
      buffer.write(i == -1 ? ch : to[i]);
    }
    return buffer.toString();
  }

  _Result _checkTyped(Map<String, dynamic> item, String input) {
    final given = _normalize(input);
    if (given.isEmpty) return _Result.wrong;
    final accepted = <String>[
      item['answer'].toString(),
      ...((item['alternatives'] as List?) ?? const []).map((a) => a.toString()),
    ].map(_normalize).where((a) => a.isNotEmpty).toList();

    if (accepted.contains(given)) return _Result.correct;
    final plain = _stripAccents(given);
    if (accepted.any((a) => _stripAccents(a) == plain)) return _Result.accentsOnly;
    return _Result.wrong;
  }

  int get _gradable => widget.items.where((i) => (i['answer'] ?? '') != '' || i['options'] != null).length;
  int get _score => _results.values.where((r) => r == _Result.correct).length;

  void _reset() {
    setState(() {
      _chosen.clear();
      _results.clear();
      _revealed.clear();
      for (final c in _controllers) {
        c.clear();
      }
    });
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.success;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: color, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ),
              if (_gradable > 0)
                Text('$_score / $_gradable', textDirection: TextDirection.ltr,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          if (widget.instruction.isNotEmpty) ...[
            const SizedBox(height: 8),
            TranslatedText(widget.instruction,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
          ],
          const SizedBox(height: 12),
          for (int i = 0; i < widget.items.length; i++) _buildItem(i),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(tr(context, 'Start again')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int index) {
    final item = widget.items[index];
    final options = item['options'] as List<String>?;
    final isOpen = options == null && (item['answer'] ?? '') == '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // French content always reads left-to-right, even in the Arabic UI.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text('${index + 1}. ${item['question']}',
                style: TextStyle(fontSize: 16, color: AppTheme.textPrimary, height: 1.5)),
          ),
          const SizedBox(height: 10),
          if (options != null)
            _buildOptions(index, options, item['correct'] as int)
          else if (isOpen)
            _buildOpen(index, item)
          else
            _buildTyped(index, item),
          if (_feedbackVisible(index, isOpen) && (item['explanation'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            TranslatedText(item['explanation'].toString(),
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
          ],
        ],
      ),
    );
  }

  bool _feedbackVisible(int index, bool isOpen) =>
      isOpen ? _revealed.contains(index) : _results.containsKey(index);

  Widget _buildOptions(int index, List<String> options, int correct) {
    final chosen = _chosen[index];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int o = 0; o < options.length; o++)
            ChoiceChip(
              label: Text(options[o]),
              selected: chosen == o,
              showCheckmark: false,
              selectedColor: (o == correct ? AppTheme.success : AppTheme.error).withValues(alpha: 0.35),
              side: BorderSide(
                color: chosen != null && o == correct
                    ? AppTheme.success
                    : AppTheme.fg.withValues(alpha: 0.15),
              ),
              onSelected: chosen != null
                  ? null
                  : (_) => setState(() {
                        _chosen[index] = o;
                        _results[index] = o == correct ? _Result.correct : _Result.wrong;
                      }),
            ),
        ],
      ),
    );
  }

  Widget _buildTyped(int index, Map<String, dynamic> item) {
    final result = _results[index];
    final locked = result == _Result.correct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controllers[index],
                  enabled: !locked,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(hintText: tr(context, 'Your answer'), isDense: true),
                  onSubmitted: (_) => _submitTyped(index, item),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: locked ? null : () => _submitTyped(index, item),
                child: Text(tr(context, 'Check')),
              ),
            ],
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              switch (result) {
                _Result.correct => '✅ Correct !',
                _Result.accentsOnly => '🟡 Presque ! Vérifiez les accents.',
                _Result.wrong => '❌ Réponse : ${item['answer']}',
              },
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: switch (result) {
                  _Result.correct => AppTheme.success,
                  _Result.accentsOnly => AppTheme.warning,
                  _Result.wrong => AppTheme.error,
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _submitTyped(int index, Map<String, dynamic> item) {
    setState(() => _results[index] = _checkTyped(item, _controllers[index].text));
  }

  Widget _buildOpen(int index, Map<String, dynamic> item) {
    if (!_revealed.contains(index)) {
      return OutlinedButton.icon(
        onPressed: () => setState(() => _revealed.add(index)),
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: Text(tr(context, 'See a model answer')),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(item['model_answer'].toString(),
            style: TextStyle(color: AppTheme.textPrimary, height: 1.5)),
      ),
    );
  }
}
