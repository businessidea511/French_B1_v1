import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:french_course_b1/data/roleplay_scenarios.dart';
import 'package:french_course_b1/pages/games/conjugation_game_page.dart';
import 'package:french_course_b1/pages/games/duel_page.dart';
import 'package:french_course_b1/pages/home_page.dart';
import 'package:french_course_b1/pages/mistakes/mistakes_page.dart';
import 'package:french_course_b1/pages/roleplay/roleplay_page.dart';
import 'package:french_course_b1/services/duel_questions.dart';
import 'package:french_course_b1/services/language_provider.dart';
import 'package:french_course_b1/services/lessons_provider.dart';
import 'package:french_course_b1/services/progress_service.dart';
import 'package:french_course_b1/theme/app_theme.dart';
import 'package:french_course_b1/widgets/exercise_block.dart';

/// Animations here loop forever, so pump a fixed time instead of settling.
Future<void> _settle(WidgetTester tester, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1100, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => LessonsProvider()),
      ChangeNotifierProvider.value(value: ProgressService.instance),
      ChangeNotifierProvider(create: (_) => ThemeController()),
    ],
    child: MaterialApp(home: page),
  ));
  await _settle(tester);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'selected_language': 'en'});
    ProgressService.clock = DateTime.now;
    ProgressService.instance.reset();
    await ProgressService.instance.load();
  });

  testWidgets('first start shows the welcome, then the tabs', (tester) async {
    await _pump(tester, const HomePage());
    await tester.tap(find.text('Start'));
    await _settle(tester);
    await tester.tap(find.text('English'));
    await _settle(tester);
    await tester.tap(find.text('Regular'));
    await _settle(tester, 2500);

    expect(ProgressService.instance.onboarded, isTrue);
    expect(ProgressService.instance.dailyGoal, 30);
    expect(find.text('Daily goal'), findsOneWidget);

    await tester.tap(find.text('Practise'));
    await _settle(tester);
    expect(find.text('Conjugation game'), findsOneWidget);
    await tester.tap(find.text('Words'));
    await _settle(tester);
    expect(find.text('Street French'), findsOneWidget);
    await tester.tap(find.text('Me'));
    await _settle(tester);
    expect(find.text('Level 1'), findsOneWidget);
  });

  testWidgets('a wrong conjugation goes to the mistakes notebook', (tester) async {
    await _pump(tester, const ConjugationGamePage());
    await tester.tap(find.text('Play!'));
    await _settle(tester, 800);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.tap(find.text('Check'));
    await _settle(tester);
    expect(find.text('❌'), findsOneWidget);
    expect(ProgressService.instance.mistakes.single['source'], 'Conjugaison');
    expect(ProgressService.instance.mistakes.single['wrong'], 'zzz');
  });

  testWidgets('role-play shows the correction and saves it', (tester) async {
    RoleplayChatPage.chat = (messages, {thinking = false, temperature, maxTokens}) async => {
          'reply': 'Très bien. Vous avez votre carte d\'identité ?',
          'correction': 'Je voudrais changer mon adresse.',
          'explanation': 'Use « voudrais ».',
          'done': false,
        };
    await _pump(tester, RoleplayChatPage(scenario: scenarios.first));
    await tester.enterText(find.byType(TextField), 'Je veux changer mon adresse');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await _settle(tester);
    expect(find.text('✏️ Je voudrais changer mon adresse.'), findsOneWidget);
    expect(find.textContaining('carte d\'identité'), findsOneWidget);
    expect(ProgressService.instance.mistakes.single['source'], 'Jeu de rôle');
  });

  testWidgets('mistakes can be practised as a quiz', (tester) async {
    ProgressService.instance.addMistake(
      source: 'Exercices',
      question: 'Je ___ au marché.',
      wrong: 'va',
      right: 'vais',
      options: ['vais', 'va', 'allons'],
    );
    await _pump(tester, const MistakesPage());
    expect(find.text('Je ___ au marché.'), findsOneWidget);
    await tester.tap(find.textContaining('Fix my mistakes'));
    await _settle(tester);
    expect(find.byType(ExerciseBlock), findsOneWidget);
  });

  test('both duel players get the same valid questions', () {
    final a = duelQuestions('ABC234');
    final b = duelQuestions('ABC234');
    expect(a, hasLength(10));
    expect([for (final q in a) q.prompt], [for (final q in b) q.prompt]);
    for (final q in a) {
      expect(q.correct, inInclusiveRange(0, q.options.length - 1));
      expect(q.options.toSet(), hasLength(q.options.length), reason: 'no duplicate options in ${q.prompt}');
    }
    expect(duelQuestions('ZZZ999').map((q) => q.prompt), isNot([for (final q in a) q.prompt]));
  });

  testWidgets('a duel sends the score and shows the board', (tester) async {
    // An older duel: the server has no saved questions, so they come from the code.
    DuelPage.send = (body) async => {'duel': null};
    final sent = <Map<String, dynamic>>[];
    DuelPage.api = (body) async {
      sent.add(body);
      return [
        {'name': 'Sara', 'score': 900, 'correct': 9, 'seconds': 40},
      ];
    };
    await _pump(tester, const DuelPage());
    await tester.enterText(find.byType(TextField).first, 'Sara');
    await tester.enterText(find.byType(TextField).last, 'ABC234');
    await tester.tap(find.text('Join'));
    await _settle(tester);
    for (var i = 0; i < 10; i++) {
      final q = duelQuestions('ABC234')[i];
      await tester.tap(find.text(q.options[q.correct]).last);
      await _settle(tester, 2500);
    }
    await _settle(tester);
    expect(sent.single['action'], 'submit');
    expect(sent.single['correct'], 10);
    expect(find.text('Sara'), findsOneWidget);
  });

  testWidgets('the creator chooses grammar topics and the number of questions', (tester) async {
    DuelBuilder.chat = (messages, {thinking = false, temperature, maxTokens}) async => {
          'questions': [
            for (var i = 0; i < 6; i++)
              {
                'topic': 'Grammaire',
                'level': 3 - i % 3,
                'prompt': 'Il faut que tu ___ ($i).',
                'options': ['sois', 'es', 'seras', 'étais'],
                'correct': 0,
              },
          ],
        };
    final created = <Map<String, dynamic>>[];
    DuelPage.send = (body) async {
      created.add(body);
      return {'ok': true};
    };
    await _pump(tester, const DuelPage());
    await tester.enterText(find.byType(TextField).first, 'Sara');
    await tester.tap(find.text('Create a duel'));
    await _settle(tester);
    expect(find.text('What should the duel cover?'), findsOneWidget);

    await tester.tap(find.byType(FilterChip).at(3)); // the first grammar topic
    await tester.tap(find.text('5'));
    await _settle(tester, 500);
    await tester.tap(find.text('Create the duel'));
    await _settle(tester, 3000);

    final body = created.single;
    expect(body['action'], 'create');
    final questions = body['questions'] as List;
    expect(questions, hasLength(5));
    final levels = [for (final q in questions) q['level'] as int];
    expect(levels, [...levels]..sort(), reason: 'easy first, then medium, then hard');
    expect(body['topics'], contains('Conjugaison'));
    expect(find.text('5 questions'), findsOneWidget);
  });

  test('duel questions go from easy to hard', () async {
    DuelBuilder.chat = (messages, {thinking = false, temperature, maxTokens}) async => {'questions': []};
    final questions = await DuelBuilder.build(const DuelTopics(), count: 15);
    expect(questions, hasLength(15));
    final levels = [for (final q in questions) q.level];
    expect(levels, [...levels]..sort());
    expect(levels.toSet(), containsAll([1, 2, 3]));
  });

  testWidgets('classmates wait in a room and start together when the creator presses Start', (tester) async {
    final questions = [
      for (var i = 0; i < 5; i++)
        {'prompt': 'Il faut que tu ___ ($i).', 'hint': 'Subjonctif', 'options': ['sois', 'es'], 'correct': 0, 'level': 1},
    ];
    String? startedAt;
    final sent = <String>[];
    DuelPage.send = (body) async {
      sent.add(body['action'] as String);
      final status = {'live': true, 'started_at': null, 'host_name': 'Ahmad', 'players': ['Ahmad', 'Sara'], 'now': DateTime.now().toUtc().toIso8601String()};
      return body['action'] == 'get' ? {'duel': {'topics': ['Le Subjonctif'], 'questions': questions}, 'status': status} : {'status': status};
    };
    DuelPage.status = (code) async => {
          'live': true,
          'started_at': startedAt,
          'host_name': 'Ahmad',
          'players': ['Ahmad', 'Sara', 'Yassin'],
          'now': DateTime.now().toUtc().toIso8601String(),
        };
    await _pump(tester, const DuelPage());
    await tester.enterText(find.byType(TextField).first, 'Sara');
    await tester.enterText(find.byType(TextField).last, 'LIVE01');
    await tester.tap(find.text('Join'));
    await _settle(tester);

    expect(sent, ['get', 'join']);
    expect(find.text('Waiting for Ahmad to start…'), findsOneWidget);
    await _settle(tester, 2500);
    expect(find.text('Yassin'), findsOneWidget, reason: 'the room updates while waiting');
    expect(find.text('Il faut que tu ___ (0).'), findsNothing, reason: 'nobody plays before the start');

    // The creator presses Start: the server sets a start time 3 s from now.
    startedAt = DateTime.now().toUtc().add(const Duration(seconds: 3)).toIso8601String();
    await _settle(tester, 2500);
    expect(find.text('Get ready!'), findsOneWidget);
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
    await _settle(tester, 1000);
    expect(find.text('Il faut que tu ___ (0).'), findsOneWidget);
  });
}
