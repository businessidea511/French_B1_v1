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
                expandedHeight: 140,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: AppTheme.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  expandedTitleScale: 1.2,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${widget.icon} '),
                      Expanded(
                        child: TranslatedText(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 18, 
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: false,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.3),
                          AppTheme.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: 0.1,
                        child: Text(
                          widget.icon,
                          style: const TextStyle(fontSize: 80),
                        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 32, bottom: 8),
          child: emoji != null
              ? Row(
                  children: [
                    Text('$emoji ', style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TranslatedText(title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ))),
                  ],
                )
              : TranslatedText(title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      )),
        ),
        Container(
          height: 4,
          width: 60,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
      ],
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  french,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const Icon(Icons.volume_up_rounded, color: AppTheme.primary, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 8),
          TranslatedText(
            english,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
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
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TranslatedText(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TranslatedText(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
              height: 1.5,
              fontWeight: FontWeight.w500,
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

  List<Widget> _parseLineToWidgets(String line) {
    final List<Widget> widgets = [];
    final trimmed = line.trimRight();

    if (trimmed.isEmpty) {
      return [const SizedBox(height: 2)];
    }

    // 1. Check for '=' separator (e.g. 'me / m\'  =  me')
    if (trimmed.contains('=')) {
      final parts = trimmed.split('=');
      if (parts.length == 2) {
        widgets.add(Text(
          parts[0],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ));
        widgets.add(const Text(
          ' = ',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ));
        widgets.add(TranslatedText(
          parts[1].trim(),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ));
        return widgets;
      }
    }

    // 2. Check for parenthesized translation at the end of the line
    // e.g., 'être   →  été    (been)' or 'Je le vois.  (I see him)'
    if (trimmed.endsWith(')')) {
      final lastOpenBracket = trimmed.lastIndexOf('(');
      // Ensure bracket is not at index 0 (so there's text before it)
      if (lastOpenBracket > 0) {
        final leftPart = trimmed.substring(0, lastOpenBracket);
        final parenthesized = trimmed.substring(lastOpenBracket);

        if (leftPart.contains('→')) {
          final leftParts = leftPart.split('→');
          for (int i = 0; i < leftParts.length; i++) {
            widgets.add(Text(
              leftParts[i],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ));
            if (i < leftParts.length - 1) {
              widgets.add(const Text(
                ' → ',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ));
            }
          }
        } else {
          widgets.add(Text(
            leftPart,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ));
        }

        widgets.add(TranslatedText(
          parenthesized,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ));
        return widgets;
      }
    }

    // 3. Check for '→' separator
    if (trimmed.contains('→')) {
      final parts = trimmed.split('→');
      if (parts.length == 2) {
        final rightSide = parts[1].toLowerCase();
        final hasEnglishExplanations = rightSide.contains('the') ||
            rightSide.contains('before') ||
            rightSide.contains('after') ||
            rightSide.contains('verb') ||
            rightSide.contains('auxiliary') ||
            rightSide.contains('infinitive') ||
            rightSide.contains('subject') ||
            rightSide.contains('agrees') ||
            rightSide.contains('agreement') ||
            rightSide.contains('participle');

        widgets.add(Text(
          parts[0],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ));
        widgets.add(const Text(
          ' → ',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ));

        if (hasEnglishExplanations) {
          widgets.add(TranslatedText(
            parts[1].trim(),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ));
        } else {
          widgets.add(Text(
            parts[1],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ));
        }
        return widgets;
      }
    }

    // Fallback: render the entire line as plain Text
    widgets.add(Text(
      trimmed,
      softWrap: true,
      overflow: TextOverflow.visible,
      style: const TextStyle(
        fontSize: 14,
        color: AppTheme.textPrimary,
        height: 1.6,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    ));
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: icon + title in a row ─────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TranslatedText(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Body: French text ─────────────────────────────────
          // Wrap in horizontal scroll so conjugation tables don't clip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: frenchText.split('\n').map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: _parseLineToWidgets(line),
                    ),
                  );
                }).toList(),
              ),
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

  bool _shouldTranslateColumn(String header) {
    final h = header.toLowerCase();
    return h.contains('meaning') ||
        h.contains('translation') ||
        h.contains('english') ||
        h.contains('definition') ||
        h.contains('explanation') ||
        h.contains('traduction') ||
        h.contains('signification') ||
        h.contains('sens');
  }

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
              final header = idx < headers.length ? headers[idx] : '';

              if (_shouldTranslateColumn(header)) {
                return DataCell(
                  TranslatedText(
                    cell,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                );
              }
              return DataCell(
                Text(
                  cell,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          )).toList(),
        ),
      ),
    );
  }
}
