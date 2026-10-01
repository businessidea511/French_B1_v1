import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/deepseek_service.dart';
import '../../services/language_provider.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercise_block.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';
import '../exercises/exercises_page.dart';

/// Notebook of every mistake made in the app, with a quiz to fix them and AI
/// exercises on the learner's weak points.
class MistakesPage extends StatelessWidget {
  const MistakesPage({super.key});

  static const _sourceEmoji = {
    'Exercices': '✍️',
    'Conjugaison': '🎯',
    'Dictée': '🎧',
    'Jeu de rôle': '🎭',
    'Duel': '⚔️',
  };

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressService>();
    final mistakes = progress.mistakes;
    final quizzable = mistakes.where((m) => m['source'] != 'Dictée').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('📒 Mes erreurs')),
      body: PageBody(
        children: [
          TranslatedText(
            'Every mistake you make in the exercises, games, dictations and role-plays lands here. Practise them until they disappear!',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (mistakes.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Floating(child: Text('🌈', style: TextStyle(fontSize: 70))),
                  SizedBox(height: 12),
                  Text('Aucune erreur pour le moment !',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else ...[
            if (quizzable.isNotEmpty)
              GlowButton(
                label: 'Corriger mes erreurs (${quizzable.length > 15 ? 15 : quizzable.length})',
                icon: Icons.fact_check_rounded,
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => _MistakeQuizPage(mistakes: quizzable.take(15).toList()))),
              ),
            const SizedBox(height: 10),
            GlowButton(
              label: 'Nouveaux exercices sur mes points faibles',
              icon: Icons.auto_awesome,
              colors: [AppTheme.secondary, AppTheme.accent],
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => _WeakPointsPage(mistakes: mistakes.take(25).toList()))),
            ),
            SectionTitle('${mistakes.length} erreurs'),
            for (final (i, m) in mistakes.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Entrance(index: i, child: _MistakeCard(mistake: m, emoji: _sourceEmoji[m['source']] ?? '📝')),
              ),
          ],
        ],
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  final Map<String, dynamic> mistake;
  final String emoji;
  const _MistakeCard({required this.mistake, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final explanation = (mistake['explanation'] ?? '').toString();
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${mistake['source']} · ${mistake['date']}',
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${mistake['question']}', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                      Text('❌ ${mistake['wrong']}', style: TextStyle(color: AppTheme.error)),
                      Text('✅ ${mistake['right']}',
                          style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
                if (explanation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('💡 $explanation', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Écouter',
                icon: Icon(Icons.volume_up_rounded, color: AppTheme.primary, size: 20),
                onPressed: () => TtsService.instance.speak('${mistake['right']}'),
              ),
              IconButton(
                tooltip: 'Je le sais maintenant',
                icon: Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 22),
                onPressed: () => context.read<ProgressService>().removeMistake('${mistake['id']}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quiz made of the learner's own mistakes.
class _MistakeQuizPage extends StatelessWidget {
  final List<Map<String, dynamic>> mistakes;
  const _MistakeQuizPage({required this.mistakes});

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final m in mistakes)
        if ((m['options'] as List?)?.isNotEmpty ?? false)
          {
            'question': m['question'],
            'options': m['options'],
            'correct': (m['options'] as List).indexOf(m['right']),
            'explanation': m['explanation'] ?? '',
          }
        else
          {'question': m['question'], 'answer': m['right'], 'alternatives': [], 'explanation': m['explanation'] ?? ''}
    ];
    final block = ExerciseBlock.fromJson({'title': 'Mes erreurs', 'instruction': '', 'items': items});
    return Scaffold(
      appBar: AppBar(title: const Text('📒 Corriger mes erreurs')),
      body: PageBody(children: [if (block != null) block]),
    );
  }
}

/// New AI exercises built from the learner's mistakes.
class _WeakPointsPage extends StatefulWidget {
  final List<Map<String, dynamic>> mistakes;
  const _WeakPointsPage({required this.mistakes});

  @override
  State<_WeakPointsPage> createState() => _WeakPointsPageState();
}

class _WeakPointsPageState extends State<_WeakPointsPage> {
  List<Map<String, dynamic>>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final language = context.read<LanguageProvider>().currentLanguage.englishName;
    final summary = [
      for (final m in widget.mistakes) '- ${m['question']} → learner wrote "${m['wrong']}", correct: "${m['right']}"'
    ].join('\n');
    try {
      final raw = await DeepSeekService.generateExercises(
        'The learner\'s weak points (new sentences practising the same rules as these mistakes)',
        'B1',
        language,
        topicContent: 'MISTAKES THE LEARNER MADE:\n$summary',
      );
      final items = ExercisesPage.sanitize(raw);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not create exercises. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final block = _items == null ? null : ExerciseBlock.fromJson({'title': 'Mes points faibles', 'instruction': '', 'items': _items});
    return Scaffold(
      appBar: AppBar(title: const Text('✨ Mes points faibles')),
      body: PageBody(
        children: [
          if (_error != null)
            Text(_error!, style: TextStyle(color: AppTheme.error))
          else if (block == null)
            Padding(
              padding: EdgeInsets.only(top: 80),
              child: Column(children: [
                Floating(child: Text('🧠', style: TextStyle(fontSize: 64))),
                SizedBox(height: 12),
                TranslatedText('Professeur AI is studying your mistakes…', style: TextStyle(color: AppTheme.textSecondary)),
              ]),
            )
          else
            block,
        ],
      ),
    );
  }
}
