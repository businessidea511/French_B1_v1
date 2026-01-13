import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/deepseek_service.dart';

class ExamenOnePage extends StatefulWidget {
  const ExamenOnePage({super.key});

  @override
  State<ExamenOnePage> createState() => _ExamenOnePageState();
}

class _ExamenOnePageState extends State<ExamenOnePage> {
  bool _isExamStarted = false;
  bool _isLoading = false;
  int currentQuestion = 0;
  int score = 0;
  List<Map<String, dynamic>> questions = [];

  // Manual copy of text from image
  Widget _buildInfoSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildSectionTitle('QUOI ?'),
          const SizedBox(height: 16),
          const Text(
            "Les 5 compétences de l'UE1 seront évaluées :",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildBulletPoint('comprendre des messages oraux (= écouter)'),
          _buildBulletPoint('comprendre des messages écrits (= lire)'),
          _buildBulletPoint(
              'prendre part à une conversation (= parler en groupe)'),
          _buildBulletPoint("s'exprimer oralement en continu (= parler seul)"),
          _buildBulletPoint("s'exprimer par écrit (= écrire)"),
          const SizedBox(height: 16),
          const Text(
            'La note finale sera sur 100.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('QUAND ?'),
          const SizedBox(height: 16),
          _buildDatePoint(
              'Mercredi 07/01 & vendredi 09/01', 'révisions en classe'),
          _buildDatePoint('Mercredi 14/01 & vendredi 16/01',
              'examens d’entraînement en classe (= révisions)'),
          _buildDatePoint('Mercredi 21/01',
              'EXAMEN sur « comprendre des messages oraux, s’exprimer oralement en continu »',
              isHighlight: true),
          _buildDatePoint('Vendredi 23/01',
              'EXAMEN sur « comprendre des messages écrits, prendre part à une conversation, s’exprimer par écrit ».',
              isHighlight: true),
          _buildDatePoint(
              'Mercredi 28/01 ou vendredi 30/01', 'deuxième chance (si raté)'),
          _buildDatePoint('Vendredi 30/01', 'remise des points'),
          const SizedBox(height: 32),
          _buildSectionTitle('QUE FAIRE ?'),
          const SizedBox(height: 16),
          _buildSubSection('Revoir le vocabulaire :',
              'des thèmes abordés depuis septembre (logement/quartier/enfance/...)'),
          const SizedBox(height: 12),
          _buildSubSection('Savoir :',
              'à l’écrit et à l’oral : raconter un évènement au passé en articulant correctement les temps, présenter son logement/son quartier, exprimer des souhaits au conditionnel, exprimer des actions situées dans le futur, résumer un fait divers, ...'),
          const SizedBox(height: 12),
          _buildSubSection('Langue :',
              'les temps verbaux du passé (imparfait, plus-que-parfait et passé composé), du présent (indicatif présent et conditionnel présent) et du futur (futur simple et futur proche). Les structures grammaticales vues en classe (Si j’avais..., j’aurais... / Si seulement il avait fait ça !, ...)'),
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton.icon(
              onPressed: _startExam,
              icon: const Icon(Icons.play_arrow),
              label: const Text('COMMENCER L\'EXAMEN (Entraînement)'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: const Text(
          'Groupe de FLE Caramel : évaluations de janvier 2025',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ));
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
        color: AppTheme.primary,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildDatePoint(String date, String activity,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontFamily: 'Outfit', // Ensure font matches app
                ),
                children: [
                  TextSpan(
                      text: '$date : ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isHighlight ? AppTheme.primary : null,
                          decoration:
                              isHighlight ? TextDecoration.underline : null)),
                  TextSpan(text: activity),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('- $title',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 4),
          child: Text(content, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  // --- Logic for Exam ---

  Future<void> _startExam() async {
    setState(() {
      _isLoading = true;
      _isExamStarted = true;
      questions = [];
      score = 0;
      currentQuestion = 0;
    });

    try {
      // Custom prompt for the specific exam topics
      // Topics: Passé (imp, pqp, pc), Présent, Futur (simple, proche), Conditionnel, Si clauses.
      // We will trick the DeepSeekService or just call it
      // Actually, DeepSeekService.generateExercises takes a 'topic'.
      // I'll send a custom formatted string and hope the service handles it or I'll modify the service call inline?
      // The service uses: "Generate $count multiple choice exercises for French B1 topic: $topic."
      // So I can pass a long string describing the topics.
      final topicDescription =
          "Review of: Passé Composé, Imparfait, Plus-que-parfait, Conditionnel, Futur Simple, Futur Proche, and 'Si' clauses (Si j'avais..., j'aurais...). Context: Housing, Childhood, Neighborhood.";

      final aiQuestions = await DeepSeekService.generateExercises(
          topicDescription, 'B1',
          count: 15);

      final sanitizedQuestions = aiQuestions.map((q) {
        final List<String> options = List<String>.from(q['options']);
        final String correctText = options[q['correct']];
        final uniqueOptions = options.toSet().toList();
        uniqueOptions.shuffle();
        final newCorrectIndex = uniqueOptions.indexOf(correctText);
        return {
          ...q,
          'options': uniqueOptions,
          'correct': newCorrectIndex,
        };
      }).toList();

      setState(() {
        questions = sanitizedQuestions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating exam: $e')),
        );
        setState(() {
          _isLoading = false;
          _isExamStarted = false; // Go back to info page
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Examen Janvier 2025'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isExamStarted) {
              setState(() {
                _isExamStarted = false;
                questions = [];
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _isExamStarted
          ? (_isLoading ? _buildLoadingState() : _buildQuiz())
          : _buildInfoSection(),
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
            'Préparation de votre examen...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          const Text('Génération des questions sur les 5 compétences...'),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    if (questions.isEmpty) {
      return const Center(child: Text('Erreur de chargement.'));
    }

    if (currentQuestion >= questions.length) {
      return _buildResults();
    }

    final question = questions[currentQuestion];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${currentQuestion + 1}/${questions.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Examen Blanc',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (currentQuestion + 1) / questions.length,
              minHeight: 10,
              backgroundColor: AppTheme.surface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 32),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                  isCorrect ? 'Correct' : 'Incorrect',
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
              child: const Text('Question Suivante'),
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
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 32),
            Text(
              'Examen Terminé!',
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Score: $score / ${questions.length}',
              style:
                  const TextStyle(fontSize: 18, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: percentage >= 50
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$percentage%',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color:
                          percentage >= 50 ? AppTheme.success : AppTheme.error,
                    ),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isExamStarted = false;
                  questions = [];
                });
              },
              child: const Text('Retour aux détails'),
            ),
          ],
        ),
      ),
    );
  }
}
