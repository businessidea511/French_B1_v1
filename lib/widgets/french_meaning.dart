import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_provider.dart';
import '../services/life_story_service.dart';
import '../services/ui_strings.dart';
import '../theme/app_theme.dart';
import 'translated_text.dart';

/// The 🌐 button next to a French sentence.
class TranslateButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;
  final Color? color;
  const TranslateButton({super.key, required this.active, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tr(context, 'Translate'),
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.translate_rounded, size: 20, color: active ? (color ?? AppTheme.primary) : AppTheme.textTertiary),
      onPressed: onPressed,
    );
  }
}

/// The meaning of a French sentence in the learner's language. With
/// [english] (hand-written) it comes from the shared translations; without
/// it the AI translates the French.
class FrenchMeaning extends StatefulWidget {
  final String french;
  final String? english;
  const FrenchMeaning({super.key, required this.french, this.english});

  @override
  State<FrenchMeaning> createState() => _FrenchMeaningState();
}

class _FrenchMeaningState extends State<FrenchMeaning> {
  String? _for; // language + sentence of [_future]
  Future<String>? _future;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textSecondary, fontStyle: FontStyle.italic);
    final english = widget.english;
    if (english != null && english.isNotEmpty) return TranslatedText(english, style: style);
    final current = context.watch<LanguageProvider>().currentLanguage;
    final language = current == AppLanguage.french ? 'English' : current.englishName;
    final key = '$language|${widget.french}';
    if (_for != key) {
      _for = key;
      _future = LifeStoryService.instance.translate(widget.french, language);
    }
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snapshot) => Text(
        snapshot.data ?? (snapshot.hasError ? tr(context, 'Translation failed. Try again.') : '…'),
        style: style,
      ),
    );
  }
}
