import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/grammar_tricks.dart';
import '../../models/grammar_topic.dart';
import '../../services/grammar_tricks_service.dart';
import '../../services/lessons_provider.dart';
import '../../services/tts_service.dart';
import '../../services/ui_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';
import 'grammar_page.dart';

const _palette = [0xFF5B6CF0, 0xFF23A07F, 0xFFE0604A, 0xFFC98A0E, 0xFF9B59D0, 0xFF3D8BE0];

/// "🧠 Grammar tricks": every grammar topic as a short memory card.
class GrammarTricksPage extends StatelessWidget {
  const GrammarTricksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = context.watch<LessonsProvider>().allGrammar;
    return Scaffold(
      appBar: AppBar(title: Text('🧠 ${tr(context, 'Grammar tricks')}')),
      body: PageBody(
        children: [
          TranslatedText(
            'Not the whole lesson: only the tricks that make each rule stick in your mind, and the classic traps.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          for (final (i, t) in topics.indexed)
            Entrance(
              key: ValueKey(t.id),
              index: i,
              child: Padding(padding: const EdgeInsets.only(bottom: 10), child: _TopicRow(topic: t, color: Color(_palette[i % _palette.length]))),
            ),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final GrammarTopic topic;
  final Color color;
  const _TopicRow({required this.topic, required this.color});

  @override
  Widget build(BuildContext context) {
    final tricks = curatedTricksFor(topic.id, topic.title) ?? embeddedTricks(topic.content);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GrammarTricksDetailPage(topic: topic))),
      child: GlassCard(
        glow: color,
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
              child: Text(topic.icon, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.title,
                      textDirection: TextDirection.ltr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  tricks != null
                      ? TranslatedText(tricks.oneLine,
                          maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))
                      : Text('✨ ${tr(context, 'Tap to create the tricks')}', style: TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
                ],
              ),
            ),
            if (tricks != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Text('🧠 ${tricks.tricks.length}', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
      ),
    );
  }
}

/// The memory card of one topic.
class GrammarTricksDetailPage extends StatefulWidget {
  final GrammarTopic topic;
  const GrammarTricksDetailPage({super.key, required this.topic});

  @override
  State<GrammarTricksDetailPage> createState() => _GrammarTricksDetailPageState();
}

class _GrammarTricksDetailPageState extends State<GrammarTricksDetailPage> {
  GrammarTricks? _tricks;
  bool _loading = true;
  bool _writing = false;
  String? _error;

  GrammarTopic get _topic => widget.topic;

  @override
  void initState() {
    super.initState();
    GrammarTricksService.find(_topic.id, _topic.title, _topic.content).then((t) {
      if (!mounted) return;
      setState(() {
        _tricks = t;
        _loading = false;
      });
      if (t == null) _write();
    });
  }

  Future<void> _write() async {
    setState(() {
      _writing = true;
      _error = null;
    });
    try {
      final t = await GrammarTricksService.writeAndKeep(_topic.id, _topic.title, _topic.subtitle, _topic.content);
      if (mounted) setState(() => _tricks = t);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not create the tricks. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _tricks;
    return Scaffold(
      appBar: AppBar(title: Text('🧠 ${_topic.title}', textDirection: TextDirection.ltr, overflow: TextOverflow.ellipsis)),
      body: PageBody(
        children: [
          if (_loading || _writing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  if (_writing) Text(tr(context, 'Finding the best tricks for this topic…'), style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )
          else if (t == null)
            Column(
              children: [
                const SizedBox(height: 30),
                TranslatedText(_error ?? 'No tricks yet.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.error)),
                const SizedBox(height: 12),
                GlowButton(label: tr(context, 'Try again'), icon: Icons.refresh_rounded, onPressed: _write),
              ],
            )
          else ...[
            Entrance(
              child: GlassCard(
                glow: AppTheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎯 ${tr(context, 'In one line')}',
                        style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(height: 6),
                    TranslatedText(t.oneLine, style: TextStyle(fontSize: 17, height: 1.4, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ],
                ),
              ),
            ),
            SectionTitle('💡 ${tr(context, 'Tricks to remember')}'),
            for (final (i, trick) in t.tricks.indexed)
              Entrance(index: i + 1, child: _TrickCard(number: i + 1, trick: trick, color: Color(_palette[i % _palette.length]))),
            if (t.traps.isNotEmpty) ...[
              SectionTitle('⚠️ ${tr(context, 'Classic traps')}'),
              for (final (i, trap) in t.traps.indexed) Entrance(index: i + 1, child: _TrapCard(trap: trap)),
            ],
            const SizedBox(height: 18),
            GlowButton(
              label: tr(context, 'Open the full lesson'),
              icon: Icons.menu_book_rounded,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => grammarPageFor(_topic))),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrickCard extends StatelessWidget {
  final int number;
  final MemoryTrick trick;
  final Color color;
  const _TrickCard({required this.number, required this.trick, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        glow: color,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Text('$number', style: TextStyle(color: AppTheme.onColor, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TranslatedText(trick.title,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, height: 1.3)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TranslatedText(trick.trick, style: TextStyle(fontSize: 15, height: 1.45, color: AppTheme.textSecondary)),
            if (trick.examples.isNotEmpty) const SizedBox(height: 10),
            for (final e in trick.examples) _ExampleLine(text: e, color: color),
          ],
        ),
      ),
    );
  }
}

class _ExampleLine extends StatelessWidget {
  final String text;
  final Color color;
  const _ExampleLine({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: BorderDirectional(start: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, height: 1.35)),
          ),
          IconButton(
            tooltip: tr(context, 'Listen'),
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.volume_up_rounded, size: 18, color: color),
            onPressed: () => TtsService.instance.speak(text),
          ),
        ],
      ),
    );
  }
}

class _TrapCard extends StatelessWidget {
  final GrammarTrap trap;
  const _TrapCard({required this.trap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        radius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('❌ ${trap.wrong}',
                textDirection: TextDirection.ltr,
                style: TextStyle(color: AppTheme.error, decoration: TextDecoration.lineThrough, decorationColor: AppTheme.error, fontSize: 15)),
            const SizedBox(height: 4),
            Text('✅ ${trap.right}',
                textDirection: TextDirection.ltr,
                style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 15)),
            if (trap.why.isNotEmpty) ...[
              const SizedBox(height: 4),
              TranslatedText(trap.why, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
