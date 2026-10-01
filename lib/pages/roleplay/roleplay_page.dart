import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/roleplay_scenarios.dart';
import '../../services/deepseek_service.dart';
import '../../services/language_provider.dart';
import '../../services/progress_service.dart';
import '../../services/speech_input.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';
import '../../services/ui_strings.dart';

/// Choose a real Belgian situation to act out with the AI.
class RoleplayPage extends StatelessWidget {
  const RoleplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🎭 ${tr(context, 'Role-play')}')),
      body: PageBody(
        children: [
          TranslatedText(
            'Practise real situations of life in Belgium. Professeur AI plays the other person, answers you, and corrects your French after every message.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 12),
          FeatureGrid(tiles: [
            for (final s in scenarios)
              FeatureTile(
                emoji: s.emoji,
                title: s.title,
                subtitle: s.goal,
                color: AppTheme.secondary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoleplayChatPage(scenario: s))),
              ),
          ]),
        ],
      ),
    );
  }
}

class _Message {
  final bool fromAi;
  final String text;
  String correction = '';
  String explanation = '';
  String? translation;
  _Message(this.fromAi, this.text);
}

class RoleplayChatPage extends StatefulWidget {
  final Scenario scenario;
  const RoleplayChatPage({super.key, required this.scenario});

  /// The AI call. Tests replace it with a fake.
  @visibleForTesting
  static Future<Map<String, dynamic>> Function(
    List<Map<String, dynamic>> messages, {
    bool thinking,
    double? temperature,
    int? maxTokens,
  }) chat = DeepSeekService.chatJson;

  @override
  State<RoleplayChatPage> createState() => _RoleplayChatPageState();
}

class _RoleplayChatPageState extends State<RoleplayChatPage> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  late final List<_Message> _messages = [_Message(true, widget.scenario.opening)];
  bool _waiting = false;
  bool _done = false;
  String? _hint;
  final _speech = SpeechInput();
  bool _listening = false;
  String _beforeVoice = '';

  @override
  void initState() {
    super.initState();
    TtsService.instance.speak(widget.scenario.opening);
  }

  @override
  void dispose() {
    _speech.stop();
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _language => context.read<LanguageProvider>().currentLanguage.englishName;

  String get _system => '''You are role-playing in French with a B1 learner who lives in Belgium.
YOUR ROLE: ${widget.scenario.aiRole}.
SITUATION: ${widget.scenario.title}. THE LEARNER'S GOAL: ${widget.scenario.goal}
RULES
- Stay in character. Speak natural, simple B1 French (Belgian context: Belgian words where natural, euros, real Belgian places).
- 1 to 3 short sentences per reply, and usually end with a question so the conversation continues.
- React to exactly what the learner says. Make it a little challenging (ask for details, a small problem), but friendly.
- Never speak another language than French in "reply", even if the learner does.
- The learner may answer by voice (speech-to-text), so ignore missing punctuation and capitals.
- When the learner's goal is clearly reached, close the conversation naturally and set "done": true.
CORRECTION of the learner's LAST message only:
- If it has French mistakes (grammar, wrong word, missing accent that changes meaning), give the corrected sentence with minimal changes in "correction" and a very short explanation in $_language in "explanation".
- If it is correct (or the only issue is a missing capital or full stop), "correction" and "explanation" are "".
Return JSON: {"reply": "...", "correction": "", "explanation": "", "done": false}''';

  List<Map<String, dynamic>> get _history => [
        {'role': 'system', 'content': _system},
        for (final m in _messages) {'role': m.fromAi ? 'assistant' : 'user', 'content': m.text},
      ];

  void _toggleMic() {
    if (_listening) {
      _speech.stop();
      return;
    }
    TtsService.instance.stop();
    _beforeVoice = _input.text.trim();
    final ok = _speech.start(
      onText: (text, _) {
        if (!mounted) return;
        final full = _beforeVoice.isEmpty ? text : '$_beforeVoice $text';
        _input.value = TextEditingValue(text: full, selection: TextSelection.collapsed(offset: full.length));
      },
      onEnd: () {
        if (mounted) setState(() => _listening = false);
      },
      onError: (error) {
        if (!mounted) return;
        final msg = error == 'not-allowed' || error == 'service-not-allowed'
            ? 'Allow the microphone in your browser to speak.'
            : error == 'no-speech'
                ? 'I did not hear anything. Tap the microphone and speak.'
                : 'The microphone did not work. Try again or type.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, msg))));
      },
    );
    setState(() => _listening = ok);
  }

  Future<void> _send() async {
    if (_listening) _speech.stop();
    final text = _input.text.trim();
    if (text.isEmpty || _waiting || _done) return;
    final mine = _Message(false, text);
    setState(() {
      _messages.add(mine);
      _waiting = true;
      _hint = null;
      _input.clear();
    });
    _scrollDown();
    try {
      final r = await RoleplayChatPage.chat(_history, temperature: 0.8, maxTokens: 900);
      final reply = '${r['reply'] ?? ''}'.trim();
      mine.correction = '${r['correction'] ?? ''}'.trim();
      mine.explanation = '${r['explanation'] ?? ''}'.trim();
      if (mine.correction.isNotEmpty && mine.correction != mine.text) {
        ProgressService.instance.addMistake(
          source: 'Jeu de rôle',
          question: '🎭 ${widget.scenario.title}',
          wrong: mine.text,
          right: mine.correction,
          explanation: mine.explanation,
        );
      } else {
        mine.correction = '';
      }
      ProgressService.instance.addXp(3);
      if (!mounted) return;
      setState(() {
        if (reply.isNotEmpty) _messages.add(_Message(true, reply));
        _done = r['done'] == true;
        _waiting = false;
      });
      if (reply.isNotEmpty) TtsService.instance.speak(reply);
      _scrollDown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.remove(mine);
        _input.text = text;
        _waiting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'Connection lost. Try again.'))));
    }
  }

  Future<void> _askHint() async {
    setState(() => _hint = '…');
    try {
      final r = await RoleplayChatPage.chat([
        ..._history,
        {
          'role': 'user',
          'content': '(Out of character) Suggest ONE natural B1 French sentence I could say now to move towards my goal. '
              'Return JSON: {"suggestion": "..."}',
        },
      ], temperature: 0.7, maxTokens: 300);
      if (mounted) setState(() => _hint = '${r['suggestion'] ?? ''}'.trim());
    } catch (_) {
      if (mounted) setState(() => _hint = null);
    }
  }

  Future<void> _finish() async {
    final turns = _messages.where((m) => !m.fromAi).length;
    if (turns == 0) {
      Navigator.pop(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _Evaluation(history: _history, language: _language),
    );
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    return Scaffold(
      appBar: AppBar(
        title: Text('${s.emoji} ${s.title}'),
        actions: [TextButton(onPressed: _finish, child: Text(tr(context, 'Finish')))],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('🎯 '),
                Expanded(child: TranslatedText(s.goal, style: TextStyle(color: AppTheme.warning, fontSize: 13))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length + (_waiting ? 1 : 0) + (_done ? 1 : 0),
              itemBuilder: (context, i) {
                if (i < _messages.length) return Entrance(child: _bubble(_messages[i]));
                if (_waiting && i == _messages.length) return const _Typing();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: GlowButton(label: tr(context, 'See my evaluation'), icon: Icons.emoji_events_rounded, onPressed: _finish),
                );
              },
            ),
          ),
          if (_hint != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Text('💡 '),
                  Expanded(
                    child: Text(_hint!,
                        textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.textPrimary, fontStyle: FontStyle.italic)),
                  ),
                  if (_hint != '…')
                    TextButton(
                      onPressed: () => setState(() {
                        _input.text = _hint!;
                        _hint = null;
                      }),
                      child: Text(tr(context, 'Use')),
                    ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: tr(context, 'An idea?'),
                    onPressed: _waiting || _done ? null : _askHint,
                    icon: const Text('💡', style: TextStyle(fontSize: 22)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      enabled: !_done,
                      textDirection: TextDirection.ltr,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(hintText: tr(context, _listening ? "I'm listening… speak French" : 'Answer in French…')),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  if (SpeechInput.supported) ...[
                    const SizedBox(width: 6),
                    _listening
                        ? Floating(
                            distance: 3,
                            period: const Duration(milliseconds: 900),
                            child: IconButton.filled(
                              tooltip: tr(context, 'Stop'),
                              style: IconButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: AppTheme.onColor),
                              onPressed: _toggleMic,
                              icon: const Icon(Icons.mic_rounded),
                            ),
                          )
                        : IconButton.filledTonal(
                            tooltip: tr(context, 'Speak'),
                            onPressed: _waiting || _done ? null : _toggleMic,
                            icon: const Icon(Icons.mic_none_rounded),
                          ),
                  ],
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _waiting || _done ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_Message m) {
    final ai = m.fromAi;
    return Align(
      alignment: ai ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        child: Column(
          crossAxisAlignment: ai ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: ai
                      ? [AppTheme.surface, AppTheme.surfaceLight.withValues(alpha: 0.7)]
                      : [AppTheme.primary, AppTheme.accent],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(ai ? 4 : 20),
                  bottomRight: Radius.circular(ai ? 20 : 4),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: Text(m.text, style: TextStyle(color: ai ? AppTheme.textPrimary : AppTheme.onColor, fontSize: 16, height: 1.35))),
                        if (ai) ...[
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.volume_up_rounded, size: 18, color: AppTheme.primary),
                            onPressed: () => TtsService.instance.speak(m.text),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.translate_rounded, size: 18, color: AppTheme.textTertiary),
                            onPressed: () async {
                              if (m.translation != null) return setState(() => m.translation = null);
                              final lang = context.read<LanguageProvider>().currentLanguage.name;
                              final t = await DeepSeekService.translateText(m.text, lang);
                              if (mounted) setState(() => m.translation = t);
                            },
                          ),
                        ],
                      ],
                    ),
                    if (m.translation != null)
                      Directionality(
                        textDirection: Directionality.of(context),
                        child: Text(m.translation!, style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
                      ),
                  ],
                ),
              ),
            ),
            if (m.correction.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✏️ ${m.correction}',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)),
                    if (m.explanation.isNotEmpty)
                      Text(m.explanation, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) => const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Floating(distance: 3, period: Duration(milliseconds: 900), child: Text('💬 …', style: TextStyle(fontSize: 22))),
        ),
      );
}

/// Score and feedback at the end of a role-play.
class _Evaluation extends StatefulWidget {
  final List<Map<String, dynamic>> history;
  final String language;
  const _Evaluation({required this.history, required this.language});

  @override
  State<_Evaluation> createState() => _EvaluationState();
}

class _EvaluationState extends State<_Evaluation> {
  Map<String, dynamic>? _result;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _evaluate();
  }

  Future<void> _evaluate() async {
    try {
      final r = await RoleplayChatPage.chat([
        ...widget.history,
        {
          'role': 'user',
          'content': '(Out of character) The role-play is over. Evaluate MY French as a kind B1 teacher. '
              'Write "summary", "strengths" and the explanations in ${widget.language}; keep French examples in French. '
              'Return JSON: {"score": 0-10, "summary": "2 sentences", "strengths": ["..."], '
              '"phrases": [{"fr": "useful French sentence for this situation", "meaning": "..."}] (3 phrases)}',
        },
      ], temperature: 0.4, maxTokens: 1500);
      final score = (r['score'] as num?)?.round() ?? 0;
      ProgressService.instance.addXp(score);
      if (mounted) {
        setState(() => _result = r);
        if (score >= 7) Confetti.burst(context);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(24),
        children: [
          if (_failed)
            Text(tr(context, 'Evaluation not possible right now.'), style: TextStyle(color: AppTheme.error))
          else if (r == null)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else ...[
            Center(
              child: GoalRing(
                progress: ((r['score'] as num?) ?? 0) / 10,
                size: 130,
                center: Text('${(r['score'] as num?)?.round() ?? 0}/10',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
              ),
            ),
            const SizedBox(height: 16),
            Text('${r['summary'] ?? ''}', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, height: 1.4)),
            if ((r['strengths'] as List?)?.isNotEmpty ?? false) ...[
              const SectionTitle('👍'),
              for (final s in r['strengths'] as List)
                Text('• $s', style: TextStyle(color: AppTheme.success, height: 1.5)),
            ],
            if ((r['phrases'] as List?)?.isNotEmpty ?? false) ...[
              const SectionTitle('💬 Phrases utiles'),
              for (final p in r['phrases'] as List)
                if (p is Map)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${p['fr']}', textDirection: TextDirection.ltr, style: TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text('${p['meaning'] ?? ''}'),
                    trailing: IconButton(
                      icon: Icon(Icons.volume_up_rounded, color: AppTheme.primary),
                      onPressed: () => TtsService.instance.speak('${p['fr']}'),
                    ),
                  ),
            ],
            const SizedBox(height: 10),
            TranslatedText('Your corrected sentences were added to « My mistakes ».',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
