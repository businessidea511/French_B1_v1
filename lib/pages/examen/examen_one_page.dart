import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';
import '../../services/language_provider.dart';
import '../../services/deepseek_service.dart';
import '../../services/hugging_face_tts_service.dart';

class ExamenOnePage extends StatefulWidget {
  const ExamenOnePage({super.key});
  @override
  State<ExamenOnePage> createState() => _ExamenOnePageState();
}

class _ExamenOnePageState extends State<ExamenOnePage> {
  // ─── Phase ───────────────────────────────────────────────────────────────
  String _examPhase = 'intro'; // intro | loading | listening | grammar | reading | writing | submitting | results
  int _listeningSubPhase = 1;  // 1=Ex A (vrai/faux), 2=Ex B (MCQ a/b/c), 3=Ex C (matching)
  int _currentQuestionIndex = 0;

  // ─── Data ─────────────────────────────────────────────────────────────────
  Map<String, dynamic>? _examData;
  Map<String, dynamic>? _essayGrading;

  // ─── Answers ──────────────────────────────────────────────────────────────
  final Map<int, String> _ex1Answers = {}; // 'vrai' | 'faux' | 'on ne sait pas'
  final Map<int, int>    _ex2Answers = {}; // option index 0/1/2
  final Map<int, int>    _ex3Answers = {}; // dialogue idx → situation idx
  final Map<int, int> _grammarAnswers = {};
  final Map<int, int> _readingAnswers  = {};
  final TextEditingController _essayController = TextEditingController();

  // ─── Audio ────────────────────────────────────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts  _flutterTts  = FlutterTts();
  bool _isPlaying      = false;
  bool _isLoadingAudio = false;
  String _ttsEngine    = '';
  int _playingDialIdx  = -1; // -1 = main audio, 0-3 = dialogue index

  // ═════════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _isPlaying = false; _playingDialIdx = -1; });
    });
    _flutterTts.setLanguage('fr-FR');
    _flutterTts.setSpeechRate(0.85);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.05);
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() { _isPlaying = false; _playingDialIdx = -1; });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    _essayController.dispose();
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Audio helpers
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      await _flutterTts.stop();
    } catch (_) {}
    if (mounted) setState(() { _isPlaying = false; _playingDialIdx = -1; _isLoadingAudio = false; });
  }

  Future<void> _speak(String text, {int dialIdx = -1}) async {
    // Tap same source → stop
    if (_isPlaying && _playingDialIdx == dialIdx) { await _stopAudio(); return; }
    if (_isPlaying) await _stopAudio();

    setState(() { _isLoadingAudio = true; _ttsEngine = ''; _playingDialIdx = dialIdx; });

    final clean = text
        .replaceAll('**', '').replaceAll('*', '')
        .replaceAll('###', '').replaceAll('##', '').replaceAll('#', '');

    try {
      final path = await HuggingFaceTtsService.synthesizeAndSave(clean)
          .timeout(const Duration(seconds: 20));
      if (path != null && mounted) {
        setState(() { _ttsEngine = 'neural'; _isLoadingAudio = false; _isPlaying = true; });
        await _audioPlayer.play(DeviceFileSource(path));
        return;
      }
    } catch (e) {
      debugPrint('HF TTS failed: $e');
    }
    if (mounted) {
      setState(() { _ttsEngine = 'system'; _isLoadingAudio = false; _isPlaying = true; });
      await _flutterTts.speak(clean);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Exam logic
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _fetchExam() async {
    setState(() => _examPhase = 'loading');
    try {
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      final exam = await DeepSeekService.generateExam(lp.currentLanguage.englishName);
      setState(() {
        _examData = exam;
        _examPhase = 'listening';
        _listeningSubPhase = 1;
        _currentQuestionIndex = 0;
        _ex1Answers.clear(); _ex2Answers.clear(); _ex3Answers.clear();
        _grammarAnswers.clear(); _readingAnswers.clear();
        _essayController.clear(); _essayGrading = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
        setState(() => _examPhase = 'intro');
      }
    }
  }

  Future<void> _submitExam() async {
    final wc = _essayController.text.trim()
        .split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wc < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre rédaction est trop courte (min. 20 mots).')));
      return;
    }
    setState(() => _examPhase = 'submitting');
    try {
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      final title = _examData?['writing']?['topic_title'] ?? 'Essay';
      final grading = await DeepSeekService.gradeEssay(
          title, _essayController.text, lp.currentLanguage.englishName);
      setState(() { _essayGrading = grading; _examPhase = 'results'; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
        setState(() => _examPhase = 'writing');
      }
    }
  }

  void _navStop() {
    _audioPlayer.stop(); _flutterTts.stop();
    setState(() { _isPlaying = false; _playingDialIdx = -1; _isLoadingAudio = false; });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Build
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final showStepper = {'listening', 'grammar', 'reading', 'writing'}.contains(_examPhase);
    Widget body;
    switch (_examPhase) {
      case 'loading':    body = _loadingState('Préparation de votre examen...', 'Professeur AI construit un examen B1 personnalisé...'); break;
      case 'submitting': body = _loadingState('Correction en cours...', 'Professeur AI évalue votre rédaction...', secondary: true); break;
      case 'listening':  body = _buildListeningSection(); break;
      case 'grammar':    body = _buildGrammarSection(); break;
      case 'reading':    body = _buildReadingSection(); break;
      case 'writing':    body = _buildWritingSection(); break;
      case 'results':    body = _buildResultsDashboard(); break;
      default:           body = _buildIntroSection(); break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_examPhase == 'results' ? 'Résultats de l\'évaluation' : 'Examen FLE — Niveau B1',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_examPhase == 'intro' || _examPhase == 'loading' || _examPhase == 'submitting') {
              _navStop(); Navigator.pop(context);
            } else {
              showDialog(context: context, builder: (_) => AlertDialog(
                title: const Text('Quitter l\'examen ?'),
                content: const Text('Votre progression sera perdue.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  TextButton(
                    onPressed: () { Navigator.pop(context); _navStop(); setState(() => _examPhase = 'intro'); },
                    child: const Text('Quitter', style: TextStyle(color: AppTheme.error)),
                  ),
                ],
              ));
            }
          },
        ),
      ),
      body: Column(children: [
        if (showStepper) _buildStepHeader(),
        Expanded(child: body),
      ]),
    );
  }

  // ─── Step header ──────────────────────────────────────────────────────────
  Widget _buildStepHeader() {
    final steps = ['A. Écoute', 'Grammaire', 'Lecture', 'Écriture'];
    final phaseIdx = {'listening': 0, 'grammar': 1, 'reading': 2, 'writing': 3}[_examPhase] ?? 0;

    return Container(
      color: AppTheme.surface.withValues(alpha: 0.6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(4, (i) {
          final active    = i == phaseIdx;
          final completed = i  < phaseIdx;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: active ? AppTheme.primary : (completed ? AppTheme.success : AppTheme.surfaceLight),
                shape: BoxShape.circle,
              ),
              child: Center(child: completed
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : Text('${i + 1}', style: TextStyle(color: active ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
            const SizedBox(height: 4),
            Text(
              (active && _examPhase == 'listening') ? 'Écoute ($_listeningSubPhase/3)' : steps[i],
              style: TextStyle(fontSize: 10.5, color: active ? AppTheme.primary : (completed ? AppTheme.success : AppTheme.textTertiary),
                fontWeight: active ? FontWeight.bold : FontWeight.normal),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _loadingState(String title, String subtitle, {bool secondary = false}) =>
    Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      secondary
          ? const SpinKitDoubleBounce(color: AppTheme.secondary, size: 80)
          : const SpinKitWanderingCubes(color: AppTheme.primary, size: 80),
      const SizedBox(height: 32),
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 8),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.6)), textAlign: TextAlign.center)),
    ]));

  // ═════════════════════════════════════════════════════════════════════════
  // LISTENING — dispatch sub-phases
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildListeningSection() {
    switch (_listeningSubPhase) {
      case 1:  return _buildListeningExA();
      case 2:  return _buildListeningExB();
      case 3:  return _buildListeningExC();
      default: return _buildListeningExA();
    }
  }

  // ─── EXERCISE A — Vrai / Faux / On ne sait pas ────────────────────────────
  Widget _buildListeningExA() {
    final ex1        = _examData!['listening']['exercise1'] as Map<String, dynamic>;
    final audioText  = ex1['audio_script'] as String;
    final statements = ex1['statements'] as List;
    final allDone    = _ex1Answers.length == statements.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _exHeader('A. Exercice 1', 'Écoutez et répondez par "vrai", "faux" ou "on ne sait pas".',
            Icons.record_voice_over_rounded, AppTheme.primary),
        const SizedBox(height: 16),
        _audioCard(audioText, dialIdx: -1),
        const SizedBox(height: 22),

        // Table
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  color: AppTheme.surfaceLight,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Row(children: [
                    const Expanded(child: Text('Affirmation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary))),
                    _thCell('Vrai',     AppTheme.success),
                    _thCell('Faux',     AppTheme.error),
                    _thCell('On ne\nsait pas', AppTheme.warning),
                  ]),
                ),
                ...List.generate(statements.length, (i) =>
                    _vraiFauxRow(i, statements[i]['statement'] as String, statements[i]['answer'] as String)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _navButtons(
          onBack: null,
          onNext: allDone ? () => setState(() => _listeningSubPhase = 2) : null,
          nextLabel: 'Exercice B →',
        ),
      ]),
    );
  }

  Widget _thCell(String t, Color c) => SizedBox(
    width: 72,
    child: Text(t, textAlign: TextAlign.center,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: c)),
  );

  Widget _vraiFauxRow(int idx, String statement, String correctAnswer) {
    final selected = _ex1Answers[idx];
    final opts   = ['vrai', 'faux', 'on ne sait pas'];
    final colors = [AppTheme.success, AppTheme.error, AppTheme.warning];

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          child: Text('${idx + 1}. $statement',
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4)),
        ),
        ...List.generate(3, (i) {
          final isSel = selected == opts[i];
          return GestureDetector(
            onTap: () => setState(() => _ex1Answers[idx] = opts[i]),
            child: SizedBox(width: 72,
              child: Center(
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSel ? colors[i].withValues(alpha: 0.25) : Colors.transparent,
                    border: Border.all(color: isSel ? colors[i] : Colors.white.withValues(alpha: 0.25), width: 2),
                  ),
                  child: isSel ? Icon(Icons.check, size: 14, color: colors[i]) : null,
                ),
              ),
            ),
          );
        }),
      ]),
    );
  }

  // ─── EXERCISE B — Multiple choice a/b/c ────────────────────────────────────
  Widget _buildListeningExB() {
    final ex1      = _examData!['listening']['exercise1'] as Map<String, dynamic>;
    final audioTxt = ex1['audio_script'] as String;
    final ex2Qs    = _examData!['listening']['exercise2']['questions'] as List;
    final allDone  = _ex2Answers.length == ex2Qs.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _exHeader('B. Exercice 2', 'Écoutez et entourez la bonne réponse.',
            Icons.checklist_rounded, AppTheme.accent),
        const SizedBox(height: 12),
        // Replay info + button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: Row(children: [
            const Icon(Icons.replay, color: AppTheme.textTertiary, size: 18),
            const SizedBox(width: 10),
            const Expanded(child: Text('Même enregistrement que l\'Exercice A — vous pouvez le réécouter.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
            const SizedBox(width: 10),
            _playBtn(audioTxt, dialIdx: -1, compact: true),
          ]),
        ),
        const SizedBox(height: 20),
        ...List.generate(ex2Qs.length, (i) {
          final q    = ex2Qs[i];
          final opts = List<String>.from(q['options']);
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${i + 1}) ${q['question']}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 14),
                ...List.generate(opts.length, (j) {
                  final sel = _ex2Answers[i] == j;
                  return _optBtn(opts[j], sel, () => setState(() => _ex2Answers[i] = j),
                      bottom: j < opts.length - 1);
                }),
              ]),
            ),
          );
        }),
        _navButtons(
          onBack: () { _navStop(); setState(() => _listeningSubPhase = 1); },
          onNext: allDone ? () { _navStop(); setState(() => _listeningSubPhase = 3); } : null,
          nextLabel: 'Exercice C →',
        ),
      ]),
    );
  }

  // ─── EXERCISE C — Dialogue matching grid ─────────────────────────────────
  Widget _buildListeningExC() {
    final ex3      = _examData!['listening']['exercise3'] as Map<String, dynamic>;
    final dialogues  = ex3['dialogues'] as List;
    final situations = List<String>.from(ex3['situations']);
    final allDone  = _ex3Answers.length == dialogues.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _exHeader(
          'C. Exercice 3',
          'Vous écoutez ${dialogues.length} dialogues. Associez chaque dialogue à la situation correspondante.\n⚠️ Il y a ${situations.length} situations mais seulement ${dialogues.length} dialogues.',
          Icons.compare_arrows_rounded,
          AppTheme.secondary,
        ),
        const SizedBox(height: 20),

        // Dialogue cards (play buttons)
        ...List.generate(dialogues.length, (i) {
          final script = dialogues[i]['script'] as String;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
                  child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text('Dialogue ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                _playBtn(script, dialIdx: i),
              ]),
            ),
          );
        }),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Associez chaque dialogue à une situation :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _matchingGrid(dialogues, situations),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        _navButtons(
          onBack: () { _navStop(); setState(() => _listeningSubPhase = 2); },
          onNext: allDone ? () { _navStop(); setState(() { _examPhase = 'grammar'; _currentQuestionIndex = 0; }); } : null,
          nextLabel: 'Grammaire →',
        ),
      ]),
    );
  }

  Widget _matchingGrid(List dialogues, List<String> situations) {
    const labelW  = 90.0;
    const cellW   = 88.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header row
      Row(children: [
        SizedBox(width: labelW),
        ...situations.map((s) => SizedBox(width: cellW,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(s, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          ))),
      ]),
      const SizedBox(height: 8),
      // Data rows
      ...List.generate(dialogues.length, (dIdx) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            SizedBox(width: labelW,
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: Text('Dialogue ${dIdx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), textAlign: TextAlign.center))),
            ...List.generate(situations.length, (sIdx) {
              final isSel = _ex3Answers[dIdx] == sIdx;
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSel) { _ex3Answers.remove(dIdx); } else { _ex3Answers[dIdx] = sIdx; }
                }),
                child: SizedBox(width: cellW,
                  child: Center(child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSel ? AppTheme.secondary.withValues(alpha: 0.25) : Colors.transparent,
                      border: Border.all(color: isSel ? AppTheme.secondary : Colors.white.withValues(alpha: 0.25), width: 2),
                    ),
                    child: isSel ? const Icon(Icons.check, size: 14, color: AppTheme.secondary) : null,
                  ))),
              );
            }),
          ]),
        );
      }),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // GRAMMAR SECTION
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildGrammarSection() {
    final list = _examData!['grammar'] as List;
    final q    = list[_currentQuestionIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _questionCard(
          label: 'Grammaire',
          current: _currentQuestionIndex, total: list.length,
          question: q['question'] as String,
          options: List<String>.from(q['options']),
          selected: _grammarAnswers[_currentQuestionIndex],
          onSelect: (i) => setState(() => _grammarAnswers[_currentQuestionIndex] = i),
        ),
        const SizedBox(height: 24),
        _navButtons(
          onBack: () {
            if (_currentQuestionIndex > 0) {
              setState(() => _currentQuestionIndex--);
            } else {
              setState(() { _examPhase = 'listening'; _listeningSubPhase = 3; });
            }
          },
          onNext: _grammarAnswers[_currentQuestionIndex] != null ? () {
            if (_currentQuestionIndex < list.length - 1) {
              setState(() => _currentQuestionIndex++);
            } else {
              setState(() { _examPhase = 'reading'; _currentQuestionIndex = 0; });
            }
          } : null,
        ),
      ]),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // READING SECTION
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildReadingSection() {
    final data = _examData!['reading'] as Map<String, dynamic>;
    final qs   = data['questions'] as List;
    final q    = qs[_currentQuestionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Card(
          child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Texte de Compréhension Écrite',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accent)),
            const SizedBox(height: 12),
            Text(data['text'] as String,
                style: const TextStyle(fontSize: 15, height: 1.65, color: AppTheme.textPrimary)),
          ])),
        ),
        const SizedBox(height: 20),
        _questionCard(
          label: 'Compréhension Écrite',
          current: _currentQuestionIndex, total: qs.length,
          question: q['question'] as String,
          options: List<String>.from(q['options']),
          selected: _readingAnswers[_currentQuestionIndex],
          onSelect: (i) => setState(() => _readingAnswers[_currentQuestionIndex] = i),
        ),
        const SizedBox(height: 24),
        _navButtons(
          onBack: () {
            if (_currentQuestionIndex > 0) {
              setState(() => _currentQuestionIndex--);
            } else {
              final grammarLen = (_examData!['grammar'] as List).length;
              setState(() { _examPhase = 'grammar'; _currentQuestionIndex = grammarLen - 1; });
            }
          },
          onNext: _readingAnswers[_currentQuestionIndex] != null ? () {
            if (_currentQuestionIndex < qs.length - 1) {
              setState(() => _currentQuestionIndex++);
            } else {
              setState(() { _examPhase = 'writing'; _currentQuestionIndex = 0; });
            }
          } : null,
        ),
      ]),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // WRITING SECTION
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildWritingSection() {
    final w = _examData!['writing'] as Map<String, dynamic>;
    final readingQLen = (_examData!['reading']['questions'] as List).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.edit_note_rounded, color: AppTheme.secondary, size: 26),
            const SizedBox(width: 8),
            Expanded(child: Text(w['topic_title'] as String,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 10),
          const Text('Sujet :', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(w['prompt'] as String, style: const TextStyle(fontSize: 15, height: 1.5)),
        ]))),
        const SizedBox(height: 20),
        TextField(
          controller: _essayController,
          maxLines: 12, minLines: 8,
          style: const TextStyle(fontSize: 15, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Commencez à écrire ici...',
            hintStyle: const TextStyle(color: AppTheme.textTertiary),
            fillColor: AppTheme.surface, filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.secondary, width: 2)),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _essayController,
          builder: (_, v, __) {
            final wc = v.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
            return Text('Nombre de mots : $wc (Recommandé : 80-150)',
              style: TextStyle(fontSize: 13, color: wc >= 20 ? AppTheme.success : AppTheme.textTertiary,
                fontWeight: wc >= 20 ? FontWeight.bold : FontWeight.normal));
          },
        ),
        const SizedBox(height: 32),
        _navButtons(
          onBack: () => setState(() { _examPhase = 'reading'; _currentQuestionIndex = readingQLen - 1; }),
          onNext: () => _submitExam(),
          nextLabel: 'Soumettre l\'examen',
        ),
      ]),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // RESULTS DASHBOARD
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildResultsDashboard() {
    final listening  = _examData!['listening'] as Map<String, dynamic>;
    final ex1Data    = listening['exercise1'] as Map<String, dynamic>;
    final ex2Data    = listening['exercise2'] as Map<String, dynamic>;
    final ex3Data    = listening['exercise3'] as Map<String, dynamic>;
    final grammarList= _examData!['grammar']  as List;
    final readingList= _examData!['reading']['questions'] as List;

    // Scores
    final statements = ex1Data['statements'] as List;
    final ex2Qs      = ex2Data['questions']  as List;
    final ex3Answers = List<int>.from(ex3Data['answers']);

    int ex1c = 0;
    for (int i = 0; i < statements.length; i++) {
      if (_ex1Answers[i] == statements[i]['answer']) ex1c++;
    }
    int ex2c = 0;
    for (int i = 0; i < ex2Qs.length; i++) {
      if (_ex2Answers[i] == ex2Qs[i]['correct']) ex2c++;
    }
    int ex3c = 0;
    for (int i = 0; i < ex3Answers.length; i++) {
      if (_ex3Answers[i] == ex3Answers[i]) ex3c++;
    }
    int gc = 0;
    for (int i = 0; i < grammarList.length; i++) {
      if (_grammarAnswers[i] == grammarList[i]['correct']) gc++;
    }
    int rc = 0;
    for (int i = 0; i < readingList.length; i++) {
      if (_readingAnswers[i] == readingList[i]['correct']) rc++;
    }

    final listenTotal   = statements.length + ex2Qs.length + ex3Answers.length;
    final listenCorrect = ex1c + ex2c + ex3c;
    final mcqTotal      = listenTotal + grammarList.length + readingList.length;
    final mcqCorrect    = listenCorrect + gc + rc;
    final mcqPct        = (mcqCorrect / mcqTotal) * 100;
    final essayScore    = (_essayGrading?['score'] as num?)?.toInt() ?? 0;
    final overallPct    = ((mcqPct + essayScore) / 2).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        // ── Global score card ──────────────────────────────────────────────
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          const Text('SCORE GLOBAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.4, color: AppTheme.textTertiary)),
          const SizedBox(height: 20),
          Stack(alignment: Alignment.center, children: [
            SizedBox(width: 130, height: 130,
              child: CircularProgressIndicator(
                value: overallPct / 100, strokeWidth: 12,
                backgroundColor: AppTheme.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(overallPct >= 50 ? AppTheme.success : AppTheme.error),
              )),
            Text('$overallPct%', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold,
                color: overallPct >= 50 ? AppTheme.success : AppTheme.error)),
          ]),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _scoreTile('Écoute A',   '$ex1c/${statements.length}',      AppTheme.primary),
            _scoreTile('Écoute B',   '$ex2c/${ex2Qs.length}',           AppTheme.accent),
            _scoreTile('Écoute C',   '$ex3c/${ex3Answers.length}',      AppTheme.secondary),
            _scoreTile('Gram.',      '$gc/${grammarList.length}',        AppTheme.warning),
            _scoreTile('Lecture',    '$rc/${readingList.length}',        Colors.teal),
            _scoreTile('Écriture',   '$essayScore/100',                  Colors.purple),
          ]),
        ]))),

        const SizedBox(height: 28),
        const Center(child: Text('CORRECTIONS DÉTAILLÉES',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.accent))),
        const Divider(color: Colors.white12, height: 24),

        // ── Listening review ───────────────────────────────────────────────
        _sectionTitle('1. Compréhension Orale'),
        _transcriptCard(ex1Data['audio_script'] as String),
        const SizedBox(height: 14),
        _exAReview(statements),
        const SizedBox(height: 14),
        _exBReview(ex2Qs),
        const SizedBox(height: 14),
        _exCReview(ex3Data),

        const SizedBox(height: 24),
        // ── Grammar review ─────────────────────────────────────────────────
        _sectionTitle('2. Grammaire (Conditionnel, Voix Passive, COD/COI, Impératif)'),
        _mcqReview(grammarList, _grammarAnswers),

        const SizedBox(height: 24),
        // ── Reading review ─────────────────────────────────────────────────
        _sectionTitle('3. Compréhension Écrite'),
        _transcriptCard(_examData!['reading']['text'] as String, label: 'Texte de lecture :', color: AppTheme.accent),
        const SizedBox(height: 14),
        _mcqReview(readingList, _readingAnswers),

        const SizedBox(height: 24),
        // ── Writing review ─────────────────────────────────────────────────
        _sectionTitle('4. Expression Écrite'),
        _writingReview(),

        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () => setState(() {
            _examPhase = 'intro'; _examData = null; _essayGrading = null;
            _ex1Answers.clear(); _ex2Answers.clear(); _ex3Answers.clear();
            _grammarAnswers.clear(); _readingAnswers.clear();
            _essayController.clear(); _listeningSubPhase = 1; _currentQuestionIndex = 0;
          }),
          icon: const Icon(Icons.refresh),
          label: const Text('Passer un autre examen'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _scoreTile(String label, String score, Color c) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
    const SizedBox(height: 3),
    Text(score, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c)),
  ]);

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
  );

  Widget _transcriptCard(String text, {String label = 'Transcription de l\'enregistrement :', Color color = AppTheme.primary}) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surfaceLight.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(fontSize: 14, height: 1.55, color: AppTheme.textPrimary)),
      ]),
    );

  // ── Exercise A review ──────────────────────────────────────────────────────
  Widget _exAReview(List statements) {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('A. Vrai / Faux / On ne sait pas',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14)),
        const SizedBox(height: 12),
        ...List.generate(statements.length, (i) {
          final correct    = statements[i]['answer'] as String;
          final userAnswer = _ex1Answers[i];
          final ok         = userAnswer == correct;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ok ? AppTheme.success.withValues(alpha: 0.08) : AppTheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ok ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.error.withValues(alpha: 0.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(ok ? Icons.check_circle : Icons.cancel, size: 18, color: ok ? AppTheme.success : AppTheme.error),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${i + 1}. ${statements[i]['statement']}',
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(children: [
                  Text('Votre réponse : ', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                  Text(userAnswer ?? '—', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: ok ? AppTheme.success : AppTheme.error)),
                ]),
                if (!ok) Row(children: [
                  Text('Réponse correcte : ', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                  Text(correct, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.success)),
                ]),
              ])),
            ]),
          );
        }),
      ])),
    );
  }

  // ── Exercise B review ──────────────────────────────────────────────────────
  Widget _exBReview(List questions) {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('B. Choix Multiple (a / b / c)',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent, fontSize: 14)),
        const SizedBox(height: 12),
        ...List.generate(questions.length, (i) {
          final q       = questions[i];
          final opts    = List<String>.from(q['options']);
          final correct = q['correct'] as int;
          final userSel = _ex2Answers[i];
          final ok      = userSel == correct;
          return ExpansionTile(
            leading: Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? AppTheme.success : AppTheme.error),
            title: Text('${i + 1}) ${q['question']}',
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(ok ? 'Correct ✓' : 'Incorrect ✗',
                style: TextStyle(fontSize: 11, color: ok ? AppTheme.success : AppTheme.error)),
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: Column(children: [
                ...List.generate(opts.length, (j) {
                  final isC = j == correct; final isU = j == userSel;
                  final bg = isC ? AppTheme.success.withValues(alpha: 0.12) : (isU && !isC ? AppTheme.error.withValues(alpha: 0.12) : null);
                  final bd = isC ? AppTheme.success : (isU ? AppTheme.error : Colors.white.withValues(alpha: 0.05));
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: bd)),
                    child: Row(children: [
                      Icon(isC ? Icons.check : (isU ? Icons.close : Icons.circle_outlined), size: 15,
                          color: isC ? AppTheme.success : (isU ? AppTheme.error : AppTheme.textTertiary)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(opts[j], style: TextStyle(fontSize: 13, fontWeight: (isC || isU) ? FontWeight.bold : FontWeight.normal,
                          color: (isC || isU) ? Colors.white : AppTheme.textSecondary))),
                    ]),
                  );
                }),
                if (q['explanation'] != null) ...[
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Explication :', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(q['explanation'] as String, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
                    ])),
                ],
              ])),
            ],
          );
        }),
      ])),
    );
  }

  // ── Exercise C review ──────────────────────────────────────────────────────
  Widget _exCReview(Map<String, dynamic> ex3Data) {
    final dialogues   = ex3Data['dialogues']  as List;
    final situations  = List<String>.from(ex3Data['situations']);
    final correctAnsw = List<int>.from(ex3Data['answers']);

    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('C. Association Dialogues ↔ Situations',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 14)),
        const SizedBox(height: 12),
        ...List.generate(dialogues.length, (i) {
          final correct = correctAnsw[i];
          final userSel = _ex3Answers[i];
          final ok      = userSel == correct;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ok ? AppTheme.success.withValues(alpha: 0.07) : AppTheme.error.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ok ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.error.withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(ok ? Icons.check_circle : Icons.cancel, size: 18, color: ok ? AppTheme.success : AppTheme.error),
                const SizedBox(width: 8),
                Text('Dialogue ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.background.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                child: Text(dialogues[i]['script'] as String,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4, fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Text('Votre réponse : ', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                Text(userSel != null ? situations[userSel] : '—',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ok ? AppTheme.success : AppTheme.error)),
              ]),
              if (!ok) Row(children: [
                Text('Réponse correcte : ', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                Text(situations[correct], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.success)),
              ]),
            ]),
          );
        }),
      ])),
    );
  }

  // ── MCQ review (Grammar + Reading) ──────────────────────────────────────
  Widget _mcqReview(List questions, Map<int, int> answers) {
    return Column(children: List.generate(questions.length, (i) {
      final q       = questions[i];
      final correct = q['correct'] as int;
      final userSel = answers[i];
      final ok      = userSel == correct;
      final opts    = List<String>.from(q['options']);
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: ok ? AppTheme.success.withValues(alpha: 0.25) : AppTheme.error.withValues(alpha: 0.25), width: 1.5)),
        child: ExpansionTile(
          leading: Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? AppTheme.success : AppTheme.error),
          title: Text(q['question'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Text(ok ? 'Correct ✓' : 'Incorrect ✗', style: TextStyle(fontSize: 11, color: ok ? AppTheme.success : AppTheme.error)),
          children: [Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ...List.generate(opts.length, (j) {
              final isC = j == correct; final isU = j == userSel;
              final bg = isC ? AppTheme.success.withValues(alpha: 0.12) : (isU && !isC ? AppTheme.error.withValues(alpha: 0.12) : null);
              final bd = isC ? AppTheme.success : (isU ? AppTheme.error : Colors.white.withValues(alpha: 0.05));
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: bd)),
                child: Row(children: [
                  Icon(isC ? Icons.check : (isU ? Icons.close : Icons.circle_outlined), size: 15,
                      color: isC ? AppTheme.success : (isU ? AppTheme.error : AppTheme.textTertiary)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(opts[j], style: TextStyle(fontSize: 13, fontWeight: (isC || isU) ? FontWeight.bold : FontWeight.normal,
                      color: (isC || isU) ? Colors.white : AppTheme.textSecondary))),
                ]),
              );
            }),
            if (q['explanation'] != null) ...[
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Explication :', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(q['explanation'] as String, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
                ])),
            ],
          ]))],
        ),
      );
    }));
  }

  // ── Writing review ───────────────────────────────────────────────────────
  Widget _writingReview() {
    final w           = _examData!['writing'] as Map<String, dynamic>;
    final corrections = _essayGrading?['corrections'] as List? ?? [];
    final feedback    = _essayGrading?['feedback'] as String? ?? '';

    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(w['topic_title'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
        const SizedBox(height: 6),
        Text(w['prompt'] as String, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
        const Divider(height: 28, color: Colors.white12),
        const Text('Votre Rédaction :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
          child: Text(_essayController.text, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5, fontStyle: FontStyle.italic))),
        const SizedBox(height: 16),
        const Text('Évaluation du Professeur AI :', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent, fontSize: 14)),
        const SizedBox(height: 6),
        Text(feedback, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
        const SizedBox(height: 18),
        const Text('Erreurs et corrections :', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
        const SizedBox(height: 10),
        if (corrections.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.success.withValues(alpha: 0.2))),
            child: const Row(children: [
              Icon(Icons.check_circle_outline, color: AppTheme.success),
              SizedBox(width: 12),
              Expanded(child: Text('Aucune faute détectée — Excellent travail !', style: TextStyle(color: Colors.white, fontSize: 13))),
            ]),
          )
        else
          ...corrections.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Original : ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error, fontSize: 13)),
                Expanded(child: Text(c['original'] ?? '', style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppTheme.textSecondary, fontSize: 13))),
              ]),
              const SizedBox(height: 5),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Corrigé : ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 13)),
                Expanded(child: Text(c['corrected'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
              ]),
              const SizedBox(height: 6),
              Text(c['explanation'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary, height: 1.4)),
            ]),
          )),
      ])),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // INTRO SECTION
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildIntroSection() {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(20), width: double.infinity,
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5)),
        child: const Text('Groupe de FLE Caramel : évaluations de janvier 2025',
            textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      ),
      const SizedBox(height: 32),
      _iTitle('QUOI ?'),
      const SizedBox(height: 14),
      const Text('Les compétences évaluées pour le niveau B1 :',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
      const SizedBox(height: 10),
      _iBullet('Écoute A : Vrai / Faux / On ne sait pas (6 affirmations)'),
      _iBullet('Écoute B : Choix multiple a/b/c (5 questions)'),
      _iBullet('Écoute C : Association 4 dialogues → 1 situation parmi 6'),
      _iBullet('Grammaire : 8 QCM (Conditionnel, Voix Passive, COD/COI, Impératif)'),
      _iBullet('Compréhension écrite : 3 QCM sur un texte'),
      _iBullet('Expression écrite : 1 sujet corrigé par l\'IA'),
      const SizedBox(height: 32),
      _iTitle('QUE FAIRE ?'),
      const SizedBox(height: 14),
      _iSub('Vocabulaire :', 'La santé et le travail.'),
      const SizedBox(height: 8),
      _iSub('Grammaire :', 'Conditionnel, Voix Passive, COD/COI, et L\'Impératif (formes tu/nous/vous, irréguliers : va, sois, aie, sache).'),
      const SizedBox(height: 8),
      _iSub('Structure :', '1. Écoute (A: Vrai/Faux → B: QCM a/b/c → C: Dialogues)\n2. Grammaire (8 QCM)\n3. Lecture (3 QCM)\n4. Rédaction (corrigée par IA)'),
      const SizedBox(height: 44),
      Center(child: ElevatedButton.icon(
        onPressed: _fetchExam,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('COMMENCER L\'EXAMEN (Généré par IA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      )),
      const SizedBox(height: 40),
    ]));
  }

  Widget _iTitle(String t) => Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: AppTheme.secondary));
  Widget _iBullet(String t) => Padding(padding: const EdgeInsets.only(bottom: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('• ', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
      Expanded(child: Text(t, style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4))),
    ]));

  Widget _iSub(String t, String c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('→ $t', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.accent)),
    Padding(padding: const EdgeInsets.only(left: 14, top: 4), child: Text(c, style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4))),
  ]);

  // ═════════════════════════════════════════════════════════════════════════
  // Reusable UI widgets
  // ═════════════════════════════════════════════════════════════════════════

  Widget _exHeader(String title, String instruction, IconData icon, Color color) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 8),
        Text(instruction, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
      ]),
    );

  Widget _audioCard(String text, {int dialIdx = -1}) =>
    Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        const Icon(Icons.headphones_rounded, size: 38, color: AppTheme.primary),
        const SizedBox(height: 8),
        const Text('Enregistrement Audio', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Appuyez pour écouter le scénario.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 14),
        _playBtn(text, dialIdx: dialIdx),
        if (_ttsEngine.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_ttsEngine == 'neural' ? '🎙️ Voix Neurale Premium' : '🔊 Voix Système',
            style: TextStyle(fontSize: 11, color: _ttsEngine == 'neural' ? AppTheme.primary : Colors.orange, fontWeight: FontWeight.bold)),
        ),
      ]),
    );

  Widget _playBtn(String text, {int dialIdx = -1, bool compact = false}) {
    final loading = _isLoadingAudio && _playingDialIdx == dialIdx;
    final playing = _isPlaying && _playingDialIdx == dialIdx;
    if (loading) return const SpinKitPulse(color: AppTheme.primary, size: 36);
    return ElevatedButton.icon(
      onPressed: () => _speak(text, dialIdx: dialIdx),
      style: ElevatedButton.styleFrom(
        backgroundColor: playing ? AppTheme.error : AppTheme.primary,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white, size: compact ? 18 : 22),
      label: Text(playing ? 'Stop' : (compact ? 'Replay' : 'Écouter'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: compact ? 13 : 14, color: Colors.white)),
    );
  }

  Widget _questionCard({
    required String label, required int current, required int total,
    required String question, required List<String> options,
    required int? selected, required Function(int) onSelect,
  }) =>
    Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$label : ${current + 1}/$total', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 13)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Text('FLE B1', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 16),
      Text(question, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.4)),
      const SizedBox(height: 20),
      ...List.generate(options.length, (i) {
        final sel = selected == i;
        return _optBtn(options[i], sel, () => onSelect(i), bottom: i < options.length - 1);
      }),
    ])));

  Widget _optBtn(String text, bool selected, VoidCallback onTap, {bool bottom = true}) =>
    Padding(
      padding: EdgeInsets.only(bottom: bottom ? 10 : 0),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          side: BorderSide(color: selected ? AppTheme.primary : Colors.white.withValues(alpha: 0.1), width: selected ? 2 : 1),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(children: [
          Container(width: 20, height: 20,
            decoration: BoxDecoration(shape: BoxShape.circle,
              border: Border.all(color: selected ? AppTheme.primary : AppTheme.textTertiary, width: 2),
              color: selected ? AppTheme.primary : Colors.transparent),
            child: selected ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: selected ? Colors.white : AppTheme.textPrimary, fontWeight: selected ? FontWeight.bold : FontWeight.normal))),
        ]),
      ),
    );

  Widget _navButtons({VoidCallback? onBack, VoidCallback? onNext, String nextLabel = 'Suivant'}) =>
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      onBack != null
          ? OutlinedButton.icon(onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 17),
              label: const Text('Précédent'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))
          : const SizedBox.shrink(),
      ElevatedButton.icon(
        onPressed: onNext,
        icon: Icon(nextLabel.contains('Soumettre') ? Icons.check_circle_rounded : Icons.arrow_forward, size: 17),
        label: Text(nextLabel),
        style: ElevatedButton.styleFrom(
          backgroundColor: nextLabel.contains('Soumettre') ? AppTheme.success : AppTheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    ]);
}
