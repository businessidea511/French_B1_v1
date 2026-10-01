import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything the learner has done, saved on this device: XP per day (streak
/// and daily goal), flashcards scheduled for review (spaced repetition), the
/// mistakes notebook, game records, weekly missions and words saved from photos.
class ProgressService extends ChangeNotifier {
  static final ProgressService instance = ProgressService();

  /// Replaceable in tests.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  static const String _prefKey = 'progress_v1';

  /// Days until the next review for each box. A card goes up one box each
  /// time it is known, and back to box 1 when it is missed.
  static const List<int> intervals = [0, 1, 3, 7, 14, 30, 60];

  static const int maxMistakes = 300;
  static const int maxReviewCards = 1500;

  bool _loaded = false;
  Map<String, int> _dailyXp = {};
  int dailyGoal = 30;
  bool onboarded = false;
  Map<String, Map<String, dynamic>> _reviews = {};
  List<Map<String, dynamic>> _mistakes = [];
  Map<String, int> _records = {};
  Map<String, List<String>> _missions = {};
  List<Map<String, String>> _savedWords = [];

  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) _fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (e) {
      debugPrint('Could not load progress: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  /// Forgets everything loaded (tests only).
  @visibleForTesting
  void reset() {
    _loaded = false;
    _dailyXp = {};
    dailyGoal = 30;
    onboarded = false;
    _reviews = {};
    _mistakes = [];
    _records = {};
    _missions = {};
    _savedWords = [];
  }

  void _fromJson(Map<String, dynamic> j) {
    _dailyXp = Map<String, int>.from(j['xp'] as Map? ?? const {});
    dailyGoal = (j['goal'] as num?)?.toInt() ?? 30;
    onboarded = j['onboarded'] == true;
    _reviews = {
      for (final e in (j['reviews'] as Map? ?? const {}).entries) '${e.key}': Map<String, dynamic>.from(e.value as Map)
    };
    _mistakes = [for (final m in (j['mistakes'] as List? ?? const [])) Map<String, dynamic>.from(m as Map)];
    _records = Map<String, int>.from(j['records'] as Map? ?? const {});
    _missions = {
      for (final e in (j['missions'] as Map? ?? const {}).entries) '${e.key}': List<String>.from(e.value as List)
    };
    _savedWords = [for (final w in (j['saved_words'] as List? ?? const [])) Map<String, String>.from(w as Map)];
  }

  Map<String, dynamic> _toJson() => {
        'xp': _dailyXp,
        'goal': dailyGoal,
        'onboarded': onboarded,
        'reviews': _reviews,
        'mistakes': _mistakes,
        'records': _records,
        'missions': _missions,
        'saved_words': _savedWords,
      };

  Future<void> _save() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(_toJson()));
    } catch (e) {
      debugPrint('Could not save progress: $e');
    }
  }

  // ── Days, XP, streak ───────────────────────────────────────────────────────

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _today() {
    final n = clock();
    return DateTime(n.year, n.month, n.day);
  }

  int get todayXp => _dailyXp[dayKey(_today())] ?? 0;
  int get totalXp => _dailyXp.values.fold(0, (a, b) => a + b);
  int get activeDays => _dailyXp.values.where((x) => x > 0).length;
  double get goalProgress => dailyGoal <= 0 ? 1 : (todayXp / dailyGoal).clamp(0.0, 1.0);

  /// XP of the last 7 days, oldest first.
  List<int> get lastWeekXp {
    final today = _today();
    return [for (var i = 6; i >= 0; i--) _dailyXp[dayKey(today.subtract(Duration(days: i)))] ?? 0];
  }

  /// Days in a row with some practice. Today counts once practised; until
  /// then the streak from yesterday is still alive.
  int get streak {
    var day = _today();
    if ((_dailyXp[dayKey(day)] ?? 0) == 0) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while ((_dailyXp[dayKey(day)] ?? 0) > 0) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  void addXp(int amount) {
    if (amount <= 0) return;
    final key = dayKey(_today());
    _dailyXp[key] = (_dailyXp[key] ?? 0) + amount;
    _save();
  }

  void setDailyGoal(int goal) {
    dailyGoal = goal;
    _save();
  }

  void completeOnboarding() {
    onboarded = true;
    _save();
  }

  // ── Spaced repetition ──────────────────────────────────────────────────────

  /// Records an answer to a flashcard and schedules its next review.
  void recordCard(Map<String, String> card, bool knewIt) {
    final front = (card['front'] ?? '').trim();
    if (front.isEmpty) return;
    final old = _reviews[front];
    final box = knewIt ? ((old?['box'] as int? ?? 0) + 1).clamp(1, intervals.length - 1) : 1;
    final due = _today().add(Duration(days: knewIt ? intervals[box] : 1));
    _reviews[front] = {'card': Map<String, String>.from(card), 'box': box, 'due': dayKey(due)};
    if (_reviews.length > maxReviewCards) {
      // Drop the best-known cards first.
      final keys = _reviews.keys.toList()
        ..sort((a, b) => (_reviews[b]!['box'] as int).compareTo(_reviews[a]!['box'] as int));
      for (final k in keys.take(_reviews.length - maxReviewCards)) {
        _reviews.remove(k);
      }
    }
    addXp(knewIt ? 2 : 1);
  }

  bool inReviews(String front) => _reviews.containsKey(front.trim());

  /// Adds a card to the reviews, due today, unless it is already there.
  void addToReviews(Map<String, String> card) {
    final front = (card['front'] ?? '').trim();
    if (front.isEmpty || _reviews.containsKey(front)) return;
    _reviews[front] = {'card': Map<String, String>.from(card), 'box': 0, 'due': dayKey(_today())};
    _save();
  }

  /// Cards whose review day has come.
  List<Map<String, String>> get dueCards {
    final today = dayKey(_today());
    final due = _reviews.values.where((r) => (r['due'] as String).compareTo(today) <= 0).toList()
      ..sort((a, b) => (a['due'] as String).compareTo(b['due'] as String));
    return [for (final r in due) Map<String, String>.from(r['card'] as Map)];
  }

  int get dueCount => dueCards.length;
  int get reviewCardCount => _reviews.length;

  /// Cards known at least three times in a row.
  int get learnedCount => _reviews.values.where((r) => (r['box'] as int) >= 3).length;

  int? boxOf(String front) => _reviews[front.trim()]?['box'] as int?;

  // ── Mistakes notebook ──────────────────────────────────────────────────────

  List<Map<String, dynamic>> get mistakes => List.unmodifiable(_mistakes);

  void addMistake({
    required String source,
    required String question,
    required String wrong,
    required String right,
    String explanation = '',
    List<String> options = const [],
  }) {
    if (question.trim().isEmpty || right.trim().isEmpty) return;
    _mistakes.removeWhere((m) => m['question'] == question && m['right'] == right);
    _mistakes.insert(0, {
      'id': '${clock().microsecondsSinceEpoch}',
      'source': source,
      'question': question,
      'wrong': wrong,
      'right': right,
      'explanation': explanation,
      'options': options,
      'date': dayKey(_today()),
    });
    if (_mistakes.length > maxMistakes) _mistakes.removeRange(maxMistakes, _mistakes.length);
    _save();
  }

  void removeMistake(String id) {
    _mistakes.removeWhere((m) => m['id'] == id);
    _save();
  }

  // ── Game records ───────────────────────────────────────────────────────────

  int recordOf(String game) => _records[game] ?? 0;

  /// Saves [score] if it beats the record. Returns true for a new record.
  bool saveRecord(String game, int score) {
    if (score <= recordOf(game)) return false;
    _records[game] = score;
    _save();
    return true;
  }

  // ── Weekly missions ────────────────────────────────────────────────────────

  /// Monday of the current week, e.g. "2026-09-28".
  static String weekKey([DateTime? date]) {
    final d = date ?? _today();
    return dayKey(DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1)));
  }

  bool missionDone(String id) => _missions[weekKey()]?.contains(id) ?? false;

  void toggleMission(String id) {
    final week = _missions.putIfAbsent(weekKey(), () => []);
    if (week.contains(id)) {
      week.remove(id);
    } else {
      week.add(id);
      addXp(15);
      return;
    }
    _save();
  }

  // ── Words saved from photos ────────────────────────────────────────────────

  List<Map<String, String>> get savedWords => List.unmodifiable(_savedWords);

  void saveWords(List<Map<String, String>> words) {
    for (final w in words) {
      if (_savedWords.any((s) => s['front'] == w['front'])) continue;
      _savedWords.insert(0, w);
      final front = (w['front'] ?? '').trim();
      if (front.isNotEmpty && !_reviews.containsKey(front)) {
        _reviews[front] = {'card': w, 'box': 0, 'due': dayKey(_today())};
      }
    }
    _save();
  }

  void removeSavedWord(String front) {
    _savedWords.removeWhere((w) => w['front'] == front);
    _save();
  }
}
