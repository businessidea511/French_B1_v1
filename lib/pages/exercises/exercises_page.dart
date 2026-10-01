import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/deepseek_service.dart';
import '../../services/topic_context.dart';
import '../../services/language_provider.dart';
import '../../services/lessons_provider.dart';
import '../../services/global_scroll_manager.dart';
import '../../services/progress_service.dart';
import '../../services/ui_strings.dart';

class ExercisesPage extends StatefulWidget {
  final String? initialTopic;
  const ExercisesPage({super.key, this.initialTopic});

  /// Drops malformed AI questions, removes duplicate options, shuffles the
  /// options and re-points "correct" at the right one.
  static List<Map<String, dynamic>> sanitize(List<Map<String, dynamic>> raw) {
    final out = <Map<String, dynamic>>[];
    for (final q in raw) {
      final question = (q['question'] ?? '').toString().trim();
      final rawOptions = q['options'];
      final correct = q['correct'];
      if (question.isEmpty || rawOptions is! List || correct is! num) continue;
      final ci = correct.toInt();
      if (ci < 0 || ci >= rawOptions.length) continue;
      final correctText = rawOptions[ci].toString().trim();
      final options = rawOptions.map((o) => o.toString().trim()).where((o) => o.isNotEmpty).toSet().toList()
        ..shuffle();
      if (options.length < 2 || !options.contains(correctText)) continue;
      out.add({
        ...q,
        'question': question,
        'options': options,
        'correct': options.indexOf(correctText),
        'explanation': (q['explanation'] ?? '').toString(),
        'translation': q['translation']?.toString(),
      });
    }
    return out;
  }

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  String? selectedTopic;
  int currentQuestion = 0;
  int score = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> questions = [];
  final List<int> _chosen = []; // the option picked for each answered question
  final Map<String, int> _best = {}; // best score (%) per topic, saved on this device
  final ScrollController _scrollController = ScrollController();

  static const String _bestPrefix = 'exercise_best_';

  @override
  void initState() {
    super.initState();
    GlobalScrollManager.register(_scrollController);
    _loadBestScores();
    if (widget.initialTopic != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAIExercises(widget.initialTopic!);
      });
    }
  }

  @override
  void dispose() {
    GlobalScrollManager.unregister(_scrollController);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBestScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = {
        for (final k in prefs.getKeys().where((k) => k.startsWith(_bestPrefix)))
          k.substring(_bestPrefix.length): prefs.getInt(k) ?? 0,
      };
      if (mounted) setState(() => _best.addAll(saved));
    } catch (e) {
      debugPrint('Could not load best scores: $e');
    }
  }

  Future<void> _saveBestScore(String topic, int percent) async {
    if ((_best[topic] ?? -1) >= percent) return;
    setState(() => _best[topic] = percent);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_bestPrefix$topic', percent);
    } catch (e) {
      debugPrint('Could not save best score: $e');
    }
  }

  Future<void> _startAIExercises(String topic) async {
    setState(() {
      selectedTopic = topic;
      _isLoading = true;
      questions = [];
      _chosen.clear();
    });

    try {
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      final topicContent = topic == 'mixed_review'
          ? null
          : TopicContext.forTitle(Provider.of<LessonsProvider>(context, listen: false), topic);
      final aiQuestions = await DeepSeekService.generateExercises(
          topic, 'B1', lp.currentLanguage.englishName,
          topicContent: topicContent);

      final sanitizedQuestions = ExercisesPage.sanitize(aiQuestions);
      if (sanitizedQuestions.isEmpty) throw Exception('No usable questions');

      if (mounted) {
        setState(() {
          questions = sanitizedQuestions;
          _isLoading = false;
          currentQuestion = 0;
          score = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          questions = []; // No static fallback for now to keep it fresh
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'Could not create exercises. Please try again.'))),
        );
        setState(() => selectedTopic = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Exercises')),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : selectedTopic == null
              ? _buildTopicSelection()
              : _buildQuiz(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Professeur AI is preparing your exercises...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(tr(context, 'This may take a few seconds')),
        ],
      ),
    );
  }

  Widget _buildTopicSelection() {
    final lessonsProvider = Provider.of<LessonsProvider>(context);
    final grammarItems = lessonsProvider.allGrammar;
    final lessonItems = lessonsProvider.allLessons;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        // Special Mixed Review Card
        // Special Mixed Review Card
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _startAIExercises('mixed_review'),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.8),
                              AppTheme.primary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('⭐', style: TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'B1 General Review',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppTheme.textPrimary,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Final Exam style: All tenses + COD/COI',
                              style: TextStyle(
                                color: AppTheme.fg.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.auto_awesome, color: AppTheme.primary, size: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        const SectionHeader('GRAMMAR TOPICS'),
        ...grammarItems.map((topic) => _buildTopicTile(topic.title, topic.icon, topic.id)),
        
        const SizedBox(height: 24),
        const SectionHeader('LESSON TOPICS'),
        ...lessonItems.map((topic) => _buildTopicTile(topic.title, topic.icon, topic.id)),
      ],
    );
  }

  Widget _buildTopicTile(String title, String icon, String id) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.fg.withValues(alpha: 0.05), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startAIExercises(title),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _best.containsKey(title)
                            ? 'Best: ${_best[title]}% · 10 new questions each time'
                            : '10 new questions each time',
                        style: TextStyle(
                          color: _best.containsKey(title)
                              ? ((_best[title] ?? 0) >= 70 ? AppTheme.success : AppTheme.warning)
                              : AppTheme.fg.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    if (questions.isEmpty) {
      return Center(child: Text(tr(context, 'No exercises found for this topic.')));
    }

    if (currentQuestion >= questions.length) {
      return _buildResults();
    }

    final question = questions[currentQuestion];

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (currentQuestion + 1) / questions.length,
              minHeight: 10,
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'QUESTION ${currentQuestion + 1} OF ${questions.length}',
            style: TextStyle(
                letterSpacing: 1.5,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              question['question'],
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          if (question['translation'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.translate, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question['translation'],
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.fg.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 40),
          ...List.generate(
            (question['options'] as List).length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: () => _answerQuestion(index, question['correct']),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  alignment: Alignment.centerLeft,
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    question['options'][index],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _answerQuestion(int selected, int correct) {
    final isCorrect = selected == correct;
    final correctText = (questions[currentQuestion]['options'] as List)[correct].toString();
    _chosen.add(selected);

    if (isCorrect) {
      setState(() => score++);
      ProgressService.instance.addXp(3);
    } else {
      final q = questions[currentQuestion];
      final options = [for (final o in q['options'] as List) o.toString()];
      ProgressService.instance.addMistake(
        source: 'Exercices',
        question: q['question'].toString(),
        wrong: options[selected],
        right: correctText,
        explanation: (q['explanation'] ?? '').toString(),
        options: options,
      );
      ProgressService.instance.addXp(1);
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? AppTheme.success : AppTheme.error,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  isCorrect ? 'Excellent!' : 'Pas tout à fait...',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isCorrect ? AppTheme.success : AppTheme.error,
                      ),
                ),
              ],
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text('✅ $correctText',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.success)),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'EXPLICATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              questions[currentQuestion]['explanation'] ?? '',
              style: TextStyle(fontSize: 16, height: 1.5, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => currentQuestion++);
                if (currentQuestion >= questions.length && selectedTopic != null) {
                  _saveBestScore(selectedTopic!, (score / questions.length * 100).round());
                }
              },
              child: Text(currentQuestion + 1 >= questions.length ? 'See my results' : 'Next Question'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final percentage = (score / questions.length * 100).round();

    final mistakes = [
      for (var i = 0; i < questions.length && i < _chosen.length; i++)
        if (_chosen[i] != questions[i]['correct']) i
    ];

    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🎯', style: TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 32),
            Text(
              'Quiz Complete!',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'You scored $score out of ${questions.length}',
              style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: percentage >= 70
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$percentage%',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: percentage >= 70 ? AppTheme.success : AppTheme.warning,
                    ),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => selectedTopic = null),
                    child: Text(tr(context, 'Back to topics')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startAIExercises(selectedTopic!),
                    child: Text(tr(context, 'New questions')),
                  ),
                ),
              ],
            ),
            if (mistakes.isNotEmpty) ...[
              const SizedBox(height: 40),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(tr(context, 'Review your mistakes ({n})', {'n': mistakes.length}),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ),
              const SizedBox(height: 12),
              for (final i in mistakes) _buildMistakeReview(i),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMistakeReview(int i) {
    final q = questions[i];
    final options = q['options'] as List;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}. ${q['question']}', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                const SizedBox(height: 8),
                Text('❌ ${options[_chosen[i]]}', style: TextStyle(color: AppTheme.error)),
                Text('✅ ${options[q['correct']]}',
                    style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if ((q['explanation'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(q['explanation'], style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 8),
      child: Text(
        title,
        style: TextStyle(
          letterSpacing: 1.5,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textTertiary,
        ),
      ),
    );
  }
}
