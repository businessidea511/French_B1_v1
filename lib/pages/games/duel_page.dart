import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../services/duel_questions.dart';
import '../../services/lessons_provider.dart';
import '../../services/progress_service.dart';
import '../../services/ui_strings.dart';
import '../../services/web_share.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';

export '../../services/duel_questions.dart' show DuelQuestion, duelQuestions;

/// Friendly duel for a friend or a whole class: same questions for everyone, scores shared by code.
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

  /// Saves or loads a duel's questions. Throws [DuelServerError] with the HTTP status on failure.
  @visibleForTesting
  static Future<Map<String, dynamic>> Function(Map<String, dynamic> body) send = _send;

  static Future<Map<String, dynamic>> _send(Map<String, dynamic> body) async {
    final response = await ApiClient.post('/api/duel', body, timeout: const Duration(seconds: 20));
    if (response.statusCode != 200) throw DuelServerError(response.statusCode);
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  /// Waiting-room status of a live duel (players, start time), polled every 2 s.
  @visibleForTesting
  static Future<Map<String, dynamic>?> Function(String code) status = _status;

  static Future<Map<String, dynamic>?> _status(String code) async {
    final response = await http.get(ApiClient.uri('/api/duel?code=$code')).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw DuelServerError(response.statusCode);
    final value = (jsonDecode(response.body) as Map)['status'];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static Future<List<Map<String, dynamic>>> _callApi(Map<String, dynamic> body) async {
    final response = await ApiClient.post('/api/duel', body, timeout: const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(ApiClient.errorMessage(response));
    return [for (final r in (jsonDecode(response.body)['rows'] as List? ?? const [])) Map<String, dynamic>.from(r as Map)];
  }

  @override
  State<DuelPage> createState() => _DuelPageState();
}

class DuelServerError implements Exception {
  final int status;
  const DuelServerError(this.status);
  @override
  String toString() => 'Duel server error $status';
}

enum _Stage { lobby, preparing, ready, waiting, play, result }

class _DuelPageState extends State<DuelPage> {
  final _name = TextEditingController();
  final _join = TextEditingController();
  _Stage _stage = _Stage.lobby;
  String _code = '';
  List<DuelQuestion> _questions = [];
  List<String> _topics = [];
  String _preparing = '';
  int _index = 0;
  int _correct = 0;
  int? _picked;
  final Stopwatch _clock = Stopwatch();
  Timer? _ticker;
  Timer? _boardTimer; // keeps the class ranking fresh on the results screen
  List<Map<String, dynamic>>? _board;
  String? _error;
  bool _sending = false;

  // Live duel: everyone waits in a room and starts at the same moment.
  String? _hostKey; // only on the creator's phone
  Map<String, dynamic>? _liveStatus; // last status from the server
  List<String> _players = [];
  String? _hostName;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  int? _countdown; // seconds before the start, shown big
  DateTime _waitingSince = DateTime.now();
  bool _starting = false;

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
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
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

  /// Creator: choose topics and number of questions, prepare the questions,
  /// save them with a new code and show the code, so it can be sent before playing.
  Future<void> _create() async {
    if (!await _checkName()) return;
    if (!mounted) return;
    final grammar = context.read<LessonsProvider>().allGrammar;
    final choice = await showModalBottomSheet<(DuelTopics, int)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _DuelSetupSheet(grammarTitles: [for (final g in grammar) g.title]),
    );
    if (choice == null || !mounted) return;
    final (topics, count) = choice;
    setState(() {
      _error = null;
      _preparing = tr(context, 'Preparing the questions…');
      _stage = _Stage.preparing;
    });
    try {
      final rules = {
        for (final g in grammar)
          if (topics.grammar.contains(g.title))
            g.title: [
              for (final w in g.content ?? const [])
                if (w is Map && w['type'] == 'section_title') '${w['title'] ?? ''}',
            ],
      };
      final questions = await DuelBuilder.build(topics, count: count, grammarRules: rules);
      final hostKey = _newHostKey();
      var live = false;
      for (var attempt = 0; ; attempt++) {
        final code = _newCode();
        try {
          final created = await DuelPage.send({
            'action': 'create',
            'code': code,
            'topics': topics.names,
            'questions': [for (final q in questions) q.toJson()],
            'host_key': hostKey,
            'host_name': _name.text.trim(),
          });
          _code = code;
          live = created['live'] == true;
          break;
        } on DuelServerError catch (e) {
          if (e.status == 409 && attempt < 3) continue; // code already taken
          // Server not ready (duels.sql not run): only the classic duel works, its questions come from the code.
          if (topics.grammar.isEmpty && topics.withConjugation && topics.withVocabulary && count == 10) {
            _code = code;
            _questions = duelQuestions(code);
            _topics = topics.names;
            if (mounted) setState(() => _stage = _Stage.ready);
            return;
          }
          rethrow;
        }
      }
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _topics = topics.names;
        _stage = _Stage.ready;
      });
      if (live) {
        _hostKey = hostKey;
        _hostName = _name.text.trim();
        _players = [_name.text.trim()];
        _enterWaiting();
      }
    } catch (e) {
      debugPrint('Duel not created: $e');
      if (!mounted) return;
      setState(() {
        _stage = _Stage.lobby;
        _error = tr(context, e is DuelServerError && e.status == 503
            ? 'The class duel server is not ready yet.'
            : 'Could not prepare the questions. Try again.');
      });
    }
  }

  static String _newHostKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return List.generate(24, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// The questions of a duel: saved with the code, or (older duels) made from the code.
  Future<List<DuelQuestion>> _loadQuestions(String code) async {
    if (code == _code && _questions.isNotEmpty) return _questions;
    _liveStatus = null;
    try {
      final answer = await DuelPage.send({'action': 'get', 'code': code});
      final duel = answer['duel'];
      if (answer['status'] is Map) _liveStatus = Map<String, dynamic>.from(answer['status'] as Map);
      if (duel is Map) {
        final questions = [
          for (final raw in (duel['questions'] as List? ?? const [])) DuelQuestion.fromJson(raw),
        ].whereType<DuelQuestion>().toList();
        if (questions.isNotEmpty) {
          _topics = [for (final t in (duel['topics'] as List? ?? const [])) '$t'];
          return questions;
        }
      }
    } catch (e) {
      debugPrint('Duel questions not loaded, using the classic ones: $e');
    }
    _topics = [];
    return duelQuestions(code);
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
      _preparing = tr(context, 'Loading the duel…');
      _stage = _Stage.preparing;
    });
    final questions = await _loadQuestions(code);
    if (!mounted) return;
    _code = code;
    _questions = questions;
    // Live duel created by someone else: join the waiting room (or play at once if it has started).
    final status = _liveStatus;
    if (_hostKey == null && status != null && status['live'] == true) {
      final startedAt = DateTime.tryParse('${status['started_at'] ?? ''}');
      try {
        final joined = await DuelPage.send({'action': 'join', 'code': code, 'name': _name.text.trim()});
        if (joined['status'] is Map) _applyStatus(Map<String, dynamic>.from(joined['status'] as Map));
      } catch (e) {
        debugPrint('Could not join the waiting room: $e');
      }
      if (!mounted) return;
      final serverNow = DateTime.tryParse('${status['now'] ?? ''}');
      final late = startedAt != null && serverNow != null && !startedAt.isAfter(serverNow);
      if (!late) {
        _enterWaiting();
        return;
      }
    }
    _begin();
  }

  /// Starts answering now (the clock and score start here).
  void _begin() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _countdown = null;
      _index = 0;
      _correct = 0;
      _picked = null;
      _board = null;
      _stage = _Stage.play;
    });
    _clock
      ..reset()
      ..start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  // ── Live duel: waiting room and synchronised start ─────────────────────────

  void _enterWaiting() {
    _waitingSince = DateTime.now();
    setState(() => _stage = _Stage.waiting);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    _poll();
  }

  Future<void> _poll() async {
    if (_stage != _Stage.waiting || _countdownTimer != null) return;
    try {
      final status = await DuelPage.status(_code);
      if (status != null && mounted) _applyStatus(status);
    } catch (e) {
      debugPrint('Waiting room status failed: $e');
    }
    if (mounted && _stage == _Stage.waiting) setState(() {}); // e.g. "play without waiting" after 2 min
  }

  /// Shows who is waiting and, once the creator pressed Start, counts down to
  /// the start time. The server's clock decides, so every phone starts together.
  void _applyStatus(Map<String, dynamic> status) {
    setState(() {
      _players = [for (final p in (status['players'] as List? ?? const [])) '$p'];
      _hostName = (status['host_name'] as String?) ?? _hostName;
    });
    final startedAt = DateTime.tryParse('${status['started_at'] ?? ''}');
    final serverNow = DateTime.tryParse('${status['now'] ?? ''}');
    if (startedAt == null || serverNow == null || _countdownTimer != null || _stage != _Stage.waiting) return;
    final startLocal = DateTime.now().add(startedAt.difference(serverNow));
    void tick() {
      final left = startLocal.difference(DateTime.now());
      if (left <= Duration.zero) {
        _begin();
      } else if (mounted) {
        setState(() => _countdown = (left.inMilliseconds / 1000).ceil());
      }
    }

    _pollTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => tick());
    tick();
  }

  Future<void> _startForEveryone() async {
    if (_hostKey == null || _starting) return;
    setState(() => _starting = true);
    try {
      final answer = await DuelPage.send({'action': 'start', 'code': _code, 'host_key': _hostKey});
      if (answer['status'] is Map && mounted) _applyStatus(Map<String, dynamic>.from(answer['status'] as Map));
    } catch (e) {
      debugPrint('Start failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'Connection lost. Try again.'))));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _leaveWaiting() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _countdownTimer = null;
    setState(() {
      _countdown = null;
      _hostKey = null;
      _stage = _Stage.lobby;
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
  /// 100 points per right answer, plus a speed bonus (30 seconds per question).
  int get _score => _correct * 100 + max(0, 30 * _questions.length - _seconds);

  Future<void> _finish() async {
    _clock.stop();
    _ticker?.cancel();
    setState(() {
      _stage = _Stage.result;
      _sending = true;
    });
    if (_correct >= _questions.length * 0.8) Confetti.burst(context);
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
          _Stage.preparing => _buildPreparing(),
          _Stage.ready => _buildReady(),
          _Stage.waiting => _buildWaiting(),
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
          'Challenge a friend or your whole class! Choose the topics and the number of questions; everyone with the code answers the same questions, from easy to hard. Create a duel and send the code, or enter the code you received.',
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

  /// "10 questions · Le Subjonctif · Conjugaison"
  Widget _topicsLine() => Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          Chip(
            label: Text(tr(context, '{n} questions', {'n': _questions.length})),
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
          ),
          for (final t in _topics) Chip(label: Text(t)),
        ],
      );

  Widget _buildPreparing() {
    return PageBody(
      key: const ValueKey('preparing'),
      children: [
        const SizedBox(height: 60),
        const Center(child: Floating(child: Text('🧠', style: TextStyle(fontSize: 64)))),
        const SizedBox(height: 18),
        Center(child: Text(_preparing, style: TextStyle(color: AppTheme.textSecondary, fontSize: 16))),
        const SizedBox(height: 18),
        const Center(child: SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3))),
      ],
    );
  }

  Widget _buildWaiting() {
    final isHost = _hostKey != null;
    final me = _name.text.trim().toLowerCase();
    final waitedLong = DateTime.now().difference(_waitingSince) > const Duration(minutes: 2);
    if (_countdown != null) {
      return Center(
        key: const ValueKey('countdown'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr(context, 'Get ready!'), style: TextStyle(color: AppTheme.textSecondary, fontSize: 20)),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
              child: Text('${_countdown!}',
                  key: ValueKey(_countdown),
                  style: TextStyle(fontSize: 120, fontWeight: FontWeight.w900, color: AppTheme.primary)),
            ),
          ],
        ),
      );
    }
    return PageBody(
      key: const ValueKey('waiting'),
      children: [
        if (isHost) ...[
          _codeCard(),
          const SizedBox(height: 12),
        ] else ...[
          const Center(child: Floating(child: Text('⏳', style: TextStyle(fontSize: 60)))),
          const SizedBox(height: 10),
          Center(
            child: Text(
              _hostName == null
                  ? tr(context, 'Waiting for the creator to start…')
                  : tr(context, 'Waiting for {name} to start…', {'name': _hostName}),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 10),
        ],
        _topicsLine(),
        SectionTitle('${tr(context, 'Players')} · ${_players.length} 👥'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, p) in _players.indexed)
              Entrance(
                index: i,
                child: Chip(
                  avatar: Text(p.trim().toLowerCase() == me ? '⭐' : '🙂'),
                  label: Text(p),
                  backgroundColor: p.trim().toLowerCase() == me ? AppTheme.warning.withValues(alpha: 0.2) : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (isHost) ...[
          GlowButton(
            label: tr(context, 'Start for everyone'),
            icon: Icons.flag_rounded,
            onPressed: _starting ? null : _startForEveryone,
          ),
          const SizedBox(height: 8),
          Text(tr(context, 'When everyone is here, press Start: all phones count down 3-2-1 and begin together.'),
              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
        ] else if (waitedLong)
          TextButton(onPressed: _begin, child: Text(tr(context, 'Play now without waiting'))),
        const SizedBox(height: 8),
        TextButton(onPressed: _leaveWaiting, child: Text(tr(context, 'Back'))),
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
        const SizedBox(height: 12),
        _topicsLine(),
        const SizedBox(height: 14),
        TranslatedText(
          'Send it to one friend or to your class group. Everyone opens the link (or Practice → Duel and types the code) and plays the same questions, whenever they want. The ranking shows who wins.',
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
            Text('⏱ ${_seconds}s   ✓ $_correct', textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)),
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
        Center(child: Floating(child: Text(_correct >= _questions.length * 0.8 ? '🏆' : '⚔️', style: const TextStyle(fontSize: 72)))),
        Center(
          child: Text('$_score pts', textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppTheme.warning)),
        ),
        Center(child: Text('$_correct / ${_questions.length} · ${_seconds}s', textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.textSecondary))),
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
        if (_topics.isNotEmpty) ...[const SizedBox(height: 10), _topicsLine()],
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
                    Text('${row['score']} pts', textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Text('${row['correct']}/${_questions.length} · ${row['seconds']}s', textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.textTertiary)),
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


/// Creator's choices: what the duel covers and how many questions.
class _DuelSetupSheet extends StatefulWidget {
  final List<String> grammarTitles;
  const _DuelSetupSheet({required this.grammarTitles});

  @override
  State<_DuelSetupSheet> createState() => _DuelSetupSheetState();
}

class _DuelSetupSheetState extends State<_DuelSetupSheet> {
  bool _conjugation = true;
  bool _vocabulary = true;
  final Set<String> _grammar = {};
  int _count = 10;

  bool get _all => _conjugation && _vocabulary && _grammar.length == widget.grammarTitles.length;
  bool get _empty => !_conjugation && !_vocabulary && _grammar.isEmpty;

  void _toggleAll() => setState(() {
        final on = !_all;
        _conjugation = on;
        _vocabulary = on;
        _grammar
          ..clear()
          ..addAll(on ? widget.grammarTitles : const []);
      });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool selected, VoidCallback onTap, {String? emoji}) => FilterChip(
          label: Text(emoji == null ? label : '$emoji $label'),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppTheme.primary.withValues(alpha: 0.25),
          checkmarkColor: AppTheme.primary,
        );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.textTertiary, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 16),
          Text(tr(context, 'What should the duel cover?'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(tr(context, 'All topics'), _all, _toggleAll, emoji: '🌍'),
              chip(DuelTopics.conjugation, _conjugation, () => setState(() => _conjugation = !_conjugation), emoji: '🎯'),
              chip(DuelTopics.vocabulary, _vocabulary, () => setState(() => _vocabulary = !_vocabulary), emoji: '📚'),
            ],
          ),
          const SizedBox(height: 14),
          Text(tr(context, 'Grammar'), style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in widget.grammarTitles)
                chip(t, _grammar.contains(t), () => setState(() => _grammar.contains(t) ? _grammar.remove(t) : _grammar.add(t))),
            ],
          ),
          const SizedBox(height: 20),
          Text(tr(context, 'How many questions?'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [for (final n in DuelBuilder.counts) ButtonSegment(value: n, label: Text('$n'))],
            selected: {_count},
            onSelectionChanged: (v) => setState(() => _count = v.first),
          ),
          const SizedBox(height: 8),
          Text(tr(context, 'From easy to hard.'), style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
          const SizedBox(height: 22),
          if (_empty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(tr(context, 'Choose at least one topic.'), style: TextStyle(color: AppTheme.error)),
            ),
          GlowButton(
            label: tr(context, 'Create the duel'),
            icon: Icons.bolt_rounded,
            onPressed: _empty
                ? null
                : () => Navigator.pop(
                      context,
                      (
                        DuelTopics(withConjugation: _conjugation, withVocabulary: _vocabulary, grammar: _grammar.toList()),
                        _count,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
