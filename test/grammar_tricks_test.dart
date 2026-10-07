import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/data/grammar_tricks.dart';
import 'package:french_course_b1/models/grammar_topic.dart';
import 'package:french_course_b1/pages/grammar/grammar_tricks_page.dart';
import 'package:french_course_b1/services/grammar_tricks_service.dart';
import 'package:french_course_b1/services/language_provider.dart';
import 'package:french_course_b1/services/translation_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every grammar topic of the course has hand-written tricks', () {
    for (final g in grammarTopics) {
      expect(curatedTricksFor(g.id, g.title), isNotNull, reason: g.id);
    }
    // Topics added from the book (random ids) are recognised by their title.
    for (final title in [
      'Le discours indirect au présent',
      'Le Superlatif',
      "Les adverbes de temps : demain / le lendemain, aujourd'hui / ce jour-là, hier / la veille",
    ]) {
      expect(curatedTricksFor('custom_grammar_1', title), isNotNull, reason: title);
    }
    expect(curatedTricksFor('custom_grammar_2', 'Les pronoms relatifs'), isNull);
  });

  test('each card is short and complete', () {
    curatedTricks.forEach((id, t) {
      expect(t.oneLine, isNotEmpty, reason: id);
      expect(t.tricks.length, inInclusiveRange(3, 6), reason: id);
      expect(t.traps, isNotEmpty, reason: id);
      for (final trick in t.tricks) {
        expect(trick.examples, isNotEmpty, reason: '$id: ${trick.title}');
      }
    });
    final enY = curatedTricks['cod_coi']!.tricks.map((t) => t.title).join(' | ');
    expect(enY, contains('→ EN'));
    expect(enY, contains('→ Y'));
  });

  test('tricks saved inside a topic come back, and their texts get translated', () {
    final t = curatedTricks['superlatif']!;
    final content = [
      {'type': 'section_title', 'title': 'Le superlatif'},
      t.toWidget(),
    ];
    final back = embeddedTricks(content)!;
    expect(back.oneLine, t.oneLine);
    expect(back.tricks.first.examples, t.tricks.first.examples);
    expect(back.traps.first.right, t.traps.first.right);
    expect(TranslationStore.lessonTexts('Le superlatif', content), containsAll(t.texts));
  });

  test('a new topic gets its tricks from the AI; known topics are left alone', () async {
    var calls = 0;
    GrammarTricksService.chat = (messages, {thinking = false, temperature, maxTokens}) async {
      calls++;
      expect(messages.last['content'], contains('Les pronoms relatifs'));
      expect(messages.last['content'], contains('qui remplace le sujet'), reason: 'the lesson itself guides the tricks');
      return {
        'one_line': 'qui, que, où, dont link two sentences.',
        'tricks': [
          {'title': 'qui = subject, que = object', 'trick': 'A verb right after? qui.', 'examples': ["L'homme qui parle."]},
        ],
        'traps': [
          {'wrong': "L'homme que parle.", 'right': "L'homme qui parle.", 'why': 'subject → qui'},
        ],
      };
    };
    final lesson = [
      {'type': 'text', 'content': 'qui remplace le sujet'},
      {'type': GrammarTricks.widgetType, 'one_line': 'old', 'tricks': [{'title': 'old', 'trick': 'old'}]},
    ];
    final withTricks = await GrammarTricksService.attach('custom_grammar_9', 'Les pronoms relatifs', '', lesson);
    expect(withTricks.where((w) => (w as Map)['type'] == GrammarTricks.widgetType), hasLength(1), reason: 'old tricks replaced');
    expect(embeddedTricks(withTricks)!.oneLine, startsWith('qui, que'));

    final known = await GrammarTricksService.attach('cod_coi', 'COD / COI', '', lesson);
    expect(known, same(lesson));
    expect(calls, 1);

    // If the AI fails, the topic is still saved, just without tricks.
    GrammarTricksService.chat = (messages, {thinking = false, temperature, maxTokens}) async => throw Exception('offline');
    final plain = [{'type': 'text', 'content': 'x'}];
    expect(await GrammarTricksService.attach('custom_grammar_10', 'Le gérondif', '', plain), same(plain));
  });

  testWidgets('the memory card of a topic', (tester) async {
    tester.view.physicalSize = const Size(420, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final topic = grammarTopics.firstWhere((g) => g.id == 'cod_coi');
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MaterialApp(home: GrammarTricksDetailPage(topic: topic)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('de, du, de la, des → EN'), findsOneWidget);
    expect(find.text("Je mange du pain. → J'en mange."), findsOneWidget);
    expect(find.text('❌ Je lui vais.'), findsOneWidget);
    expect(find.text("✅ J'y vais."), findsOneWidget);
    expect(find.text('Open the full lesson'), findsOneWidget);
  });
}
