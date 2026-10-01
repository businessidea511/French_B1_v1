import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/lesson_topic.dart';
import '../../services/progress_service.dart';
import '../../services/ui_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lesson_template.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';

/// One part of a long lesson: a section title and the widgets under it.
class LessonPart {
  final String title;
  final String emoji;
  final List<dynamic> widgets;
  const LessonPart(this.title, this.emoji, this.widgets);
}

/// Splits long lessons (widget format) at their section titles, so they can
/// be studied one part at a time instead of one very long page.
class LessonParts {
  final List<dynamic> intro;
  final List<LessonPart> parts;
  const LessonParts(this.intro, this.parts);

  static const minParts = 3;
  static const minWidgets = 12;

  /// Null when the lesson is short (or in the old format): it stays one page.
  static LessonParts? split(List<dynamic>? content, String Function(String) clean) {
    if (content == null || content.length < minWidgets) return null;
    if (content.first is! Map || !(content.first as Map).containsKey('type')) return null;
    final intro = <dynamic>[];
    final parts = <LessonPart>[];
    for (final w in content) {
      if (w is Map && w['type'] == 'section_title' && clean('${w['title'] ?? ''}').isNotEmpty) {
        parts.add(LessonPart(clean('${w['title']}'), '${w['emoji'] ?? '📖'}', []));
      } else if (parts.isEmpty) {
        intro.add(w);
      } else {
        parts.last.widgets.add(w);
      }
    }
    parts.removeWhere((p) => p.widgets.isEmpty);
    return parts.length >= minParts ? LessonParts(intro, parts) : null;
  }
}

typedef PartBuilder = List<Widget> Function(List<dynamic> widgets);

String _doneKey(LessonTopic topic) => 'lesson_parts_done_${topic.id}';

/// The list of parts on the lesson's first page, with what is already done.
class LessonPartsList extends StatefulWidget {
  final LessonTopic topic;
  final List<LessonPart> parts;
  final PartBuilder buildPart;

  const LessonPartsList({super.key, required this.topic, required this.parts, required this.buildPart});

  @override
  State<LessonPartsList> createState() => _LessonPartsListState();
}

class _LessonPartsListState extends State<LessonPartsList> {
  Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getStringList(_doneKey(widget.topic)) ?? const [];
      if (mounted) setState(() => _done = done.toSet());
    } catch (_) {}
  }

  Future<void> _open(int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonPartPage(topic: widget.topic, parts: widget.parts, index: index, buildPart: widget.buildPart),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.parts.length;
    final done = widget.parts.where((p) => _done.contains(p.title)).length;
    final nextIndex = widget.parts.indexWhere((p) => !_done.contains(p.title));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(tr(context, 'This lesson has {n} parts. Open one at a time.', {'n': total}),
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: total == 0 ? 0 : done / total, minHeight: 8),
              ),
            ),
            const SizedBox(width: 12),
            Text(tr(context, '{done} / {total} parts done', {'done': done, 'total': total}),
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 14),
        for (final (i, part) in widget.parts.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Entrance(
              index: i,
              child: Tilt3D(
                maxTilt: 0.06,
                onTap: () => _open(i),
                child: GlassCard(
                  glow: i == nextIndex ? AppTheme.primary : null,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      _Badge(number: i + 1, done: _done.contains(part.title)),
                      const SizedBox(width: 14),
                      Text(part.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TranslatedText(part.title,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      ),
                      Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (nextIndex >= 0) ...[
          const SizedBox(height: 6),
          GlowButton(
            label: done == 0 ? tr(context, 'Start') : tr(context, 'Next part'),
            icon: Icons.play_arrow_rounded,
            onPressed: () => _open(nextIndex),
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final int number;
  final bool done;
  const _Badge({required this.number, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppTheme.success : AppTheme.primary.withValues(alpha: 0.15),
      ),
      child: done
          ? Icon(Icons.check_rounded, color: AppTheme.onColor, size: 20)
          : Text('$number', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900)),
    );
  }
}

/// One part of a long lesson, with buttons to the previous and next part.
class LessonPartPage extends StatefulWidget {
  final LessonTopic topic;
  final List<LessonPart> parts;
  final int index;
  final PartBuilder buildPart;

  const LessonPartPage({super.key, required this.topic, required this.parts, required this.index, required this.buildPart});

  @override
  State<LessonPartPage> createState() => _LessonPartPageState();
}

class _LessonPartPageState extends State<LessonPartPage> {
  @override
  void initState() {
    super.initState();
    _markDone();
  }

  /// A part counts as done once opened; the first time gives a little XP.
  Future<void> _markDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _doneKey(widget.topic);
      final done = (prefs.getStringList(key) ?? const <String>[]).toSet();
      final title = widget.parts[widget.index].title;
      if (done.add(title)) {
        await prefs.setStringList(key, done.toList());
        ProgressService.instance.addXp(3);
      }
    } catch (_) {}
  }

  void _go(int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LessonPartPage(topic: widget.topic, parts: widget.parts, index: index, buildPart: widget.buildPart),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final part = widget.parts[widget.index];
    final total = widget.parts.length;
    final last = widget.index == total - 1;
    return LessonTemplate(
      title: part.title,
      icon: part.emoji,
      children: [
        Text(tr(context, 'Part {n} of {total}', {'n': widget.index + 1, 'total': total}),
            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        ...widget.buildPart(part.widgets),
        const SizedBox(height: 24),
        Row(
          children: [
            if (widget.index > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _go(widget.index - 1),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(tr(context, 'Previous part')),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
            if (widget.index > 0) const SizedBox(width: 12),
            Expanded(
              child: GlowButton(
                label: last ? tr(context, 'Finish') : tr(context, 'Next part'),
                icon: last ? Icons.check_rounded : Icons.arrow_forward_rounded,
                onPressed: () {
                  if (last) {
                    Confetti.burst(context);
                    Navigator.pop(context);
                  } else {
                    _go(widget.index + 1);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}
