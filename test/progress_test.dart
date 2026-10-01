import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:french_course_b1/data/missions_data.dart';
import 'package:french_course_b1/services/practice_logic.dart';
import 'package:french_course_b1/services/progress_service.dart';

void main() {
  late DateTime now;
  final p = ProgressService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 1, 10);
    ProgressService.clock = () => now;
    p.reset();
    await p.load();
  });

  test('streak, daily goal and weekly XP', () {
    p.addXp(10);
    now = now.add(const Duration(days: 1));
    expect(p.streak, 1, reason: 'yesterday still counts before practising today');
    p.addXp(25);
    expect(p.streak, 2);
    p.setDailyGoal(50);
    expect(p.goalProgress, 0.5);
    expect(p.lastWeekXp.sublist(5), [10, 25]);
    now = now.add(const Duration(days: 2));
    expect(p.streak, 0, reason: 'a missed day breaks the streak');
  });

  test('spaced repetition schedules known cards later and missed cards tomorrow', () {
    final card = {'front': 'la gare', 'back': 'train station'};
    p.recordCard(card, true);
    expect(p.dueCount, 0);
    now = now.add(const Duration(days: 1));
    expect(p.dueCount, 1);
    p.recordCard(card, true);
    expect(p.boxOf('la gare'), 2);
    now = now.add(const Duration(days: 2));
    expect(p.dueCount, 0);
    now = now.add(const Duration(days: 1));
    p.recordCard(card, false);
    expect(p.boxOf('la gare'), 1);
    now = now.add(const Duration(days: 1));
    expect(p.dueCards.single['back'], 'train station');
  });

  test('mistakes, records, missions and saved words', () {
    p.addMistake(source: 'Exercices', question: 'Je ___ (aller)', wrong: 'va', right: 'vais');
    p.addMistake(source: 'Exercices', question: 'Je ___ (aller)', wrong: 'allons', right: 'vais');
    expect(p.mistakes, hasLength(1), reason: 'same question is kept once');
    p.removeMistake(p.mistakes.first['id'] as String);
    expect(p.mistakes, isEmpty);

    expect(p.saveRecord('conj_Facile', 120), isTrue);
    expect(p.saveRecord('conj_Facile', 80), isFalse);
    expect(p.recordOf('conj_Facile'), 120);

    p.toggleMission('pain');
    expect(p.missionDone('pain'), isTrue);
    expect(p.todayXp, 15);
    expect(missionsOfWeek(DateTime(2026, 9, 28)), hasLength(3));

    p.saveWords([{'front': 'le frigo', 'back': 'fridge'}]);
    expect(p.savedWords.single['front'], 'le frigo');
    expect(p.dueCards.map((c) => c['front']), contains('le frigo'));
  });

  test('conjugation game questions can be answered with their own answer', () {
    final random = Random(1);
    for (final level in ConjugationQuiz.levels.keys) {
      for (var i = 0; i < 40; i++) {
        final q = ConjugationQuiz.make(random, level);
        expect(ConjugationQuiz.check(q.answer, q.answer), AnswerResult.correct, reason: q.fullForm);
        expect(q.prefix, isNot(contains('/')));
      }
    }
  });

  test('conjugation answers accept agreement and flag accents', () {
    expect(ConjugationQuiz.check('suis allée', 'suis allé(e)'), AnswerResult.correct);
    expect(ConjugationQuiz.check('sommes alles', 'sommes allé(e)s'), AnswerResult.accents);
    expect(ConjugationQuiz.check('Préfère', 'préfère'), AnswerResult.correct);
    expect(ConjugationQuiz.check('prefere', 'préfère'), AnswerResult.accents);
    expect(ConjugationQuiz.check('préférons', 'préfère'), AnswerResult.wrong);
  });

  test('dictée marks missing words and accent mistakes', () {
    final marks = Dictee.compare('je suis tres fatigue', 'Je suis très fatigué ce soir.');
    expect([for (final w in marks) w.mark], [
      WordMark.ok, WordMark.ok, WordMark.accent, WordMark.accent, WordMark.missing, WordMark.missing,
    ]);
    expect(Dictee.score('Je suis très fatigué ce soir.', 'Je suis très fatigué ce soir.'), 100);
    expect(Dictee.score('', 'Bonjour.'), 0);
    expect(Dictee.sentences('Facile', Random(2)), isNotEmpty);
    expect(Dictee.sentences('Difficile', Random(2)), isNotEmpty);
  });

  test('word of the day changes every day', () {
    final a = WordOfTheDay.forDay(DateTime(2026, 10, 1));
    final b = WordOfTheDay.forDay(DateTime(2026, 10, 2));
    expect(a.fr, isNot(b.fr));
    expect(WordOfTheDay.forDay(DateTime(2026, 10, 1, 22)).fr, a.fr);
  });
}
