import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/deepseek_service.dart';
import '../services/language_provider.dart';
import '../theme/app_theme.dart';
import 'translated_text.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:ui';

class AskAIBox extends StatefulWidget {
  final String topic;

  const AskAIBox({super.key, required this.topic});

  @override
  State<AskAIBox> createState() => _AskAIBoxState();
}

class _AskAIBoxState extends State<AskAIBox> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _response;
  final ScrollController _scrollController = ScrollController();

  Future<void> _askQuestion() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = null;
    });

    final lp = Provider.of<LanguageProvider>(context, listen: false);
    final targetLang = lp.currentLanguage.name; // Use the human-readable name like 'Arabic' or 'Ukrainian'

    try {
      final answer = await DeepSeekService.askGrammarQuestion(
        _controller.text.trim(),
        widget.topic,
        targetLang,
      );

      setState(() {
        _response = answer;
        _isLoading = false;
      });
      
      // Auto-scroll to show the response
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      setState(() {
        _response = "Sorry, I couldn't get an answer. Please try again.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final isRTL = lp.isRTL;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.only(top: 40, bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.1),
            AppTheme.accent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            'Ask Professeur AI',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                              color: Colors.white,
                            ),
                          ),
                          TranslatedText(
                            'Need more help with this lesson?',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                if (_response != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb, color: AppTheme.warning, size: 16),
                            SizedBox(width: 8),
                            TranslatedText(
                              'Explanation for Dummies:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warning,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        MarkdownBody(
                          data: _response!,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: AppTheme.textPrimary,
                            ),
                            strong: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            h2: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            code: TextStyle(
                              backgroundColor: Colors.black.withOpacity(0.3),
                              color: AppTheme.accent,
                              fontFamily: 'monospace',
                            ),
                            blockquote: const TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Ask me anything...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.2),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        onSubmitted: (_) => _askQuestion(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isLoading ? null : _askQuestion,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          gradient: _isLoading ? null : AppTheme.primaryGradient,
                          color: _isLoading ? Colors.grey.withOpacity(0.3) : null,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
   );
  }
}
