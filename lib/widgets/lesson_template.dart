import 'package:flutter/material.dart';
import 'translated_text.dart';
import 'ask_ai_box.dart';
import '../pages/exercises/exercises_page.dart';
import '../pages/flashcards/flashcards_page.dart';
import '../theme/app_theme.dart';

class LessonTemplate extends StatefulWidget {
  final String title;
  final String icon;
  final String? topic; // Optional: used for AI questions
  final List<Widget> children;

  const LessonTemplate({
    super.key,
    required this.title,
    required this.icon,
    this.topic,
    required this.children,
  });

  @override
  State<LessonTemplate> createState() => _LessonTemplateState();
}

class _LessonTemplateState extends State<LessonTemplate> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.background,
              AppTheme.surface.withValues(alpha: 0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          child: PrimaryScrollController(
            controller: _scrollController,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${widget.icon} '),
                      TranslatedText(
                        widget.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary.withValues(alpha: 0.1), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ...widget.children,
                    if (widget.topic != null) ...[
                      const SizedBox(height: 60),
                      AskAIBox(topic: widget.topic!),
                      const SizedBox(height: 40),
                      const SectionTitle('Practice & Memorize', emoji: '🎯'),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              context,
                              title: 'Exercises',
                              icon: Icons.edit_note_rounded,
                              color: AppTheme.secondary,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ExercisesPage(initialTopic: widget.topic)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              context,
                              title: 'Flashcards',
                              icon: Icons.style_rounded,
                              color: AppTheme.success,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => FlashcardsPage(initialTopic: widget.topic)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 100),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? emoji;

  const SectionTitle(this.title, {this.emoji, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: emoji != null
          ? Row(
              children: [
                Text('$emoji ', style: const TextStyle(fontSize: 24)),
                Expanded(
                    child: TranslatedText(title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ))),
              ],
            )
          : TranslatedText(title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  )),
    );
  }
}

class ExampleBox extends StatelessWidget {
  final String french;
  final String english;
  final Color? color;

  const ExampleBox({
    super.key,
    required this.french,
    required this.english,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            french,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('→ ',
                  style: TextStyle(color: AppTheme.primary.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
              Expanded(
                child: TranslatedText(
                  english,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TipBox extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const TipBox({
    super.key,
    required this.title,
    required this.content,
    this.icon = Icons.lightbulb_outline,
    this.color = const Color(0xFFF59E0B),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 12),
                TranslatedText(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A styled tip box where the [title] is translated into the user's language,
/// but [frenchText] is always rendered in plain [Text] — French never translated.
class FrenchTipBox extends StatelessWidget {
  final String title;
  final String frenchText;
  final IconData icon;
  final Color color;

  const FrenchTipBox({
    super.key,
    required this.title,
    required this.frenchText,
    this.icon = Icons.lightbulb_outline,
    this.color = const Color(0xFFF59E0B),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 12),
                // Handle mixed content: "French -> English" should have English translated
                ...frenchText.split('\n').map((line) {
                  if (line.contains('→')) {
                    final parts = line.split('→');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(parts[0].trim(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                          const Text(' → ', style: TextStyle(color: AppTheme.textSecondary)),
                          Expanded(child: TranslatedText(parts[1].trim(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15))),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;

  const PremiumTable({
    super.key,
    required this.headers,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.primary.withValues(alpha: 0.1)),
          dataRowMinHeight: 48,
          dataRowMaxHeight: 80,
          columnSpacing: 30,
          columns: headers.map((h) => DataColumn(
            label: TranslatedText(
              h,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          )).toList(),
          rows: rows.map((row) => DataRow(
            cells: row.asMap().entries.map((entry) {
              final idx = entry.key;
              final cell = entry.value;
              // If it's the first column, assume it's French and don't auto-translate
              // If it's the second column onwards, it's likely a meaning/translation
              if (idx == 0) {
                return DataCell(
                  Text(
                    cell,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                );
              }
              return DataCell(
                TranslatedText(
                  cell,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              );
            }).toList(),
          )).toList(),
        ),
      ),
    );
  }
}
