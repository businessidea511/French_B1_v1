import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/vocabulary_data.dart';
import '../../services/api_client.dart';
import '../../services/practice_logic.dart';
import '../../services/progress_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';

class DuelQuestion {
  final String prompt; // French or English (translated on screen)
  final bool promptIsEnglish;
  final String hint;
  final List<String> options;
  final int correct;
  const DuelQuestion(this.prompt, this.promptIsEnglish, this.hint, this.options, this.correct);
}

/// The 10 questions of a duel. Both players get the same ones because they
/// come from the duel code.
List<DuelQuestion> duelQuestions(String code) {
  final seed = code.codeUnits.fold<int>(17, (h, c) => (h * 31 + c) & 0x7fffffff);
  final random = Random(seed);
  final questions = <DuelQuestion>[];
  for (var i = 0; i < 6; i++) {
    final q = ConjugationQuiz.make(random, 'Moyen');
    final options = [q.answer, ...ConjugationQuiz.distractors(q, random)]..shuffle(random);
    questions.add(DuelQuestion('${q.prefix} ___', false, '${q.verb} · ${q.tenseLabel}', options, options.indexOf(q.answer)));
  }
  final categories = vocabularySection.categories.where((c) => !c.cognate && c.id != 'faux_amis').toList();
  for (var i = 0; i < 4; i++) {
    final category = categories[random.nextInt(categories.length)];
    final words = List.of(category.items)..shuffle(random);
    final answer = words.first;
    final options = [for (final w in words.take(4)) w.fr]..shuffle(random);
    questions.add(DuelQuestion(answer.en, true, category.title, options, options.indexOf(answer.fr)));
  }
  return questions..shuffle(random);
}

/// Friendly duel: same 10 questions for both players, scores shared by code.
class DuelPage extends StatefulWidget {
  const DuelPage({super.key});

  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(Map<String, dynamic> body) api = _callApi;

  static Future<List<Map<String, dynamic>>> _callApi(Map<String, dynamic> body) async {
    final response = await ApiClient.post('/api/duel', body, timeout: const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(ApiClient.errorMessage(response));
    return [for (final r in (jsonDecode(response.body)['rows'] as List? ?? const [])) Map<String, dynamic>.from(r as Map)];
  }

  @override
  State<DuelPage> createState() => _DuelPageState();
}

enum _Stage { lobby, play, result }

class _DuelPageState extends State<DuelPage> {
  final _name = TextEditingController();
  final _join = TextEditingController();
  _Stage _stage = _Stage.lobby;
  String _code = '';
  List<DuelQuestion> _questions = [];
  int _index = 0;
  int _correct = 0;
  int? _picked;
  final Stopwatch _clock = Stopwatch();
  Timer? _ticker;
  List<Map<String, dynamic>>? _board;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) _name.text = p.getString('duel_name') ?? '';
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _name.dispose();
    _join.dispose();
    super.dispose();
  }

  static String _newCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> _start(String code) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Écris ton prénom d\'abord.');
      return;
    }
    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) {
      setState(() => _error = 'Le code a 6 lettres ou chiffres.');
      return;
    }
    (await SharedPreferences.getInstance()).setString('duel_name', name);
    setState(() {
      _error = null;
      _code = code;
      _questions = duelQuestions(code);
      _index = 0;
      _correct = 0;
      _picked = null;
      _board = null;
      _stage = _Stage.play;
    });
    _clock
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _answer(int i) {
    if (_picked != null) return;
    final q = _questions[_index];
    setState(() => _picked = i);
    if (i == q.correct) {
      _correct++;
      ProgressService.instance.addXp(2);
    } else {
      ProgressService.instance.addMistake(
        source: 'Duel',
        question: q.promptIsEnglish ? '${q.hint}: ${q.prompt}' : '${q.hint} · ${q.prompt}',
        wrong: q.options[i],
        right: q.options[q.correct],
        options: q.options,
      );
    }
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_index + 1 >= _questions.length) {
        _finish();
      } else {
        setState(() {
          _index++;
          _picked = null;
        });
      }
    });
  }

  int get _seconds => _clock.elapsed.inSeconds;
  int get _score => _correct * 100 + max(0, 300 - _seconds);

  Future<void> _finish() async {
    _clock.stop();
    _ticker?.cancel();
    setState(() {
      _stage = _Stage.result;
      _sending = true;
    });
    if (_correct >= 8) Confetti.burst(context);
    try {
      final board = await DuelPage.api({
        'action': 'submit',
        'code': _code,
        'name': _name.text.trim(),
        'score': _score,
        'correct': _correct,
        'seconds': _seconds,
      });
      if (mounted) setState(() => _board = board);
    } catch (e) {
      if (mounted) setState(() => _error = 'Le serveur des duels n\'est pas prêt. Ton score : $_score.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _sending = true);
    try {
      final board = await DuelPage.api({'action': 'list', 'code': _code});
      if (mounted) setState(() => _board = board);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _copyInvite() {
    Clipboard.setData(ClipboardData(text: 'Je te défie en français ! ⚔️ Ouvre PolyLearn → Pratiquer → Duel, et entre le code $_code'));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation copiée ✓')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚔️ Duel entre amis')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: switch (_stage) {
          _Stage.lobby => _buildLobby(),
          _Stage.play => _buildPlay(),
          _Stage.result => _buildResult(),
        },
      ),
    );
  }

  Widget _buildLobby() {
    return PageBody(
      key: const ValueKey('lobby'),
      children: [
        const Center(child: Floating(child: Text('⚔️', style: TextStyle(fontSize: 70)))),
        const SizedBox(height: 10),
        TranslatedText(
          'Challenge your classmate! You both answer the same 10 questions. Create a duel and send the code, or enter the code you received.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          maxLength: 24,
          decoration: const InputDecoration(hintText: 'Ton prénom', prefixIcon: Icon(Icons.person_rounded)),
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: AppTheme.error)),
        const SizedBox(height: 10),
        GlowButton(
          label: 'Créer un duel',
          icon: Icons.add_circle_rounded,
          colors: [AppTheme.secondary, Color(0xFFF97316)],
          onPressed: () => _start(_newCode()),
        ),
        const SectionTitle('J\'ai reçu un code'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _join,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                style: const TextStyle(letterSpacing: 6, fontSize: 22, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(hintText: 'CODE', counterText: ''),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: GlowButton(label: 'Rejoindre', onPressed: () => _start(_join.text.trim().toUpperCase())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlay() {
    final q = _questions[_index];
    return PageBody(
      key: ValueKey('q$_index'),
      children: [
        Row(
          children: [
            Text('Code $_code', style: TextStyle(color: AppTheme.textTertiary, letterSpacing: 2)),
            const Spacer(),
            Text('⏱ ${_seconds}s   ✓ $_correct', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: _index / _questions.length, minHeight: 6),
        ),
        const SizedBox(height: 20),
        Entrance(
          child: GlassCard(
            glow: AppTheme.secondary,
            child: Column(
              children: [
                Text(q.hint, style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (q.promptIsEnglish)
                  TranslatedText(q.prompt,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textPrimary))
                else
                  Text(q.prompt,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        for (final (i, option) in q.options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Entrance(
              index: i + 1,
              child: Tilt3D(
                maxTilt: 0.08,
                onTap: () => _answer(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _picked == null
                        ? AppTheme.surface.withValues(alpha: 0.8)
                        : i == q.correct
                            ? AppTheme.success.withValues(alpha: 0.3)
                            : i == _picked
                                ? AppTheme.error.withValues(alpha: 0.3)
                                : AppTheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.fg.withValues(alpha: 0.12)),
                  ),
                  child: Text(option,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResult() {
    final me = _name.text.trim();
    return PageBody(
      key: const ValueKey('result'),
      children: [
        Center(child: Floating(child: Text(_correct >= 8 ? '🏆' : '⚔️', style: const TextStyle(fontSize: 72)))),
        Center(
          child: Text('$_score pts',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppTheme.warning)),
        ),
        Center(child: Text('$_correct / 10 · ${_seconds}s', style: TextStyle(color: AppTheme.textSecondary))),
        const SizedBox(height: 16),
        GlassCard(
          glow: AppTheme.primary,
          child: Column(
            children: [
              TranslatedText('Send this code to your friend:', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              SelectableText(_code,
                  style: TextStyle(fontSize: 34, letterSpacing: 8, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
              TextButton.icon(onPressed: _copyInvite, icon: const Icon(Icons.copy_rounded), label: const Text('Copier l\'invitation')),
            ],
          ),
        ),
        SectionTitle(
          'Classement',
          trailing: IconButton(
            onPressed: _sending ? null : _refresh,
            icon: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
          ),
        ),
        if (_error != null) TranslatedText(_error!, style: TextStyle(color: AppTheme.error)),
        for (final (i, row) in (_board ?? const <Map<String, dynamic>>[]).indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Entrance(
              index: i,
              child: GlassCard(
                glow: row['name'] == me ? AppTheme.warning : null,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(i < 3 ? ['🥇', '🥈', '🥉'][i] : '${i + 1}.', style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${row['name']}', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17))),
                    Text('${row['score']} pts', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Text('${row['correct']}/10 · ${row['seconds']}s', style: TextStyle(color: AppTheme.textTertiary)),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        TextButton(onPressed: () => setState(() => _stage = _Stage.lobby), child: const Text('Nouveau duel')),
      ],
    );
  }
}
