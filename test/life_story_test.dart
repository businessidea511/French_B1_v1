import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/pages/life/life_chat_page.dart';
import 'package:french_course_b1/pages/life/life_home.dart';
import 'package:french_course_b1/services/language_provider.dart';
import 'package:french_course_b1/services/life_story_service.dart';
import 'package:french_course_b1/services/progress_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake story writer and actors.
class _FakeAi {
  final prompts = <String>[];

  Future<Map<String, dynamic>> call(List<Map<String, dynamic>> messages,
      {bool thinking = false, double? temperature, int? maxTokens}) async {
    final system = messages.first['content'] as String;
    prompts.add(system);
    if (system.startsWith('Translate the French chat message')) {
      return {'translation': 'Hello! Your parcel is at my place.'};
    }
    final last = messages.last['content'] as String;
    if (last == 'Je vais passer demain matin.') {
      return {
        'reply': 'Très bien !',
        'correct': true,
        'correction': '',
        'better': 'Je passerai demain matin.',
        'explanation': 'futur simple sounds more natural here',
        'remember': [],
      };
    }
    if (system.contains('You are the writer')) {
      return {
        'scenes': [
          {
            'character': 'voisine',
            'title': 'Le colis',
            'situation': 'A parcel for the learner arrived at her place.',
            'goal': 'Say when you will pick up the parcel.',
            'grammar': 'futur proche',
            'opening': 'Bonjour ! Votre colis est chez moi. Vous passez quand ?',
          },
          {
            'character': 'ami',
            'title': 'Concert à Liège',
            'situation': 'Lucas invites the learner to a concert on Saturday.',
            'goal': 'Accept or refuse the invitation and explain why.',
            'grammar': 'conditionnel',
            'opening': 'Salut ! Tu viens au concert samedi ?',
          },
          {'character': 'nobody', 'title': 'x', 'opening': 'ignored: not a chosen character'},
        ],
      };
    }
    return {
      'reply': 'Parfait, à demain alors !',
      'correction': 'Je vais passer demain.',
      'explanation': 'futur proche: aller + infinitif',
      'goal_done': true,
      'remember': ['will pick up the parcel tomorrow'],
    };
  }
}

void main() {
  late _FakeAi ai;
  final day1 = DateTime(2026, 10, 5, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ProgressService.clock = () => day1;
    ProgressService.instance.reset();
    LifeStoryService.instance.reset();
    ai = _FakeAi();
    LifeStoryService.chat = ai.call;
  });

  Future<void> configure() => LifeStoryService.instance.configure(
        firstName: 'Ahmad',
        city: 'Liège',
        about: 'I work in logistics and study French at night.',
        minutes: 10,
        characters: ['voisine', 'ami', 'collegue'],
      );

  test('each day the characters write first, and the learner must answer', () async {
    final story = LifeStoryService.instance;
    await configure();
    await story.ensureToday();

    expect(story.scenes.map((s) => s.characterId), ['voisine', 'ami'], reason: '10 minutes = 2 scenes');
    expect(story.unreadTotal, 2);
    expect(story.thread('voisine').single.text, contains('Votre colis'));
    expect(ai.prompts.first, contains('Liège'));

    await story.ensureToday(); // same day: no new plan
    expect(story.thread('voisine'), hasLength(1));

    final answer = await story.reply('voisine', 'Je passe demain', explanationLanguage: 'Arabic');
    expect(answer.text, 'Parfait, à demain alors !');
    final mine = story.thread('voisine')[1];
    expect(mine.correction, 'Je vais passer demain.');
    expect(ProgressService.instance.mistakes.first['source'], 'Ma vie');
    expect(story.sceneFor('voisine')!.done, isTrue);
    expect(story.scenesDone, 1);
    expect(story.memory['voisine'], ['will pick up the parcel tomorrow']);
    expect(ai.prompts.last, contains('Arabic'), reason: 'explanations in the learner\'s language');
  });

  test('the story is saved, and the next day continues from what was said', () async {
    final story = LifeStoryService.instance;
    await configure();
    await story.ensureToday();
    await story.reply('voisine', 'Je passe demain', explanationLanguage: 'English');

    // Restart the app.
    story.reset();
    await story.load();
    expect(story.thread('voisine'), hasLength(3));
    expect(story.memory['voisine'], isNotEmpty);
    expect(story.setUp, isTrue);

    // Tomorrow.
    ProgressService.clock = () => day1.add(const Duration(days: 1));
    await story.ensureToday();
    expect(story.planDay, '2026-10-06');
    expect(ai.prompts.last, contains('will pick up the parcel tomorrow'), reason: 'memory goes into the new episode');
    expect(story.thread('voisine').last.day, '2026-10-06');
  });

  testWidgets('start the story, see the inbox, answer a character', (tester) async {
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: ProgressService.instance),
        ChangeNotifierProvider.value(value: LifeStoryService.instance),
      ],
      child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: LifeInbox()))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('🏡 Ma vie en Belgique'), findsOneWidget);

    await tester.tap(find.text('Start my story').first);
    await tester.pumpAndSettle();
    expect(find.byType(LifeSetupPage), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Ahmad');
    final start = find.descendant(of: find.byType(LifeSetupPage), matching: find.text('Start my story'));
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();

    // Back on the inbox: today's messages.
    expect(find.text('Madame Dubois'), findsOneWidget);
    expect(find.text('Bonjour ! Votre colis est chez moi. Vous passez quand ?'), findsOneWidget);
    expect(find.text('1'), findsWidgets, reason: 'unread badges');

    await tester.tap(find.text('Madame Dubois'));
    await tester.pumpAndSettle();
    expect(find.byType(LifeChatPage), findsOneWidget);
    expect(find.text('Le colis'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Je passe demain');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Parfait, à demain alors !'), findsOneWidget);
    expect(find.text('✏️ Je vais passer demain.'), findsOneWidget);
    expect(LifeStoryService.instance.unread['voisine'], 0);

    // A correct sentence gets a green check and a more natural version.
    ScaffoldMessenger.of(tester.element(find.byType(LifeChatPage))).removeCurrentSnackBar(); // "Scene complete"
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Je vais passer demain matin.');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(find.text('✅ Correct!'), findsOneWidget);
    expect(find.text('💬 Je passerai demain matin.'), findsOneWidget);

    // Translate a message of the character: really translated, even with an English interface.
    await tester.tap(find.byIcon(Icons.translate_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Hello! Your parcel is at my place.'), findsOneWidget);
    expect(ai.prompts.last, contains('into English'));
  });

  test('voice input without punctuation is not reported as a mistake', () async {
    final story = LifeStoryService.instance;
    await configure();
    await story.ensureToday();
    LifeStoryService.chat = (messages, {thinking = false, temperature, maxTokens}) async =>
        {'reply': 'Super !', 'correct': true, 'correction': 'Je passe demain.', 'explanation': ''};
    await story.reply('voisine', 'je passe demain', explanationLanguage: 'English');
    final mine = story.thread('voisine')[1];
    expect(mine.correction, isEmpty);
    expect(mine.checked, isTrue);
    expect(ProgressService.instance.mistakes, isEmpty);
  });
}
