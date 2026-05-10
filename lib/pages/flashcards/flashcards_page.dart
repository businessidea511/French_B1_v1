import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/deepseek_service.dart';
import '../../services/lessons_provider.dart';

class FlashcardsPage extends StatefulWidget {
  final String? initialTopic;
  const FlashcardsPage({super.key, this.initialTopic});

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> {
  String? selectedTopic;
  int currentCard = 0;
  bool showAnswer = false;
  bool _isLoading = false;
  List<Map<String, String>> cards = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialTopic != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAIFlashcards(widget.initialTopic!);
      });
    }
  }

  Future<void> _startAIFlashcards(String topic) async {
    setState(() {
      selectedTopic = topic;
      _isLoading = true;
      cards = [];
    });

    try {
      final aiCards = await DeepSeekService.generateFlashcards(topic);
      if (mounted) {
        setState(() {
          cards = aiCards;
          _isLoading = false;
          currentCard = 0;
          showAnswer = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          cards = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate AI flashcards. Check your API key.')),
        );
        setState(() => selectedTopic = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : selectedTopic == null
              ? _buildTopicSelection()
              : _buildFlashcard(),
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
            'AI is shuffling your flashcards...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildTopicSelection() {
    final lessonsProvider = Provider.of<LessonsProvider>(context);
    final grammarItems = lessonsProvider.allGrammar;
    final lessonItems = lessonsProvider.allLessons;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionHeader('GRAMMAR FLASHCARDS'),
        ...grammarItems.map((topic) => _buildTopicTile(topic.title, topic.icon)),
        
        const SizedBox(height: 24),
        const SectionHeader('LESSON FLASHCARDS'),
        ...lessonItems.map((topic) => _buildTopicTile(topic.title, topic.icon)),
      ],
    );
  }

  Widget _buildTopicTile(String title, String icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(icon, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Generate 10 dynamic cards'),
        trailing: const Icon(Icons.auto_awesome, color: AppTheme.secondary),
        onTap: () => _startAIFlashcards(title),
      ),
    );
  }

  Widget _buildFlashcard() {
    if (cards.isEmpty) return const Center(child: Text('No cards found.'));
    final card = cards[currentCard];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => selectedTopic = null),
              ),
              Text(
                'CARD ${currentCard + 1} OF ${cards.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textTertiary),
              ),
              IconButton(
                icon: const Icon(Icons.shuffle),
                onPressed: () => setState(() => cards.shuffle()),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GestureDetector(
              onTap: () => setState(() => showAnswer = !showAnswer),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: showAnswer ? AppTheme.studyBackGradient : AppTheme.studyFrontGradient,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          showAnswer ? 'RÉPONSE' : 'QUESTION',
                          style: TextStyle(
                              letterSpacing: 2,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          showAnswer ? card['back']! : card['front']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 32),
                        Icon(showAnswer ? Icons.check_circle_outline : Icons.help_outline,
                            color: Colors.white.withValues(alpha: 0.1), size: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: currentCard > 0
                      ? () => setState(() {
                            currentCard--;
                            showAnswer = false;
                          })
                      : null,
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: currentCard < cards.length - 1
                      ? () => setState(() {
                            currentCard++;
                            showAnswer = false;
                          })
                      : null,
                  child: const Text('Next Card'),
                ),
              ),
            ],
          ),
        ),
      ],
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
        style: const TextStyle(
          letterSpacing: 1.5,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textTertiary,
        ),
      ),
    );
  }
}
