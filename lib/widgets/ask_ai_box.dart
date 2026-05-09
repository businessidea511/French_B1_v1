import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
  XFile? _selectedImage;
  String? _base64Image;
  String? _mimeType;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
            title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
              if (image != null) _processImage(image);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppTheme.secondary),
            title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
              if (image != null) _processImage(image);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(XFile image) async {
    final bytes = await image.readAsBytes();
    setState(() {
      _selectedImage = image;
      _base64Image = base64Encode(bytes);
      _mimeType = image.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    });
  }

  Future<void> _askQuestion() async {
    if (_controller.text.trim().isEmpty && _selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _response = null;
    });

    final lp = Provider.of<LanguageProvider>(context, listen: false);
    final targetLang = lp.currentLanguage.englishName; // Use the English name like 'Arabic' or 'Ukrainian'

    try {
      String answer;
      if (_base64Image != null) {
        answer = await DeepSeekService.askQuestionWithImage(
          _controller.text.trim(),
          _base64Image!,
          _mimeType!,
          targetLang,
        );
      } else {
        answer = await DeepSeekService.askGrammarQuestion(
          _controller.text.trim(),
          widget.topic,
          targetLang,
        );
      }

      setState(() {
        _response = answer;
        _isLoading = false;
        _selectedImage = null; // Clear image after success
        _base64Image = null;
        _controller.clear();
      });
      
      // Auto-scroll to show the response
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          final primaryController = PrimaryScrollController.maybeOf(context);
          if (primaryController != null && primaryController.hasClients) {
            primaryController.animateTo(
              primaryController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
            );
          }
        }
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
                              fontSize: 16,
                              height: 1.7,
                              color: Color(0xFFE2E8F0), // Slate 200 - Very readable
                              fontFamily: 'Inter',
                            ),
                            strong: const TextStyle(
                              color: AppTheme.secondary, // Pink for emphasis
                              fontWeight: FontWeight.bold,
                            ),
                            em: const TextStyle(
                              color: AppTheme.accent,
                              fontStyle: FontStyle.italic,
                            ),
                            h1: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                            h2: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                            h3: const TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                            listBullet: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            code: TextStyle(
                              backgroundColor: Colors.black.withOpacity(0.3),
                              color: AppTheme.success, // Green for code/correct forms
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            blockquote: const TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: const Border(
                                left: BorderSide(color: AppTheme.primary, width: 4),
                              ),
                            ),
                            blockquotePadding: const EdgeInsets.all(16),
                            tableHead: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            tableBody: const TextStyle(color: Colors.white, fontSize: 14),
                            tableBorder: TableBorder.all(color: Colors.white.withOpacity(0.1)),
                            tableCellsPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Image Preview
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Stack(
                      children: [
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: AppTheme.primary, width: 2),
                            image: DecorationImage(
                              image: kIsWeb 
                                ? NetworkImage(_selectedImage!.path) as ImageProvider
                                : FileImage(File(_selectedImage!.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedImage = null;
                              _base64Image = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _selectedImage != null ? Icons.add_a_photo : Icons.camera_alt_outlined,
                        color: _selectedImage != null ? AppTheme.success : AppTheme.textSecondary,
                      ),
                      onPressed: _isLoading ? null : _pickImage,
                    ),
                    const SizedBox(width: 8),
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
