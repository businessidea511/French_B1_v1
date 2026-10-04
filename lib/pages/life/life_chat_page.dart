import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/story_characters.dart';
import '../../services/deepseek_service.dart';
import '../../services/language_provider.dart';
import '../../services/life_story_service.dart';
import '../../services/speech_input.dart';
import '../../services/tts_service.dart';
import '../../services/ui_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';

/// A character's avatar: emoji on their colour.
class CharacterAvatar extends StatelessWidget {
  final StoryCharacter character;
  final double size;
  const CharacterAvatar(this.character, {super.key, this.size = 46});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Color(character.color), Color(character.color).withValues(alpha: 0.6)]),
          boxShadow: [BoxShadow(color: Color(character.color).withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Text(character.emoji, style: TextStyle(fontSize: size * 0.5)),
      );
}

/// Text-message conversation with one character of "Ma vie en Belgique".
class LifeChatPage extends StatefulWidget {
  final String characterId;
  const LifeChatPage({super.key, required this.characterId});

  @override
  State<LifeChatPage> createState() => _LifeChatPageState();
}

class _LifeChatPageState extends State<LifeChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _speech = SpeechInput();
  final Map<LifeMessage, String> _translations = {};
  bool _waiting = false;
  bool _listening = false;
  String _beforeVoice = '';
  String? _hint;

  LifeStoryService get _story => LifeStoryService.instance;
  StoryCharacter get _character => characterById(widget.characterId)!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _story.markRead(widget.characterId);
      _scrollDown(jump: true);
      final last = _story.thread(widget.characterId).lastOrNull;
      if (last != null && last.fromAi && last.day == _story.today) TtsService.instance.speak(last.text);
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      jump ? _scroll.jumpTo(end) : _scroll.animateTo(end, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    });
  }

  Future<void> _send() async {
    if (_listening) _speech.stop();
    final text = _input.text.trim();
    if (text.isEmpty || _waiting) return;
    final scene = _story.sceneFor(widget.characterId);
    final wasDone = scene?.done ?? true;
    setState(() {
      _waiting = true;
      _hint = null;
      _input.clear();
    });
    _scrollDown();
    try {
      final language = context.read<LanguageProvider>().currentLanguage.englishName;
      final answer = await _story.reply(widget.characterId, text, explanationLanguage: language);
      if (!mounted) return;
      setState(() => _waiting = false);
      TtsService.instance.speak(answer.text);
      _scrollDown();
      if (!wasDone && (scene?.done ?? false)) {
        Confetti.burst(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 ${tr(context, 'Scene complete! +10 XP')}')),
        );
      }
    } catch (e) {
      debugPrint('Story reply failed: $e');
      if (!mounted) return;
      setState(() {
        _waiting = false;
        _input.text = text;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'Connection lost. Try again.'))));
    }
  }

  Future<void> _askHint() async {
    setState(() => _hint = '…');
    try {
      final s = await _story.suggestion(widget.characterId);
      if (mounted) setState(() => _hint = s.isEmpty ? null : s);
    } catch (_) {
      if (mounted) setState(() => _hint = null);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    context.watch<LifeStoryService>();
    final c = _character;
    final messages = _story.thread(c.id);
    final scene = _story.sceneFor(c.id);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CharacterAvatar(c, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  TranslatedText(c.role, style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (scene != null) _SceneBanner(scene: scene),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
              itemCount: messages.length + (_waiting ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == messages.length) return const _Typing();
                final m = messages[i];
                final newDay = i == 0 || messages[i - 1].day != m.day;
                return Column(
                  children: [
                    if (newDay) _DayLabel(m.day == _story.today ? tr(context, 'Today') : m.day),
                    _bubble(m),
                  ],
                );
              },
            ),
          ),
          if (_hint != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Text('💡 '),
                  Expanded(
                    child: Text(_hint!,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: AppTheme.textPrimary, fontStyle: FontStyle.italic)),
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
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: tr(context, 'An idea?'),
                    onPressed: _waiting ? null : _askHint,
                    icon: const Text('💡', style: TextStyle(fontSize: 22)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textDirection: TextDirection.ltr,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                          hintText: tr(context, _listening ? "I'm listening… speak French" : 'Answer in French…')),
                    ),
                  ),
                  if (SpeechInput.supported) ...[
                    const SizedBox(width: 6),
                    _listening
                        ? IconButton.filled(
                            tooltip: tr(context, 'Stop'),
                            style: IconButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: AppTheme.onColor),
                            onPressed: _toggleMic,
                            icon: const Icon(Icons.mic_rounded),
                          )
                        : IconButton.filledTonal(
                            tooltip: tr(context, 'Speak'),
                            onPressed: _waiting ? null : _toggleMic,
                            icon: const Icon(Icons.mic_none_rounded),
                          ),
                  ],
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: tr(context, 'Send'),
                    onPressed: _waiting ? null : _send,
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

  Widget _bubble(LifeMessage m) {
    final ai = m.fromAi;
    final translation = _translations[m];
    return Align(
      alignment: ai ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        child: Column(
          crossAxisAlignment: ai ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              decoration: BoxDecoration(
                color: ai ? AppTheme.surface : null,
                gradient: ai ? null : LinearGradient(colors: [Color(_character.color), AppTheme.primary]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(m.text,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(color: ai ? AppTheme.textPrimary : AppTheme.onColor, fontSize: 16, height: 1.35)),
                      ),
                      if (ai) ...[
                        IconButton(
                          tooltip: tr(context, 'Listen'),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.volume_up_rounded, size: 18, color: AppTheme.primary),
                          onPressed: () => TtsService.instance.speak(m.text),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.translate_rounded, size: 18, color: AppTheme.textTertiary),
                          onPressed: () async {
                            if (translation != null) return setState(() => _translations.remove(m));
                            final lang = context.read<LanguageProvider>().currentLanguage.name;
                            final t = await DeepSeekService.translateText(m.text, lang);
                            if (mounted) setState(() => _translations[m] = t);
                          },
                        ),
                      ],
                      if (!ai) const SizedBox(width: 8),
                    ],
                  ),
                  if (translation != null) Text(translation, style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
                ],
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

/// Today's situation with this character: title, goal, grammar point, done or not.
class _SceneBanner extends StatelessWidget {
  final LifeScene scene;
  const _SceneBanner({required this.scene});

  @override
  Widget build(BuildContext context) {
    final color = scene.done ? AppTheme.success : AppTheme.warning;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(scene.done ? '✅ ' : '🎯 '),
              Expanded(
                child: Text(scene.title,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              ),
              if (scene.grammar.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Text(scene.grammar, style: TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          scene.done
              ? Text(tr(context, 'Done for today! You can keep chatting.'), style: TextStyle(color: color, fontSize: 13))
              : TranslatedText(scene.goal, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String text;
  const _DayLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.fg.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Text(text, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
          ),
        ),
      );
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) => const Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Floating(distance: 3, period: Duration(milliseconds: 900), child: Text('💬 …', style: TextStyle(fontSize: 22))),
        ),
      );
}
