import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/grammar_topic.dart';

import '../../services/deepseek_service.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  String? selectedTopic;
  int currentQuestion = 0;
  int score = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> questions = [];

  final Map<String, List<Map<String, dynamic>>> staticExercises = {
    'passe_compose': [
      {
        'question': 'Hier, je ___ un film.',
        'options': ['ai regardé', 'suis regardé', 'regardais', 'regarderai'],
        'correct': 0,
        'explanation': 'Use Passé Composé for a completed action.',
      },
      // ... kept for fallback or mix
    ],
  };

  Future<void> _startAIExercises(String topic) async {
    setState(() {
      selectedTopic = topic;
      _isLoading = true;
      questions = [];
    });

    try {
      final aiQuestions = await DeepSeekService.generateExercises(topic, 'B1');
      setState(() {
        questions = aiQuestions;
        _isLoading = false;
        currentQuestion = 0;
        score = 0;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Fallback to static or error
        questions = staticExercises[topic] ?? [];
      });
      if (questions.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to generate AI exercises. Check your API key.')),
        );
        setState(() => selectedTopic = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
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
            'Professeur DeepSeek is preparing your exercises...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          const Text('This may take a few seconds'),
        ],
      ),
    );
  }

  Widget _buildTopicSelection() {
    return Focus(
      autofocus: true,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: grammarTopics.map((topic) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(topic.icon, style: const TextStyle(fontSize: 24)),
              ),
              title: Text(topic.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Generate 10 dynamic exercises'),
              trailing: const Icon(Icons.auto_awesome, color: AppTheme.primary),
              onTap: () => _startAIExercises(topic.id),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuiz() {
    if (questions.isEmpty) {
      return const Center(child: Text('No exercises found for this topic.'));
    }

    if (currentQuestion >= questions.length) {
      return _buildResults();
    }

    final question = questions[currentQuestion];

    return Focus(
      autofocus: true,
      child: SingleChildScrollView(
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
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'QUESTION ${currentQuestion + 1} OF ${questions.length}',
              style: const TextStyle(
                  letterSpacing: 1.5,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 16),
            Text(
              question['question'],
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 40),
            ...List.generate(
              (question['options'] as List).length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  onPressed: () => _answerQuestion(index, question['correct']),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    question['options'][index],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _answerQuestion(int selected, int correct) {
    final isCorrect = selected == correct;

    if (isCorrect) {
      setState(() => score++);
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
            const SizedBox(height: 16),
            Text(
              questions[currentQuestion]['explanation'],
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => currentQuestion++);
              },
              child: const Text('Next Question'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final percentage = (score / questions.length * 100).round();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
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
              style:
                  const TextStyle(fontSize: 18, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: percentage >= 70
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$percentage%',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: percentage >= 70
                          ? AppTheme.success
                          : AppTheme.warning,
                    ),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => selectedTopic = null),
                    child: const Text('Back to Topics'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startAIExercises(selectedTopic!),
                    child: const Text('Retry Quiz'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
