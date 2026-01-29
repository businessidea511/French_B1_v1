import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/language_provider.dart';
import 'grammar/grammar_page.dart';
import 'exercises/exercises_page.dart';
import 'flashcards/flashcards_page.dart';
import 'verbs/verbs_page.dart';
import 'examen/examen_one_page.dart';
import 'essay/essay_page.dart';
import 'dialogue/dialogue_page.dart';
import 'listening/listening_page.dart';
import 'daily_phrases/daily_phrases_page.dart';

import 'package:flutter/foundation.dart'; // Import for kDebugMode

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Helper to determine if we should show local-only features
  static const bool _showLocalFeatures = kDebugMode ||
      bool.fromEnvironment('SHOW_LOCAL_FEATURES', defaultValue: false);

  void _showLanguageSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final languageProvider =
            Provider.of<LanguageProvider>(context, listen: false);
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(
            languageProvider.translate('select_language'),
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppLanguage.values.length,
              itemBuilder: (context, index) {
                final language = AppLanguage.values[index];
                return ListTile(
                  title: Text(
                    language.name,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  trailing: languageProvider.currentLanguage == language
                      ? const Icon(Icons.check, color: AppTheme.primary)
                      : null,
                  onTap: () {
                    languageProvider.setLanguage(language);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.background,
              const Color(0xFF1E293B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: CustomScrollView(
                primary: true,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.language,
                                    color: AppTheme.primary),
                                onPressed: () => _showLanguageSelector(context),
                                tooltip: languageProvider
                                    .translate('select_language'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                  color: AppTheme.primary.withOpacity(0.2)),
                            ),
                            child: const Text(
                              '🇫🇷 NIVEAU B1',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            languageProvider.translate('greeting'),
                            style: Theme.of(context).textTheme.displayLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            languageProvider.translate('subtitle'),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 900
                            ? 4
                            : MediaQuery.of(context).size.width > 600
                                ? 2
                                : 1,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        childAspectRatio: 1,
                      ),
                      delegate: SliverChildListDelegate([
                        _buildFeatureCard(
                          context,
                          title: languageProvider.translate('grammar'),
                          subtitle: '9 Essential Lessons',
                          icon: '📚',
                          color: AppTheme.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const GrammarPage()),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          title: languageProvider.translate('exercises'),
                          subtitle: 'Practice & Feedback',
                          icon: '✍️',
                          color: AppTheme.secondary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ExercisesPage()),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          title: languageProvider.translate('flashcards'),
                          subtitle: 'Smart Memorization',
                          icon: '🎴',
                          color: AppTheme.success,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const FlashcardsPage()),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          title: languageProvider.translate('verbs'),
                          subtitle: 'Conjugation Tables',
                          icon: '🔄',
                          color: AppTheme.warning,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const VerbsPage()),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          title: languageProvider.translate('examen'),
                          subtitle: 'Janvier 2025',
                          icon: '📝',
                          color: AppTheme.accent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ExamenOnePage()),
                            );
                          },
                        ),
                        if (_showLocalFeatures)
                          _buildFeatureCard(
                            context,
                            title: languageProvider.translate('essays'),
                            subtitle: 'Rédactions & Histoires',
                            icon: '📖',
                            color: Colors.purple,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const EssayPage()),
                              );
                            },
                          ),
                        if (_showLocalFeatures)
                          _buildFeatureCard(
                            context,
                            title: languageProvider.translate('dialogues'),
                            subtitle: 'Situations Réelles',
                            icon: '💬',
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const DialoguePage()),
                              );
                            },
                          ),
                        _buildFeatureCard(
                          context,
                          title: languageProvider.translate('daily_phrases'),
                          subtitle: 'Common Sentences',
                          icon: '🗣️',
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const DailyPhrasesPage()),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          title: languageProvider.translate('listening'),
                          subtitle: 'Compréhension Orale',
                          icon: '🎧',
                          color: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ListeningPage()),
                            );
                          },
                        ),
                      ]),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 60),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textTertiary,
                            fontSize: 14,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
