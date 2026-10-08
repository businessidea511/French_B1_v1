import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/data/exam_kit.dart';
import 'package:french_course_b1/pages/exam/exam_kit_page.dart';
import 'package:french_course_b1/pages/exam/writing_practice_page.dart';
import 'package:french_course_b1/services/exam_writing_service.dart';
import 'package:french_course_b1/services/practice_logic.dart';
import 'package:french_course_b1/services/progress_service.dart';
import 'package:french_course_b1/services/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget page) => ChangeNotifierProvider(create: (_) => LanguageProvider(), child: MaterialApp(home: page));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProgressService.instance.reset();
  });

  test('every blank of the game is in its phrase, with 4 different choices', () {
    for (final p in jokerPhrases) {
      for (final g in p.gaps) {
        final blank = p.withBlank(g);
        expect(blank, contains('___'), reason: '${g.answer} in ${p.french}');
        expect(blank.replaceFirst('___', g.answer), p.french);
        expect(g.wrong, isNot(contains(g.answer)));
        expect({g.answer, ...g.wrong.take(3)}, hasLength(4), reason: p.french);
      }
    }
    // "en" is found as a word (J'en), not inside another word.
    final enPhrase = jokerPhrases.firstWhere((p) => p.french.startsWith("J'en"));
    expect(enPhrase.withBlank(enPhrase.gaps.first), startsWith("J'___ ai parlé"));
  });

  test("today's dictation: 6 sentences, the same all day, new the next day", () {
    final monday = dailyDictation(DateTime(2026, 10, 12, 8));
    expect(monday, hasLength(6));
    expect(monday.toSet(), hasLength(6));
    expect(dailyDictation(DateTime(2026, 10, 12, 21)), monday);
    expect(dailyDictation(DateTime(2026, 10, 13)), isNot(monday));
    for (final s in [...examDictation, ...monday]) {
      expect(s, isNot(contains('(')));
      expect(Dictee.score(s, s), 100, reason: s);
    }
  });

  test('a correction is a mark out of 20 from 4 criteria', () async {
    ExamWritingService.chat = (messages, {thinking = false, temperature, maxTokens}) async {
      expect(messages.first['content'], contains('the subjonctif AND COD / COI'));
      expect(messages.first['content'], contains('Arabic'));
      return {
        'criteria': {'task': 4, 'grammar': '3', 'vocabulary': 4.4, 'organisation': 9},
        'summary': 'Bon texte.',
        'mistakes': [
          {'wrong': 'il faut que tu viens', 'right': 'il faut que tu viennes', 'why': 'subjonctif'},
          {'wrong': '', 'right': 'x'},
        ],
        'good': ['Je lui ai donné'],
        'better_version': 'Il faut que tu viennes.',
        'next_tip': 'Relis les verbes.',
      };
    };
    final f = await ExamWritingService.correct(examSubjects.first, 'Il faut que tu viens.', language: 'Arabic');
    expect(f.score, 4 + 3 + 4 + 5, reason: 'each criterion is kept between 0 and 5');
    expect(f.mistakes, hasLength(1));
    expect(ExamWritingService.wordCount("J'ai mangé une pomme aujourd'hui."), 5);
  });

  testWidgets('write a text, get the mark, mistakes go to the notebook', (tester) async {
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    ExamWritingService.chat = (messages, {thinking = false, temperature, maxTokens}) async => {
          'criteria': {'task': 4, 'grammar': 3, 'vocabulary': 4, 'organisation': 4},
          'summary': 'Bon texte.',
          'mistakes': [
            {'wrong': 'il faut que tu viens', 'right': 'il faut que tu viennes', 'why': 'il faut que + subjonctif'},
          ],
          'good': [],
          'better_version': 'Salut Karim ! Il faut que tu viennes.',
          'next_tip': '',
        };
    await tester.pumpWidget(_app(WritingEditorPage(subject: examSubjects.first)));
    await tester.pumpAndSettle();

    final text = List.filled(5, 'Salut Karim, il faut que tu viens en Belgique.').join(' ');
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Correct it like a teacher'));
    await tester.pumpAndSettle();

    expect(find.text('15 / 20'), findsOneWidget);
    expect(find.text('✅ il faut que tu viennes'), findsOneWidget);
    expect(ProgressService.instance.mistakes.first['source'], 'Rédaction');
    expect(await ExamWritingService.draft(examSubjects.first.id), text, reason: 'the text is kept');
  });

  testWidgets('the phrase game: right and wrong answers', (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(PhraseGamePage(random: Random(1))));
    await tester.pumpAndSettle();
    final q = PhraseQuestion.round(Random(1)).first;
    expect(find.text(q.phrase.withBlank(q.gap)), findsOneWidget);

    await tester.tap(find.text(q.gap.answer));
    await tester.pumpAndSettle();
    expect(find.text('⭐ 1'), findsOneWidget);
    expect(find.text(q.phrase.french), findsOneWidget, reason: 'the whole phrase is shown after answering');
  });
}
