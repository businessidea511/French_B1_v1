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
import '../../services/ui_strings.dart';
import '../../services/web_share.dart';
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
  /// Code from an invitation link (…/?duel=ABC123): the lobby opens with it filled in.
  final String? initialCode;

  const DuelPage({super.key, this.initialCode});

  /// The 6-character code in this page's address, if the app was opened from an invitation link.
  static String? codeFromLink() {
    final code = (Uri.base.queryParameters['duel'] ?? '').trim().toUpperCase();
    return RegExp(r'^[A-Z0-9]{6}$').hasMatch(code) ? code : null;
  }

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

enum _Stage { lobby, ready, play, result }

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
  Timer? _boardTimer; // keeps the class ranking fresh on the results screen
  List<Map<String, dynamic>>? _board;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) _join.text = widget.initialCode!;
    SharedPreferences.getInstance().then((p) {
      if (mounted) _name.text = p.getString('duel_name') ?? '';
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _boardTimer?.cancel();
    _name.dispose();
    _join.dispose();
    super.dispose();
  }

  static String _newCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<bool> _checkName() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = tr(context, 'Write your first name first.'));
      return false;
    }
    (await SharedPreferences.getInstance()).setString('duel_name', name);
    return true;
  }

  /// Creator: make a code and show it, so it can be sent before playing.
  Future<void> _create() async {
    if (!await _checkName()) return;
    setState(() {
      _error = null;
      _code = _newCode();
      _stage = _Stage.ready;
    });
  }

  Future<void> _start(String code) async {
    if (!await _checkName()) return;
    if (!mounted) return;
    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) {
      setState(() => _error = tr(context, 'The code has 6 letters or numbers.'));
      return;
    }
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
      _boardTimer?.cancel();
      _boardTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted && _stage == _Stage.result && !_sending) _refresh();
      });
    } catch (e) {
      if (mounted) setState(() => _error = tr(context, 'The duel server is not ready. Your score: {n}.', {'n': _score}));
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

  String get _inviteLink => '${Uri.base.origin}/?duel=$_code';

  String get _invite => 'Je te défie en français ! ⚔️ Duel PolyLearn, code $_code\n$_inviteLink';

  void _copyInvite() {
    Clipboard.setData(ClipboardData(text: _invite));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'Invitation copied ✓'))));
  }

  Future<void> _shareInvite() async {
    if (!await WebShare.share(_invite)) _copyInvite();
  }

  /// The big code with Share / Copy buttons.
  Widget _codeCard() => GlassCard(
        glow: AppTheme.primary,
        child: Column(
          children: [
            TranslatedText('Send this code to your friend:', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            SelectableText(_code,
                style: TextStyle(fontSize: 38, letterSpacing: 8, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (WebShare.supported)
                  FilledButton.icon(
                      onPressed: _shareInvite, icon: const Icon(Icons.ios_share_rounded), label: Text(tr(context, 'Share'))),
                OutlinedButton.icon(
                    onPressed: _copyInvite, icon: const Icon(Icons.copy_rounded), label: Text(tr(context, 'Copy the invitation'))),
              ],
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('⚔️ ${tr(context, 'Duel with friends')}')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: switch (_stage) {
          _Stage.lobby => _buildLobby(),
          _Stage.ready => _buildReady(),
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
          'Challenge a friend or your whole class! Everyone with the code answers the same 10 questions. Create a duel and send the code, or enter the code you received.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          maxLength: 24,
          decoration: InputDecoration(hintText: tr(context, 'Your first name'), prefixIcon: const Icon(Icons.person_rounded)),
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: AppTheme.error)),
        const SizedBox(height: 10),
        GlowButton(
          label: tr(context, 'Create a duel'),
          icon: Icons.add_circle_rounded,
          colors: [AppTheme.secondary, Color(0xFFF97316)],
          onPressed: _create,
        ),
        SectionTitle(tr(context, 'I received a code')),
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
              child: GlowButton(label: tr(context, 'Join'), onPressed: () => _start(_join.text.trim().toUpperCase())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReady() {
    return PageBody(
      key: const ValueKey('ready'),
      children: [
        const Center(child: Floating(child: Text('📨', style: TextStyle(fontSize: 64)))),
        const SizedBox(height: 10),
        _codeCard(),
        const SizedBox(height: 14),
        TranslatedText(
          'Send it to one friend or to your class group. Everyone opens the link (or Practice → Duel and types the code) and plays the same 10 questions, whenever they want. The ranking shows who wins.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 20),
        GlowButton(label: tr(context, 'Play!'), icon: Icons.play_arrow_rounded, onPressed: () => _start(_code)),
        const SizedBox(height: 6),
        TextButton(onPressed: () => setState(() => _stage = _Stage.lobby), child: Text(tr(context, 'Back'))),
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
    final board = _board ?? const <Map<String, dynamic>>[];
    final myRank = board.indexWhere((r) => '${r['name']}'.trim().toLowerCase() == me.toLowerCase());
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
        if (myRank >= 0) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(tr(context, 'You are #{rank} of {total}', {'rank': myRank + 1, 'total': board.length}),
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ],
        const SizedBox(height: 12),
        _codeCard(),
        SectionTitle(
          '${tr(context, 'Ranking')} · ${board.length} 👥',
          trailing: IconButton(
            onPressed: _sending ? null : _refresh,
            icon: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
          ),
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: AppTheme.error)),
        for (final (i, row) in board.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Entrance(
              index: i,
              child: GlassCard(
                glow: i == myRank ? AppTheme.warning : null,
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
        TextButton(
            onPressed: () {
              _boardTimer?.cancel();
              setState(() => _stage = _Stage.lobby);
            },
            child: Text(tr(context, 'New duel'))),
      ],
    );
  }
}
