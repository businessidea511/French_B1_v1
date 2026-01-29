import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_provider.dart';
import '../services/deepseek_service.dart';

class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String? _translatedText;
  bool _isLoading = false;
  AppLanguage? _lastLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lp = Provider.of<LanguageProvider>(context);
    if (_lastLanguage != lp.currentLanguage) {
      _lastLanguage = lp.currentLanguage;
      _translate();
    }
  }

  Future<void> _translate() async {
    final lp = Provider.of<LanguageProvider>(context, listen: false);

    // If it's English (source) or French (original), don't translate if not needed
    // Actually, usually the source is English in these lessons.
    if (lp.currentLanguage == AppLanguage.english) {
      setState(() {
        _translatedText = widget.text;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final translation = await DeepSeekService.translateText(
          widget.text, lp.currentLanguage.name);
      if (mounted) {
        setState(() {
          _translatedText = translation;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translatedText = widget.text; // Fallback to original
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Text(
      _translatedText ?? widget.text,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
