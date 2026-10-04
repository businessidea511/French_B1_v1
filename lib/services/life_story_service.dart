import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/story_characters.dart';
import 'deepseek_service.dart';
import 'progress_service.dart';

/// One message in a conversation with a character.
class LifeMessage {
  final bool fromAi;
  final String text;
  String correction; // the corrected sentence when there were mistakes
  String explanation; // why, in the learner's language
  String better; // when it was already correct: a more natural way to say it
  bool checked; // the learner's message was checked (correct when [correction] is empty)
  final String day; // yyyy-mm-dd

  LifeMessage(this.fromAi, this.text, this.day,
      {this.correction = '', this.explanation = '', this.better = '', this.checked = false});

  Map<String, dynamic> toJson() => {
        'ai': fromAi,
        't': text,
        'd': day,
        if (correction.isNotEmpty) 'c': correction,
        if (explanation.isNotEmpty) 'e': explanation,
        if (better.isNotEmpty) 'b': better,
        if (checked) 'k': true,
      };

  static LifeMessage fromJson(Map j) =>
      LifeMessage(j['ai'] == true, '${j['t'] ?? ''}', '${j['d'] ?? ''}',
          correction: '${j['c'] ?? ''}',
          explanation: '${j['e'] ?? ''}',
          better: '${j['b'] ?? ''}',
          checked: j['k'] == true);
}

/// Today's situation with one character: what happens and what the learner must do.
class LifeScene {
  final String characterId;
  final String title; // French, e.g. "Le colis de Madame Dubois"
  final String situation; // English, for the AI
  final String goal; // English, shown translated to the learner
  final String grammar; // French grammar point the scene practises, e.g. "passé composé"
  bool done;
  int replies;

  LifeScene(this.characterId, this.title, this.situation, this.goal, this.grammar, {this.done = false, this.replies = 0});

  Map<String, dynamic> toJson() => {
        'c': characterId,
        'title': title,
        'situation': situation,
        'goal': goal,
        'grammar': grammar,
        'done': done,
        'replies': replies,
      };

  static LifeScene fromJson(Map j) => LifeScene(
        '${j['c']}',
        '${j['title'] ?? ''}',
        '${j['situation'] ?? ''}',
        '${j['goal'] ?? ''}',
        '${j['grammar'] ?? ''}',
        done: j['done'] == true,
        replies: (j['replies'] as num?)?.toInt() ?? 0,
      );
}

/// "Ma vie en Belgique": the learner's interactive story. Characters write
/// every day, remember what the learner said, and each day brings new
/// situations that need French to move forward. Saved on this device.
class LifeStoryService extends ChangeNotifier {
  static final LifeStoryService instance = LifeStoryService();
  static const _prefKey = 'life_story_v1';

  /// Minutes a day → scenes a day.
  static const minuteOptions = [5, 10, 20];
  static int scenesFor(int minutes) => minutes <= 5 ? 1 : (minutes <= 10 ? 2 : 4);

  /// Learner replies that complete a scene even if the character does not close it.
  static int repliesFor(int minutes) => minutes <= 5 ? 4 : 5;

  /// The AI call. Tests replace it with a fake.
  @visibleForTesting
  static Future<Map<String, dynamic>> Function(
    List<Map<String, dynamic>> messages, {
    bool thinking,
    double? temperature,
    int? maxTokens,
  }) chat = DeepSeekService.chatJson;

  // Profile
  bool setUp = false;
  String firstName = '';
  String city = 'Bruxelles';
  String about = ''; // the learner's own words: job, family, why French
  int minutes = 10;
  List<String> characters = [for (final c in storyCharacters) c.id];

  // Story
  final Map<String, List<LifeMessage>> threads = {};
  final Map<String, List<String>> memory = {}; // what each character knows about the learner
  final Map<String, int> unread = {};
  String planDay = '';
  List<LifeScene> scenes = [];
  bool planning = false;
  String? planError;

  String get today => ProgressService.dayKey(ProgressService.now());

  int get unreadTotal => [for (final id in characters) unread[id] ?? 0].fold(0, (a, b) => a + b);
  int get scenesDone => scenes.where((s) => s.done).length;

  LifeScene? sceneFor(String characterId) {
    for (final s in scenes) {
      if (s.characterId == characterId && planDay == today) return s;
    }
    return null;
  }

  List<LifeMessage> thread(String id) => threads.putIfAbsent(id, () => []);

  // ── Saving ─────────────────────────────────────────────────────────────────

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Could not load the story: $e');
    }
    notifyListeners();
  }

  void reset() {
    setUp = false;
    firstName = '';
    city = 'Bruxelles';
    about = '';
    minutes = 10;
    characters = [for (final c in storyCharacters) c.id];
    threads.clear();
    memory.clear();
    unread.clear();
    planDay = '';
    scenes = [];
    planning = false;
    planError = null;
  }

  void _fromJson(Map<String, dynamic> j) {
    setUp = j['setUp'] == true;
    firstName = '${j['firstName'] ?? ''}';
    city = '${j['city'] ?? 'Bruxelles'}';
    about = '${j['about'] ?? ''}';
    minutes = (j['minutes'] as num?)?.toInt() ?? 10;
    characters = [for (final c in (j['characters'] as List? ?? const [])) '$c'];
    (j['threads'] as Map? ?? const {}).forEach((k, v) {
      threads['$k'] = [for (final m in (v as List)) LifeMessage.fromJson(m as Map)];
    });
    (j['memory'] as Map? ?? const {}).forEach((k, v) => memory['$k'] = [for (final m in (v as List)) '$m']);
    (j['unread'] as Map? ?? const {}).forEach((k, v) => unread['$k'] = (v as num).toInt());
    planDay = '${j['planDay'] ?? ''}';
    scenes = [for (final s in (j['scenes'] as List? ?? const [])) LifeScene.fromJson(s as Map)];
  }

  Map<String, dynamic> _toJson() => {
        'setUp': setUp,
        'firstName': firstName,
        'city': city,
        'about': about,
        'minutes': minutes,
        'characters': characters,
        // Keep the last 80 messages per character: enough context, small storage.
        'threads': {for (final e in threads.entries) e.key: [for (final m in e.value.skip(e.value.length > 80 ? e.value.length - 80 : 0)) m.toJson()]},
        'memory': memory,
        'unread': unread,
        'planDay': planDay,
        'scenes': [for (final s in scenes) s.toJson()],
      };

  Future<void> _save() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(_toJson()));
    } catch (e) {
      debugPrint('Could not save the story: $e');
    }
  }

  // ── Setup ──────────────────────────────────────────────────────────────────

  Future<void> configure({
    required String firstName,
    required String city,
    required String about,
    required int minutes,
    required List<String> characters,
  }) async {
    final changedCast = characters.toSet().difference(this.characters.toSet()).isNotEmpty ||
        this.characters.toSet().difference(characters.toSet()).isNotEmpty ||
        minutes != this.minutes;
    this.firstName = firstName.trim();
    this.city = city;
    this.about = about.trim();
    this.minutes = minutes;
    this.characters = characters;
    setUp = true;
    // New cast or time: today's plan is made again (conversations are kept).
    if (changedCast && planDay == today && scenesDone == 0) planDay = '';
    await _save();
  }

  // ── The day's plan ─────────────────────────────────────────────────────────

  /// Makes today's scenes once a day; each chosen character starts a conversation.
  Future<void> ensureToday() async {
    if (!setUp || planning || planDay == today || characters.isEmpty) return;
    planning = true;
    planError = null;
    notifyListeners();
    try {
      final count = scenesFor(minutes).clamp(1, characters.length);
      final cast = [for (final id in characters) characterById(id)].whereType<StoryCharacter>().toList();
      final mistakes = ProgressService.instance.mistakes.take(6).map((m) => '${m['wrong']} → ${m['right']}').join('; ');
      final words = ProgressService.instance.savedWords.reversed.take(10).map((w) => w['front']).join(', ');
      final result = await chat([
        {
          'role': 'system',
          'content': '''You are the writer of "Ma vie en Belgique", an interactive daily story that helps a B1 learner of French live their real life in Belgium.
THE LEARNER: ${firstName.isEmpty ? 'the learner' : firstName}, lives in $city. About them: ${about.isEmpty ? 'unknown yet' : about}
CHARACTERS (write only for these):
${[for (final c in cast) '- ${c.id}: ${c.name}, ${c.role}. ${c.persona}\n  Remembers: ${(memory[c.id] ?? const []).join(' | ')}'].join('\n')}
RECENT LEARNER MISTAKES (practise these points if natural): ${mistakes.isEmpty ? 'none yet' : mistakes}
WORDS THE LEARNER SAVED (reuse some if natural): ${words.isEmpty ? 'none yet' : words}

Write today's $count scene(s), each with a DIFFERENT character, as the next episode of an ongoing story:
- Continue what the characters remember (follow up on past events: "Alors, ce rendez-vous ?").
- Everyday, realistic Belgian situations: small problems, favours, invitations, news, plans, admin, the French course.
- Belgian words only where they are correct and natural (never forced). Write clock times, prices and dates with DIGITS: "à 19 h 30", "12 €", "le 5 octobre". Never write a time in words: "septante" means the number 70 (not 7 o'clock), "nonante" means 90.
- Each scene needs the learner to DO something in French (answer, explain, ask, accept/refuse, tell a story, give an opinion).
- "grammar": the B1 grammar point the scene makes the learner use (e.g. "passé composé", "futur proche", "subjonctif", "conditionnel", "pronoms COD/COI", "imparfait").
- "opening": the character's first message, 1–3 short natural French sentences (as a text message), using "tu" or "vous" like the character does, ending with a question.
- "title": short French title. "situation": English, what is going on (for the actor). "goal": English, what the learner must achieve, one short sentence.
JSON: {"scenes": [{"character": "<id>", "title": "...", "situation": "...", "goal": "...", "grammar": "...", "opening": "..."}]}'''
        },
        {'role': 'user', 'content': 'Write today\'s episode (${ProgressService.now().weekday == 6 || ProgressService.now().weekday == 7 ? 'weekend' : 'weekday'}).'},
      ], temperature: 0.9);

      final made = <LifeScene>[];
      for (final raw in (result['scenes'] as List? ?? const [])) {
        if (raw is! Map) continue;
        final id = '${raw['character'] ?? ''}';
        final opening = '${raw['opening'] ?? ''}'.trim();
        if (!characters.contains(id) || opening.isEmpty || made.any((s) => s.characterId == id)) continue;
        made.add(LifeScene(id, '${raw['title'] ?? ''}', '${raw['situation'] ?? ''}', '${raw['goal'] ?? ''}', '${raw['grammar'] ?? ''}'));
        thread(id).add(LifeMessage(true, opening, today));
        unread[id] = (unread[id] ?? 0) + 1;
        if (made.length >= count) break;
      }
      if (made.isEmpty) throw Exception('no scene');
      scenes = made;
      planDay = today;
    } catch (e) {
      debugPrint('Story plan failed: $e');
      planError = 'Your characters could not write today. Check the connection and try again.';
    } finally {
      planning = false;
      await _save();
    }
  }

  void markRead(String id) {
    if ((unread[id] ?? 0) == 0) return;
    unread[id] = 0;
    _save();
  }

  // ── Conversation ───────────────────────────────────────────────────────────

  String _system(StoryCharacter c, LifeScene? scene, String explanationLanguage) => '''You are ${c.name} in "Ma vie en Belgique", a daily story in French with a B1 learner.
WHO YOU ARE: ${c.persona}
YOU ARE TALKING TO: ${firstName.isEmpty ? 'the learner' : firstName}, who lives in $city. About them: ${about.isEmpty ? 'unknown yet' : about}
WHAT YOU REMEMBER ABOUT THEM: ${(memory[c.id] ?? const []).join(' | ')}
${scene == null || scene.done ? 'TODAY: free chat — talk naturally about their day or your news.' : 'TODAY\'S SITUATION: ${scene.situation}\nTHE LEARNER\'S GOAL: ${scene.goal}\nMake them use: ${scene.grammar}.'}
RULES
- This is a chat by text message: 1 to 3 short natural sentences, ${c.usesTu ? '"tu"' : '"vous"'}, B1 French, real Belgian life.
- Belgian words only where they are correct and natural (never forced). Write clock times, prices and dates with DIGITS: "à 19 h 30", "12 €", "le 5 octobre". Never write a time in words: "septante" means the number 70 (not 7 o'clock), "nonante" means 90.
- React to exactly what they say; ask follow-up questions so they must write more French.
- Never write another language than French in "reply".
- They may write by voice (speech-to-text): ignore missing punctuation and capitals.
- When the goal is clearly reached, close this topic warmly and set "goal_done": true.
CHECK their LAST message only (ignore punctuation and capitals):
- If it has French mistakes (grammar, spelling, agreement, wrong word, word order): "correct" = false, "correction" = the whole corrected sentence (keep their meaning, minimal changes), "explanation" = what was wrong and the rule, short, in $explanationLanguage.
- If it is correct: "correct" = true, "correction" = "", and "better" = a more natural or richer way a native would say it (or "" if it is already natural), "explanation" = a short note in $explanationLanguage on what was good or what "better" changes (or "").
MEMORY: in "remember", list 0–2 NEW short facts worth remembering about the learner or what was agreed (English), e.g. "has a job interview on Friday".
Return JSON: {"reply": "...", "correct": true, "correction": "", "better": "", "explanation": "", "goal_done": false, "remember": []}''';

  /// Sends the learner's message and returns the character's answer (also added to the thread).
  Future<LifeMessage> reply(String characterId, String text, {required String explanationLanguage}) async {
    final c = characterById(characterId)!;
    final scene = sceneFor(characterId);
    final mine = LifeMessage(false, text.trim(), today);
    final history = thread(characterId);
    final recent = history.skip(history.length > 30 ? history.length - 30 : 0);
    final r = await chat([
      {'role': 'system', 'content': _system(c, scene, explanationLanguage)},
      for (final m in recent) {'role': m.fromAi ? 'assistant' : 'user', 'content': m.text},
      {'role': 'user', 'content': mine.text},
    ], temperature: 0.8, maxTokens: 900);

    final answer = LifeMessage(true, '${r['reply'] ?? ''}'.trim(), today);
    if (answer.text.isEmpty) throw Exception('empty reply');
    final correction = '${r['correction'] ?? ''}'.trim();
    mine.checked = true;
    mine.explanation = '${r['explanation'] ?? ''}'.trim();
    if (correction.isEmpty || _same(correction, mine.text)) {
      final better = '${r['better'] ?? ''}'.trim();
      if (better.isNotEmpty && !_same(better, mine.text)) mine.better = better;
    } else {
      mine.correction = correction;
      ProgressService.instance.addMistake(
        source: 'Ma vie',
        question: '${c.emoji} ${c.name}${scene == null ? '' : ' · ${scene.title}'}',
        wrong: mine.text,
        right: mine.correction,
        explanation: mine.explanation,
      );
    }
    history
      ..add(mine)
      ..add(answer);
    final facts = [for (final f in (r['remember'] as List? ?? const [])) '$f'.trim()].where((f) => f.isNotEmpty);
    if (facts.isNotEmpty) {
      final known = memory.putIfAbsent(characterId, () => []);
      known.addAll(facts);
      if (known.length > 20) known.removeRange(0, known.length - 20);
    }
    ProgressService.instance.addXp(3);
    if (scene != null && !scene.done) {
      scene.replies++;
      if (r['goal_done'] == true || scene.replies >= repliesFor(minutes)) {
        scene.done = true;
        ProgressService.instance.addXp(10);
      }
    }
    await _save();
    return answer;
  }

  /// Equal apart from punctuation, capitals and spaces (voice input has none).
  static bool _same(String a, String b) {
    String n(String s) => s.toLowerCase().replaceAll(RegExp(r"[\s.,!?;:'’«»\-]+"), '');
    return n(a) == n(b);
  }

  final Map<String, String> _translated = {};

  /// Translates a message of the story into the learner's language. Chat
  /// messages are new every time, so they go straight to the AI.
  Future<String> translate(String french, String language) async {
    final key = '$language|$french';
    final known = _translated[key];
    if (known != null) return known;
    final r = await chat([
      {
        'role': 'system',
        'content': 'Translate the French chat message into $language. Natural, faithful, same tone. '
            'Return JSON: {"translation": "..."}',
      },
      {'role': 'user', 'content': french},
    ], temperature: 0.2, maxTokens: 600);
    final t = '${r['translation'] ?? ''}'.trim();
    if (t.isEmpty) throw Exception('empty translation');
    return _translated[key] = t;
  }

  /// One natural sentence the learner could write now (the 💡 button).
  Future<String> suggestion(String characterId) async {
    final c = characterById(characterId)!;
    final history = thread(characterId);
    final recent = history.skip(history.length > 12 ? history.length - 12 : 0);
    final r = await chat([
      {'role': 'system', 'content': _system(c, sceneFor(characterId), 'English')},
      for (final m in recent) {'role': m.fromAi ? 'assistant' : 'user', 'content': m.text},
      {
        'role': 'user',
        'content': '(Out of the story) Suggest ONE natural B1 French sentence I could write now. Return JSON: {"suggestion": "..."}',
      },
    ], temperature: 0.7, maxTokens: 300);
    return '${r['suggestion'] ?? ''}'.trim();
  }
}
