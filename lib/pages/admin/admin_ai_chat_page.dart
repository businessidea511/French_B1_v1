import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../theme/app_theme.dart';
import '../../services/language_provider.dart';
import '../../services/deepseek_service.dart';
import '../../services/admin_qa_service.dart';
import '../../services/hugging_face_tts_service.dart';

class AdminAIChatPage extends StatefulWidget {
  const AdminAIChatPage({super.key});

  @override
  State<AdminAIChatPage> createState() => _AdminAIChatPageState();
}

class _AdminAIChatPageState extends State<AdminAIChatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _questionController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingLibrary = true;
  String? _aiResponse;
  String _selectedLang = 'English';

  // Audio State
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  bool _isLoadingAudio = false;
  String _ttsEngine = ''; // 'neural' or 'system'
  String? _currentlyPlayingText; // tracks which text is playing

  List<AdminQA> _savedQAs = [];

  final List<String> _supportedLanguages = [
    'English',
    'French',
    'Arabic',
    'Ukrainian',
    'Italian',
    'Tigrinya',
    'Turkish',
    'Indonesian',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initAudio();
    _initFlutterTts();

    // Set default language to app's current language
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      setState(() => _selectedLang = lp.currentLanguage.englishName);
    });

    _loadSavedQAs();
  }

  void _initAudio() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _initFlutterTts() async {
    await _flutterTts.setLanguage('fr-FR');
    await _flutterTts.setSpeechRate(0.85);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.05);
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // ─── TTS Speak ──────────────────────────────────────────────────────────────

  Future<void> _speak(String text) async {
    // Stop if already playing the same text
    if (_isPlaying && _currentlyPlayingText == text) {
      await _audioPlayer.stop();
      await _flutterTts.stop();
      setState(() {
        _isPlaying = false;
        _currentlyPlayingText = null;
      });
      return;
    }

    // Stop any current playback before starting new one
    if (_isPlaying) {
      await _audioPlayer.stop();
      await _flutterTts.stop();
    }

    setState(() {
      _isLoadingAudio = true;
      _ttsEngine = '';
      _currentlyPlayingText = text;
    });

    // Clean markdown formatting from text
    final cleanText = text
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .replaceAll('_', '');

    try {
      // ── TIER 1: Hugging Face Neural Voice (Premium) ──
      debugPrint('🎙️ Trying Hugging Face Neural voice...');
      final audioPath = await HuggingFaceTtsService.synthesizeAndSave(cleanText)
          .timeout(const Duration(seconds: 20));

      if (audioPath != null && mounted) {
        setState(() {
          _ttsEngine = 'neural';
          _isLoadingAudio = false;
          _isPlaying = true;
        });
        if (kIsWeb) {
          await _audioPlayer.play(UrlSource(audioPath));
        } else {
          await _audioPlayer.play(DeviceFileSource(audioPath));
        }
        return;
      }
    } catch (e) {
      debugPrint('⚠️ HF TTS failed: $e — falling back to system voice...');
    }

    // ── TIER 2: flutter_tts Fallback (Always Available) ──
    if (mounted) {
      setState(() {
        _ttsEngine = 'system';
        _isLoadingAudio = false;
        _isPlaying = true;
      });
      debugPrint('🔄 Using system TTS fallback.');
      await _flutterTts.speak(cleanText);
    }

    if (mounted) setState(() => _isLoadingAudio = false);
  }

  // ─── Supabase operations ────────────────────────────────────────────────────

  Future<void> _loadSavedQAs() async {
    setState(() => _isLoadingLibrary = true);
    try {
      final items = await AdminQAService.fetchAll();
      if (!mounted) return;
      setState(() {
        _savedQAs = items;
        _isLoadingLibrary = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLibrary = false);
      _showSnack('Failed to load saved Q&As: $e', isError: true);
    }
  }

  Future<void> _saveCurrentQA() async {
    final question = _questionController.text.trim();
    final answer = _aiResponse;
    if (question.isEmpty || answer == null) return;

    // Prevent duplicate saves
    final exists = _savedQAs.any(
      (item) => item.question == question && item.answer == answer,
    );
    if (exists) {
      _showSnack('This Q&A is already saved!');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final newItem = await AdminQAService.insert(
        question: question,
        answer: answer,
        language: _selectedLang,
      );
      if (!mounted) return;
      setState(() {
        _savedQAs.insert(0, newItem);
        _isSaving = false;
      });
      _showSnack('Saved to library! 📚', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('Failed to save: $e', isError: true);
    }
  }

  Future<void> _deleteQA(AdminQA item) async {
    try {
      await AdminQAService.delete(item.id);
      if (!mounted) return;
      setState(() => _savedQAs.removeWhere((q) => q.id == item.id));
      _showSnack('Removed from library.');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to delete: $e', isError: true);
    }
  }

  // ─── AI question ────────────────────────────────────────────────────────────

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isLoading = true;
      _aiResponse = null;
    });

    try {
      final response =
          await DeepSeekService.askGeneralFrenchQuestion(question, _selectedLang);
      if (!mounted) return;
      setState(() {
        _aiResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiResponse =
            'Failed to get explanation. Please check your internet connection and retry.';
        _isLoading = false;
      });
    }
  }

  // ─── Copy to clipboard ──────────────────────────────────────────────────────

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showSnack('Copied to clipboard! 📋', isSuccess: true);
  }

  // ─── Helper snackbar ────────────────────────────────────────────────────────

  void _showSnack(String message, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? Colors.green.shade700
            : isError
                ? Colors.red.shade700
                : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Admin AI Assistant 🔒'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.forum_rounded), text: 'AI Chat'),
            Tab(icon: Icon(Icons.bookmark_rounded), text: 'Saved Library'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(),
          _buildSavedTab(),
        ],
      ),
    );
  }

  // ─── Chat Tab ───────────────────────────────────────────────────────────────

  Widget _buildChatTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ask any question about our B1 course, French grammar, or general French. '
                    'Receive explanations in any language. Answers are saved to Supabase.',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Input Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language Dropdown
                Row(
                  children: [
                    const Icon(Icons.g_translate_rounded,
                        color: AppTheme.accent, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Explanation Language:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLang,
                          dropdownColor: AppTheme.surface,
                          items: _supportedLanguages.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() => _selectedLang = newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Question Field
                TextField(
                  controller: _questionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Explain how to use the subjonctif with clear B1 examples...',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 16),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _askQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Ask Professeur AI',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // AI Response Card
          if (_aiResponse != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with label + Copy + Save + Audio buttons
                  Row(
                    children: [
                      const Icon(Icons.lightbulb,
                          color: AppTheme.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI Explanation ($_selectedLang):',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warning,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      // TTS engine badge
                      if (_ttsEngine.isNotEmpty && _currentlyPlayingText == _aiResponse)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _ttsEngine == 'neural'
                                  ? AppTheme.primary.withValues(alpha: 0.15)
                                  : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _ttsEngine == 'neural' ? AppTheme.primary : Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _ttsEngine == 'neural' ? '🧠 Neural' : '🔊 System',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _ttsEngine == 'neural' ? AppTheme.primary : Colors.orange,
                              ),
                            ),
                          ),
                        ),
                      // Audio button
                      if (_isLoadingAudio && _currentlyPlayingText == _aiResponse)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: SpinKitPulse(color: AppTheme.primary, size: 20),
                          ),
                        )
                      else
                        _ActionIconButton(
                          icon: (_isPlaying && _currentlyPlayingText == _aiResponse)
                              ? Icons.stop_circle
                              : Icons.play_circle_filled,
                          label: (_isPlaying && _currentlyPlayingText == _aiResponse)
                              ? 'Stop'
                              : 'Listen',
                          color: AppTheme.secondary,
                          onTap: () => _speak(_aiResponse!),
                        ),
                      const SizedBox(width: 8),
                      // Copy button
                      _ActionIconButton(
                        icon: Icons.copy_rounded,
                        label: 'Copy',
                        color: AppTheme.accent,
                        onTap: () => _copyToClipboard(_aiResponse!),
                      ),
                      const SizedBox(width: 8),
                      // Save button
                      _ActionIconButton(
                        icon: Icons.bookmark_add_outlined,
                        label: _isSaving ? '...' : 'Save',
                        color: AppTheme.primary,
                        onTap: _isSaving ? null : _saveCurrentQA,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMarkdown(_aiResponse!),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  // ─── Saved Library Tab ──────────────────────────────────────────────────────

  Widget _buildSavedTab() {
    if (_isLoadingLibrary) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Loading from Supabase…',
                style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    if (_savedQAs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_border_rounded,
                  size: 60, color: Colors.white24),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Saved Explanations Yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your saved Q&As will appear here.',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _loadSavedQAs,
              icon: const Icon(Icons.refresh, color: AppTheme.primary),
              label: const Text('Refresh',
                  style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadSavedQAs,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _savedQAs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = _savedQAs[index];
          final timestamp =
              '${item.createdAt.toLocal()}'.substring(0, 16);

          return Card(
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: ExpansionTile(
              leading: const Icon(Icons.bookmark, color: AppTheme.primary),
              title: Text(
                item.question,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Language: ${item.language} • Saved: $timestamp',
                style: const TextStyle(
                    color: AppTheme.textTertiary, fontSize: 11),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Listen button
                  if (_isLoadingAudio && _currentlyPlayingText == item.answer)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: SpinKitPulse(color: AppTheme.secondary, size: 20),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        (_isPlaying && _currentlyPlayingText == item.answer)
                            ? Icons.stop_circle
                            : Icons.play_circle_filled,
                        color: AppTheme.secondary,
                        size: 22,
                      ),
                      tooltip: (_isPlaying && _currentlyPlayingText == item.answer)
                          ? 'Stop'
                          : 'Listen in French',
                      onPressed: () => _speak(item.answer),
                    ),
                  // Copy answer button
                  IconButton(
                    icon: const Icon(Icons.copy_rounded,
                        color: AppTheme.accent, size: 20),
                    tooltip: 'Copy answer',
                    onPressed: () => _copyToClipboard(item.answer),
                  ),
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.error),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(item),
                  ),
                ],
              ),
              childrenPadding: const EdgeInsets.all(20),
              expandedAlignment: Alignment.topLeft,
              children: [
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: 16),
                ),
                _buildMarkdown(item.answer, smaller: true),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Confirm delete dialog ──────────────────────────────────────────────────

  void _confirmDelete(AdminQA item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Q&A?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove this saved Q&A from Supabase?',
          style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteQA(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ─── Shared Markdown renderer ────────────────────────────────────────────────

  Widget _buildMarkdown(String data, {bool smaller = false}) {
    final double base = smaller ? 15.0 : 16.0;
    return MarkdownBody(
      data: data,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: base,
          height: 1.7,
          color: const Color(0xFFE2E8F0),
          fontFamily: 'Inter',
        ),
        strong: const TextStyle(
          color: AppTheme.secondary,
          fontWeight: FontWeight.bold,
        ),
        em: const TextStyle(
          color: AppTheme.accent,
          fontStyle: FontStyle.italic,
        ),
        h1: TextStyle(
            color: AppTheme.primary,
            fontSize: base + 8,
            fontWeight: FontWeight.bold),
        h2: TextStyle(
            color: AppTheme.accent,
            fontSize: base + 4,
            fontWeight: FontWeight.bold),
        h3: TextStyle(
            color: AppTheme.secondary,
            fontSize: base + 2,
            fontWeight: FontWeight.bold),
        listBullet: TextStyle(
            color: AppTheme.primary,
            fontSize: base,
            fontWeight: FontWeight.bold),
        code: TextStyle(
          backgroundColor: Colors.black.withValues(alpha: 0.1),
          color: AppTheme.success,
          fontFamily: 'monospace',
          fontSize: base - 2,
          fontWeight: FontWeight.w600,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        blockquote: TextStyle(
          color: AppTheme.textTertiary,
          fontSize: base - 1,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: AppTheme.primary, width: 4),
          ),
        ),
        blockquotePadding: const EdgeInsets.all(16),
      ),
    );
  }
}

// ─── Small reusable action button ───────────────────────────────────────────

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
