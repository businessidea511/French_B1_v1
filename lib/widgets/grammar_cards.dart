import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import 'gender_text.dart';
import 'translated_text.dart';
import '../services/ui_strings.dart';

/// Small speaker button that reads French text aloud.
class SpeakButton extends StatelessWidget {
  final String french;
  final Color? color;

  const SpeakButton(this.french, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tr(context, 'Listen'),
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.volume_up_rounded, color: color ?? AppTheme.primary, size: 22),
      onPressed: () => TtsService.instance.speak(french),
    );
  }
}

/// Everyday expression used in Belgium and/or France (`"type": "expression"`).
class ExpressionCard extends StatelessWidget {
  final String expression;
  final String meaning;
  final String example;
  final String region; // belgium | france | both
  final String register; // familier | courant

  const ExpressionCard({
    super.key,
    required this.expression,
    required this.meaning,
    this.example = '',
    this.region = 'both',
    this.register = 'courant',
  });

  static ExpressionCard? fromJson(Map w) {
    final expression = (w['expression'] ?? '').toString().trim();
    if (expression.isEmpty) return null;
    return ExpressionCard(
      expression: expression,
      meaning: (w['meaning'] ?? '').toString(),
      example: (w['example'] ?? '').toString(),
      region: (w['region'] ?? 'both').toString(),
      register: (w['register'] ?? 'courant').toString(),
    );
  }

  String get _flags => switch (region) {
        'belgium' => '🇧🇪',
        'france' => '🇫🇷',
        _ => '🇧🇪 🇫🇷',
      };

  String get _where => switch (region) {
        'belgium' => 'En Belgique',
        'france' => 'En France',
        _ => 'En Belgique et en France',
      };

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.sun; // Belgian yellow
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_flags  $_where · ${tr(context, register == 'familier' ? 'informal (street language)' : 'standard')}',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Expanded(
                  child: Text('« $expression »',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ),
              ],
            ),
          ),
          if (meaning.isNotEmpty)
            TranslatedText(meaning, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
          if (example.isNotEmpty) ...[
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: GenderText('💬 $example',
                  style: TextStyle(color: AppTheme.textPrimary, fontStyle: FontStyle.italic, height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }
}

/// A common learner mistake with its correction (`"type": "mistake"`).
class MistakeCard extends StatelessWidget {
  final String wrong;
  final String right;
  final String why;

  const MistakeCard({super.key, required this.wrong, required this.right, this.why = ''});

  static MistakeCard? fromJson(Map w) {
    final wrong = (w['wrong'] ?? '').toString().trim();
    final right = (w['right'] ?? '').toString().trim();
    if (wrong.isEmpty || right.isEmpty) return null;
    return MistakeCard(wrong: wrong, right: right, why: (w['why'] ?? '').toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.fg.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('❌  $wrong',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppTheme.error,
                    )),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text('✅  $right',
                          style: TextStyle(color: AppTheme.success, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (why.isNotEmpty) ...[
            const SizedBox(height: 6),
            TranslatedText(why, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
          ],
        ],
      ),
    );
  }
}
