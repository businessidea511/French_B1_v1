import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/tts_service.dart';

class EssayDetailPage extends StatefulWidget {
  final String title;
  final String content;
  final String arabicContent;
  final String description;

  const EssayDetailPage({
    super.key,
    required this.title,
    required this.content,
    required this.arabicContent,
    required this.description,
  });

  @override
  State<EssayDetailPage> createState() => _EssayDetailPageState();
}

class _EssayDetailPageState extends State<EssayDetailPage> {
  final TtsService _ttsService = TtsService();
  bool _isPlaying = false;
  bool _showTranslation = false;

  @override
  void initState() {
    super.initState();
    _ttsService.flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _toggleAudio() async {
    if (_isPlaying) {
      await _ttsService.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });
      // Ensure language and rate are set correctly for reading
      await _ttsService.flutterTts.setLanguage("fr-FR");
      await _ttsService.setRate(0.8);
      await _ttsService.speak(widget.content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _showTranslation ? Icons.translate : Icons.translate_outlined,
              color: _showTranslation ? AppTheme.warning : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showTranslation = !_showTranslation;
              });
            },
            tooltip: 'Afficher la traduction',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleAudio,
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded),
        label: Text(_isPlaying ? 'Arrêter' : 'Écouter'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.content,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.8,
                      color: Color(
                          0xFF0F172A), // Dark blue for contrast on white card
                      fontFamily: 'Georgia',
                    ),
                  ),
                  if (_showTranslation) ...[
                    const Divider(height: 32, thickness: 1),
                    Text(
                      widget.arabicContent,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.8,
                        color: Color(0xFF334155),
                        fontFamily: 'Arial', // Better for Arabic
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Écoutez le texte et utilisez le bouton de traduction pour vérifier votre compréhension.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
