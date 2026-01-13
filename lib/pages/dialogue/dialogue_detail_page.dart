import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/tts_service.dart';

class DialogueDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final List<Map<String, String>> dialogueLines;

  const DialogueDetailPage({
    super.key,
    required this.title,
    required this.description,
    required this.dialogueLines,
  });

  @override
  State<DialogueDetailPage> createState() => _DialogueDetailPageState();
}

class _DialogueDetailPageState extends State<DialogueDetailPage> {
  final TtsService _ttsService = TtsService();

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            width: double.infinity,
            child: Text(
              widget.description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.dialogueLines.length,
              itemBuilder: (context, index) {
                final line = widget.dialogueLines[index];
                final isAgent = line['role'] == 'Agent';
                return _buildChatBubble(
                  context,
                  role: line['role']!,
                  text: line['text']!,
                  isAgent: isAgent,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(
    BuildContext context, {
    required String role,
    required String text,
    required bool isAgent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isAgent ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAgent) ...[
            const CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.support_agent, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAgent ? Colors.white : AppTheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isAgent ? Radius.zero : const Radius.circular(16),
                  bottomRight:
                      isAgent ? const Radius.circular(16) : Radius.zero,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        role,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAgent ? AppTheme.primary : Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Audio Icon
                      GestureDetector(
                        onTap: () => _ttsService.speak(text),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 20,
                          color: isAgent
                              ? AppTheme.primary.withOpacity(0.7)
                              : Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      color: isAgent ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isAgent) ...[
            const SizedBox(width: 8),
            // User Text-to-Speech Button (Optional, but let's add it for consistency or leave it for just Agent?)
            // The request was "listen to each sentence", so I will add it for both.
            // But usually for the user side, the icon should be inside or next to the bubble.
            // I'll put it inside like the Agent one.
            const CircleAvatar(
              backgroundColor: AppTheme.secondary,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
