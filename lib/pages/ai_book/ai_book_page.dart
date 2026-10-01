import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';
import '../../services/language_provider.dart';
import '../../services/lessons_provider.dart';
import '../../services/hugging_face_tts_service.dart';
import '../../services/global_scroll_manager.dart';
import '../../services/story_service.dart';
import '../../widgets/exercise_block.dart';

/// Serialized AI stories: each chapter opens with a hook, ends on a
/// cliffhanger, and "Lire la suite" writes the next one. Saved on the device.
class AIBookPage extends StatefulWidget {
  const AIBookPage({super.key});

  @override
  State<AIBookPage> createState() => _AIBookPageState();
}

class _AIBookPageState extends State<AIBookPage> {
  // Library and current story
  List<StorySeries> _library = [];
  StorySeries? _series;
  int _chapterIndex = 0;
  int _pageIndex = 0;
  bool _showTranslation = false;

  // Writing state
  bool _busy = false;
  String _busyMessage = '';

  // New story form
  String _genre = 'mystery';
  final TextEditingController _themeController = TextEditingController();
  final TextEditingController _ideaController = TextEditingController();
  final List<String> _selectedGrammar = [];
  final List<String> _selectedLessons = [];

  final PageController _pageController = PageController();
  final ScrollController _homeScroll = ScrollController();

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    GlobalScrollManager.register(_homeScroll);
    _loadLibrary();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
    _flutterTts.setLanguage('fr-FR');
    _flutterTts.setSpeechRate(0.85);
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    GlobalScrollManager.unregister(_homeScroll);
    _homeScroll.dispose();
    _pageController.dispose();
    _themeController.dispose();
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    final all = await StoryService.loadAll();
    if (mounted) setState(() => _library = all);
  }

  // ── Audio ──────────────────────────────────────────────────────────────────

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    await _flutterTts.stop();
    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _speak(String text) async {
    if (_isPlaying) return _stopAudio();
    final clean = text.replaceAll('*', '').replaceAll('#', '').replaceAll('_', '');
    setState(() => _isLoadingAudio = true);
    try {
      final audio = await HuggingFaceTtsService.synthesizeAndSave(clean).timeout(const Duration(seconds: 25));
      if (audio != null && mounted) {
        setState(() => _isLoadingAudio = false);
        await _audioPlayer.play(kIsWeb ? UrlSource(audio) : DeviceFileSource(audio));
        return;
      }
    } catch (e) {
      debugPrint('Neural voice failed, using system voice: $e');
    }
    if (!mounted) return;
    setState(() {
      _isLoadingAudio = false;
      _isPlaying = true;
    });
    await _flutterTts.speak(clean);
  }

  // ── Writing ────────────────────────────────────────────────────────────────

  Future<void> _startNewStory() async {
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    setState(() {
      _busy = true;
      _busyMessage = 'Writing chapter 1…';
    });
    try {
      final series = await StoryService.start(
        genre: _genre,
        theme: _themeController.text,
        grammar: List.of(_selectedGrammar),
        lessons: List.of(_selectedLessons),
        language: lp.currentLanguage.englishName,
      );
      _themeController.clear();
      await _loadLibrary();
      _open(series, chapterIndex: 0);
    } catch (e) {
      _showError('Could not write the story: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueStory() async {
    final series = _series!;
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    await _stopAudio();
    setState(() {
      _busy = true;
      _busyMessage = 'Writing chapter ${series.chapters.length + 1}…';
    });
    try {
      final updated = await StoryService.continueSeries(
        series,
        readerIdea: _ideaController.text,
        language: lp.currentLanguage.englishName,
      );
      _ideaController.clear();
      await _loadLibrary();
      _open(updated, chapterIndex: updated.chapters.length - 1);
    } catch (e) {
      _showError('Could not write the next chapter: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(StorySeries series, {required int chapterIndex}) {
    if (!mounted) return;
    setState(() {
      _series = series;
      _chapterIndex = chapterIndex;
      _pageIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    });
  }

  void _goToChapter(int index) {
    _stopAudio();
    _open(_series!, chapterIndex: index);
  }

  Future<void> _confirmDelete(StorySeries s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Delete "${s.title}"?', style: const TextStyle(color: Colors.white)),
        content: const Text('This story will be removed from this device.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await StoryService.delete(s.id);
    await _loadLibrary();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppTheme.error));
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_busy) return _buildBusy();
    if (_series != null) return _buildReader();
    return _buildHome();
  }

  Widget _buildBusy() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SpinKitWanderingCubes(color: AppTheme.primary, size: 80),
            const SizedBox(height: 32),
            Text(_busyMessage,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Professeur AI is writing… about 30 seconds',
                style: TextStyle(color: AppTheme.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    final lessonsProvider = Provider.of<LessonsProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Stories')),
      body: ListView(
        controller: _homeScroll,
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Stories you can\'t put down',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          const Text('Each chapter ends on a cliffhanger. Read in French, learn your grammar without noticing.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          if (_library.isNotEmpty) ...[
            const SizedBox(height: 28),
            _sectionTitle('📚  Continue reading'),
            for (final s in _library) _buildLibraryCard(s),
          ],
          const SizedBox(height: 28),
          _sectionTitle('✨  New story'),
          const Text('Genre', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in storyGenres.entries)
                ChoiceChip(
                  label: Text('${e.value.$1} ${e.value.$2}'),
                  selected: _genre == e.key,
                  onSelected: (_) => setState(() => _genre = e.key),
                ),
              ActionChip(
                avatar: const Text('🎲'),
                label: const Text('Surprise'),
                onPressed: () => setState(() {
                  final keys = storyGenres.keys.toList();
                  _genre = keys[Random().nextInt(keys.length)];
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _themeController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Theme (optional)',
              hintText: 'e.g. a stolen bike in Liège, a job interview that goes wrong…',
            ),
          ),
          const SizedBox(height: 20),
          const Text('Grammar to practise (optional)', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          _chips(lessonsProvider.allGrammar.map((g) => g.title), _selectedGrammar, AppTheme.primary),
          const SizedBox(height: 20),
          const Text('Vocabulary topics (optional)', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          _chips(lessonsProvider.allLessons.map((l) => l.title), _selectedLessons, AppTheme.secondary),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _startNewStory,
            icon: const Icon(Icons.auto_stories_rounded),
            label: const Text('Start the story'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: AppTheme.primary),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      );

  Widget _chips(Iterable<String> titles, List<String> selected, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in titles)
          FilterChip(
            label: Text(t),
            selected: selected.contains(t),
            selectedColor: color.withValues(alpha: 0.2),
            checkmarkColor: color,
            onSelected: (v) => setState(() => v ? selected.add(t) : selected.remove(t)),
          ),
      ],
    );
  }

  Widget _buildLibraryCard(StorySeries s) {
    final genre = storyGenres[s.genre];
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(s, chapterIndex: s.chapters.length - 1),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(genre?.$1 ?? '📖', style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('${genre?.$2 ?? ''} · Chapitre ${s.chapters.length}',
                        style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                    if (s.teaser.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text('« ${s.teaser} »',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textTertiary),
                onPressed: () => _confirmDelete(s),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reader ─────────────────────────────────────────────────────────────────

  Widget _buildReader() {
    final series = _series!;
    final chapter = series.chapters[_chapterIndex];
    final pages = (chapter['pages'] as List).cast<Map>();
    final onEndPage = _pageIndex >= pages.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _stopAudio();
            setState(() => _series = null);
            _loadLibrary();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(series.title, style: const TextStyle(fontSize: 17), overflow: TextOverflow.ellipsis),
            Text('Chapitre ${_chapterIndex + 1} · ${chapter['chapter_title'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary), overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Translation',
            icon: Icon(Icons.translate_rounded, color: _showTranslation ? AppTheme.primary : null),
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
          ),
          if (!onEndPage)
            _isLoadingAudio
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SpinKitPulse(color: AppTheme.primary, size: 24),
                  )
                : IconButton(
                    tooltip: 'Listen',
                    icon: Icon(_isPlaying ? Icons.stop_circle : Icons.play_circle_fill, color: AppTheme.primary),
                    onPressed: () => _speak(pages[_pageIndex]['text'].toString()),
                  ),
          if (series.chapters.length > 1)
            PopupMenuButton<int>(
              tooltip: 'Chapters',
              icon: const Icon(Icons.list_rounded),
              onSelected: _goToChapter,
              itemBuilder: (_) => [
                for (var i = 0; i < series.chapters.length; i++)
                  PopupMenuItem(
                    value: i,
                    child: Text('${i + 1}. ${series.chapters[i]['chapter_title'] ?? ''}'),
                  ),
              ],
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: pages.length + 1,
        onPageChanged: (i) {
          _stopAudio();
          setState(() => _pageIndex = i);
        },
        itemBuilder: (context, i) => i < pages.length
            ? _StoryPageView(
                key: ValueKey('${series.id}-$_chapterIndex-$i'),
                page: Map<String, dynamic>.from(pages[i]),
                showTranslation: _showTranslation,
              )
            : _buildChapterEnd(chapter),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _pageIndex == 0
                    ? null
                    : () => _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
              ),
              Expanded(
                child: Text(
                  onEndPage ? 'Fin du chapitre' : 'Page ${_pageIndex + 1} / ${pages.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textTertiary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: onEndPage
                    ? null
                    : () => _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterEnd(Map<String, dynamic> chapter) {
    final series = _series!;
    final isLatest = _chapterIndex == series.chapters.length - 1;
    final quiz = ExerciseBlock.fromJson({
      'title': 'As-tu bien compris ?',
      'instruction': '',
      'items': chapter['questions'] ?? const [],
    });

    return _EndPageScroll(
      children: [
        const SizedBox(height: 8),
        const Center(child: Text('À suivre…', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))),
        const SizedBox(height: 4),
        Center(
          child: Text('Fin du chapitre ${_chapterIndex + 1}', style: const TextStyle(color: AppTheme.textTertiary)),
        ),
        if (quiz != null) quiz,
        const SizedBox(height: 12),
        if (isLatest) ...[
          TextField(
            controller: _ideaController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Your idea for what happens next (optional)',
              hintText: 'e.g. the neighbour is lying…',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _continueStory,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text('Lire la suite → Chapitre ${series.chapters.length + 1}'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: AppTheme.primary),
          ),
        ] else
          ElevatedButton.icon(
            onPressed: () => _goToChapter(_chapterIndex + 1),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text('Chapitre ${_chapterIndex + 2}'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
        const SizedBox(height: 40),
      ],
    );
  }
}

/// One page of a chapter, with its own scroll controller (a PageView keeps
/// neighbouring pages alive, so they cannot share one controller).
class _StoryPageView extends StatefulWidget {
  final Map<String, dynamic> page;
  final bool showTranslation;

  const _StoryPageView({super.key, required this.page, required this.showTranslation});

  @override
  State<_StoryPageView> createState() => _StoryPageViewState();
}

class _StoryPageViewState extends State<_StoryPageView> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    GlobalScrollManager.register(_scroll);
  }

  @override
  void dispose() {
    GlobalScrollManager.unregister(_scroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translation = (widget.page['translation'] ?? '').toString();
    final annotations = (widget.page['annotations'] as List? ?? const []).whereType<Map>().toList();

    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: MarkdownBody(
                data: widget.page['text'].toString(),
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 20, height: 1.75, color: Colors.white),
                  strong: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          if (widget.showTranslation && translation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(translation, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16, height: 1.6)),
            ),
          ],
          if (annotations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text('✨ Learning points (${annotations.length})',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                children: [
                  for (final a in annotations)
                    ListTile(
                      dense: true,
                      title: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(a['original']?.toString() ?? '',
                            style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      subtitle: Text('${a['hint'] ?? ''} — ${a['explanation'] ?? ''}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Scrollable end-of-chapter page with its own registered controller.
class _EndPageScroll extends StatefulWidget {
  final List<Widget> children;
  const _EndPageScroll({required this.children});

  @override
  State<_EndPageScroll> createState() => _EndPageScrollState();
}

class _EndPageScrollState extends State<_EndPageScroll> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    GlobalScrollManager.register(_scroll);
  }

  @override
  void dispose() {
    GlobalScrollManager.unregister(_scroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widget.children),
    );
  }
}
