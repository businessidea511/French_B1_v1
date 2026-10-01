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
}
