import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/language_provider.dart';
import 'grammar/grammar_page.dart';
import 'exercises/exercises_page.dart';
import 'flashcards/flashcards_page.dart';
import 'verbs/verbs_page.dart';
import 'daily_phrases/daily_phrases_page.dart';
import 'listening/listening_page.dart';
import 'lessons/lessons_page.dart';
import 'ai_book/ai_book_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final languageProvider = Provider.of<LanguageProvider>(context);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Select Your Language', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: AppLanguage.values.map((lang) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(lang.name, style: const TextStyle(color: Colors.white)),
                      trailing: languageProvider.currentLanguage == lang 
                        ? const Icon(Icons.check_circle, color: AppTheme.primary) 
                        : null,
                      onTap: () {
                        languageProvider.setLanguage(lang);
                        Navigator.pop(context);
                      },
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.background,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Header Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                                  ),
                                  child: const Text('🇫🇷 NIVEAU B1', 
                                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 10)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.language, color: Colors.white70),
                                  onPressed: () => _showLanguageSelector(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(lp.translate('greeting'), 
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text(lp.translate('subtitle'), 
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Feature Grid
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.9,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildFeatureCard(
                      context,
                      title: lp.translate('grammar'),
                      subtitle: lp.translate('master_rules'),
                      icon: '📚',
                      color: AppTheme.primary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrammarPage())),
                    ),
                    _buildFeatureCard(
                      context,
                      title: lp.translate('ai_book'),
                      subtitle: lp.translate('ai_book_desc'),
                      icon: '✨',
                      color: Colors.amber,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIBookPage())),
                    ),
                    _buildFeatureCard(
                      context,
                      title: lp.translate('exercises'),
                      subtitle: lp.translate('daily_practice'),
                      icon: '✍️',
                      color: AppTheme.secondary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExercisesPage())),
                    ),
                    _buildFeatureCard(
                      context,
                      title: lp.translate('lessons'),
                      subtitle: lp.translate('culture_vocab'),
                      icon: '📖',
                      color: Colors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LessonsPage())),
                    ),
                    _buildFeatureCard(
                      context,
                      title: lp.translate('flashcards'),
                      subtitle: lp.translate('memorize_smart'),
                      icon: '🎴',
                      color: AppTheme.success,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashcardsPage())),
                    ),
                    _buildFeatureCard(
                      context,
                      title: lp.translate('verbs'),
                      subtitle: lp.translate('conjugations'),
                      icon: '🔄',
                      color: AppTheme.warning,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerbsPage())),
                    ),
                    _buildFeatureCard(
                      context,
                      title: lp.translate('daily_phrases'),
                      subtitle: lp.translate('common_talk'),
                      icon: '🗣️',
                      color: Colors.indigo,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyPhrasesPage())),
                    ),
                    _buildFeatureCard(
                      context,
                      title: lp.translate('listening'),
                      subtitle: lp.translate('audio_skills'),
                      icon: '🎧',
                      color: Colors.teal,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListeningPage())),
                    ),
                  ]),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
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
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(isHovered ? 1.05 : 1.0),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isHovered ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (isHovered)
                      BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
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
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(icon, style: const TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(height: 12),
                            Text(title, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(subtitle, 
                              style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}
