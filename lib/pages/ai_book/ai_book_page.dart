import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';
import '../../services/language_provider.dart';
import '../../services/lessons_provider.dart';
import '../../services/deepseek_service.dart';
import '../../services/hugging_face_tts_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AIBookPage extends StatefulWidget {
  const AIBookPage({super.key});

  @override
  State<AIBookPage> createState() => _AIBookPageState();
}

class _AIBookPageState extends State<AIBookPage> {
  final List<String> _selectedGrammar = [];
  final List<String> _selectedLessons = [];
  bool _isGenerating = false;
  Map<String, dynamic>? _story;

  // Audio State
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  bool _isLoadingAudio = false;
  int _currentPageIndex = 0;
  String _ttsEngine = ''; // 'neural' or 'system'
  
  // Scroll Controllers for Desktop
  final ScrollController _selectionScrollController = ScrollController();
  final ScrollController _viewerScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initAudio();
    _initFlutterTts();
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
    await _flutterTts.setSpeechRate(0.85);  // Natural B1 pace
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.05);       // Slightly natural pitch
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    _selectionScrollController.dispose();
    _viewerScrollController.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    // Stop if already playing
    if (_isPlaying) {
      await _audioPlayer.stop();
      await _flutterTts.stop();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() {
      _isLoadingAudio = true;
      _ttsEngine = '';
    });

    // Clean text for TTS
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

  Future<void> _generateStory() async {
    if (_selectedGrammar.isEmpty && _selectedLessons.isEmpty) {
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lp.translate('select_topic_error'))),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      final story = await DeepSeekService.generateAIBook(
        _selectedGrammar,
        _selectedLessons,
        lp.currentLanguage.englishName,
      );

      if (!mounted) return;

      setState(() {
        _story = story;
        _isGenerating = false;
        _currentPageIndex = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${lp.translate('error')}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SpinKitWanderingCubes(color: AppTheme.primary, size: 100),
              const SizedBox(height: 40),
              Text(
                Provider.of<LanguageProvider>(context).translate('writing_novel'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                Provider.of<LanguageProvider>(context).translate('building_story'),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_story != null) {
      return _buildStoryViewer();
    }

    return _buildTopicSelection();
  }

  Widget _buildTopicSelection() {
    final lp = Provider.of<LanguageProvider>(context);
    final lessonsProvider = Provider.of<LessonsProvider>(context);
    final grammarItems = lessonsProvider.allGrammar;
    final lessonItems = lessonsProvider.allLessons;

    return Scaffold(
      appBar: AppBar(
        title: Text(lp.translate('ai_novelist')),
      ),
      body: Scrollbar(
        controller: _selectionScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        child: SingleChildScrollView(
          controller: _selectionScrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lp.translate('create_magic_story'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              lp.translate('pick_topics'),
              style: const TextStyle(color: AppTheme.textTertiary, fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            _buildSectionTitle(lp.translate('grammar_to_use'), Icons.history_edu_rounded),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: grammarItems.map((g) {
                final isSelected = _selectedGrammar.contains(g.title);
                return FilterChip(
                  label: Text(g.title),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedGrammar.add(g.title);
                      } else {
                        _selectedGrammar.remove(g.title);
                      }
                    });
                  },
                  selectedColor: AppTheme.primary.withValues(alpha: 0.1),
                  checkmarkColor: AppTheme.primary,
                );
              }).toList(),
            ),

            const SizedBox(height: 40),
            _buildSectionTitle(lp.translate('vocab_focus'), Icons.auto_stories_rounded),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: lessonItems.map((l) {
                final isSelected = _selectedLessons.contains(l.title);
                return FilterChip(
                  label: Text(l.title),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedLessons.add(l.title);
                      } else {
                        _selectedLessons.remove(l.title);
                      }
                    });
                  },
                  selectedColor: AppTheme.secondary.withValues(alpha: 0.1),
                  checkmarkColor: AppTheme.secondary,
                );
              }).toList(),
            ),

            const SizedBox(height: 100),
          ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateStory,
        label: Text(lp.translate('create_my_novel')),
        icon: const Icon(Icons.auto_awesome_rounded),
        backgroundColor: AppTheme.primary,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryViewer() {
    final lp = Provider.of<LanguageProvider>(context);
    final List<dynamic> pages = _story!['pages'];
    final PageController controller = PageController(initialPage: _currentPageIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text(_story!['title'] ?? lp.translate('ai_novelist')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _audioPlayer.stop();
            setState(() {
              _story = null;
              _isPlaying = false;
            });
          },
        ),
        actions: [
          // Engine indicator badge
          if (_ttsEngine.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _ttsEngine == 'neural'
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _ttsEngine == 'neural' ? AppTheme.primary : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Text(
                  _ttsEngine == 'neural' ? lp.translate('neural_voice') : lp.translate('system_voice'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _ttsEngine == 'neural' ? AppTheme.primary : Colors.orange,
                  ),
                ),
              ),
            ),
          if (_isLoadingAudio)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SpinKitPulse(color: AppTheme.primary, size: 24),
            )
          else
            IconButton(
              icon: Icon(_isPlaying ? Icons.stop_circle : Icons.play_circle_filled, color: AppTheme.primary, size: 28),
              onPressed: () => _speak(pages[_currentPageIndex]['text']),
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: PageView.builder(
        controller: controller,
        itemCount: pages.length,
        onPageChanged: (index) {
          _audioPlayer.stop();
          setState(() {
            _currentPageIndex = index;
            _isPlaying = false;
          });
        },
        itemBuilder: (context, index) {
          final page = pages[index];
          final String rawText = page['text'];

          return Scrollbar(
            controller: _viewerScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              controller: _viewerScrollController,
              padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: rawText,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 20, height: 1.8, color: Colors.white, fontFamily: 'Inter'),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                if (page['annotations'] != null) ...[
                  Text(
                    '✨ ${lp.translate('learning_points')}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 16),
                  ...(() {
                    final rawAnnotations = page['annotations'];
                    List<dynamic> annotationList = [];
                    
                    if (rawAnnotations is List) {
                      annotationList = rawAnnotations;
                    } else if (rawAnnotations is Map) {
                      annotationList = [rawAnnotations];
                    } else if (rawAnnotations is String) {
                      annotationList = [rawAnnotations];
                    }

                    return annotationList.map((anno) {
                      // Handle simple String annotation
                      if (anno is String) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            anno,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        );
                      }
                      
                      // Handle Map annotation
                      final annotation = anno as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                annotation['hint']?.toString() ?? 'Note',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    annotation['original']?.toString() ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    annotation['explanation']?.toString() ?? '',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    });
                  }()),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Row(
               children: [
                 const Icon(Icons.auto_stories, color: AppTheme.textTertiary, size: 16),
                 const SizedBox(width: 8),
                 Text(
                    '${lp.translate('page')} ${_currentPageIndex + 1} ${lp.translate('of')} ${pages.length}',
                    style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                  ),
               ],
             ),
            TextButton.icon(
              onPressed: () {
                _audioPlayer.stop();
                setState(() {
                  _story = null;
                  _isPlaying = false;
                  _currentPageIndex = 0;
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(lp.translate('new_story')),
            ),
          ],
        ),
      ),
    );
  }
}
