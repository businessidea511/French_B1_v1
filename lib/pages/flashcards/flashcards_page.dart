import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/grammar_topic.dart';

import '../../services/deepseek_service.dart';

class FlashcardsPage extends StatefulWidget {
  const FlashcardsPage({super.key});

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> {
  String? selectedTopic;
  int currentCard = 0;
  bool showAnswer = false;
  bool _isLoading = false;
  List<Map<String, String>> cards = [];

  final Map<String, List<Map<String, String>>> staticCards = {
    'passe_compose': [
      {
        'front': 'How to form Passé Composé?',
        'back': 'AVOIR/ÊTRE + past participle'
      },
      {
        'front': 'Passé Composé is for...',
        'back': 'Completed actions in the past'
      },
    ],
  };

  Future<void> _startAIFlashcards(String topic) async {
    setState(() {
      selectedTopic = topic;
      _isLoading = true;
      cards = [];
    });

    try {
      final aiCards = await DeepSeekService.generateFlashcards(topic);
      setState(() {
        cards = aiCards;
        _isLoading = false;
        currentCard = 0;
        showAnswer = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        cards = staticCards[topic] ?? [];
      });
      if (cards.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Failed to generate AI flashcards. Check your API key.')),
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: grammarTopics.map((topic) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(topic.icon, style: const TextStyle(fontSize: 24)),
            ),
            title: Text(topic.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Generate 10 dynamic cards'),
            trailing: const Icon(Icons.auto_awesome, color: AppTheme.secondary),
            onTap: () => _startAIFlashcards(topic.id),
          ),
        );
      }).toList(),
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
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.textTertiary),
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
                  gradient: showAnswer
                      ? AppTheme.studyBackGradient
                      : AppTheme.studyFrontGradient,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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
                              color: Colors.white.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          showAnswer ? card['back']! : card['front']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 32),
                        Icon(
                            showAnswer
                                ? Icons.check_circle_outline
                                : Icons.help_outline,
                            color: Colors.white.withOpacity(0.4),
                            size: 48),
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
