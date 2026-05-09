import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../services/language_provider.dart';
import '../services/deepseek_service.dart';

class TranslatedMarkdown extends StatefulWidget {
  final String data;
  final MarkdownStyleSheet? styleSheet;

  const TranslatedMarkdown({
    super.key,
    required this.data,
    this.styleSheet,
  });

  @override
  State<TranslatedMarkdown> createState() => _TranslatedMarkdownState();
}

class _TranslatedMarkdownState extends State<TranslatedMarkdown> {
  String? _translatedData;
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

    if (lp.currentLanguage == AppLanguage.english) {
      setState(() {
        _translatedData = widget.data;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final translation = await DeepSeekService.translateText(
          widget.data, lp.currentLanguage.name);
      if (mounted) {
        setState(() {
          _translatedData = translation;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translatedData = widget.data;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return MarkdownBody(
      data: _translatedData ?? widget.data,
      styleSheet: widget.styleSheet,
    );
  }
}
