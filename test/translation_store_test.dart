import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/models/lesson_topic.dart';
import 'package:french_course_b1/pages/lessons/dynamic_lesson_page.dart';
import 'package:french_course_b1/pages/lessons/lesson_parts.dart';
import 'package:french_course_b1/services/language_provider.dart';
import 'package:french_course_b1/services/translation_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the text fingerprint is the same as on the server (sha1, 16 hex)', () {
    // node: crypto.createHash('sha1').update(text, 'utf8').digest('hex').slice(0, 16)
    expect(TranslationStore.hash('Le subjonctif « que je sois » — ✅'), '60e271e998535e4b');
  });

  test('language names map to codes; English is never translated', () {
    expect(TranslationStore.codeFor('العربية'), 'ar');
    expect(TranslationStore.codeFor('Arabic'), 'ar');
    expect(TranslationStore.codeFor('fr'), 'fr');
    expect(TranslationStore.codeFor('English'), isNull);
    expect(TranslationStore.targets.length, 7);
  });

  test('a lesson lists exactly the texts its widgets translate', () {
    final texts = TranslationStore.lessonTexts('Le subjonctif', [
      {'type': 'section_title', 'title': '**When to use it**', 'emoji': '📌'},
      {'type': 'text', 'content': 'After expressions of wish.'},
      {'type': 'example', 'french': 'Je veux que tu viennes.', 'translation': 'I want you to come.'},
      {'type': 'french_tipbox', 'title': 'Forms', 'frenchText': 'que je sois = that I am\nêtre → été    (been)\nque tu aies'},
      {'type': 'table', 'headers': ['Verbe', 'Meaning'], 'rows': [['être', 'to be']]},
      {'type': 'exercise', 'instruction': 'Choose the right form.', 'items': [
        {'question': 'Il faut que je ___', 'options': ['sois', 'suis'], 'correct': 0, 'explanation': 'After il faut que.'},
      ]},
      {'type': 'mistake', 'wrong': 'que je suis', 'right': 'que je sois', 'why': 'Subjunctive needed.'},
    ]);
    expect(texts, containsAll([
      'Le subjonctif', 'When to use it', 'After expressions of wish.', 'I want you to come.', 'Forms',
      'that I am', '(been)', 'Verbe', 'Meaning', 'to be', 'Choose the right form.', 'After il faut que.',
      'Subjunctive needed.',
    ]));
    expect(texts, isNot(contains('Je veux que tu viennes.')), reason: 'French examples stay French');
    expect(texts, isNot(contains('être')));
  });

  test('chunks stay under 30 texts and about 5000 characters', () {
    final chunks = TranslationStore.chunks([for (var i = 0; i < 70; i++) 'x' * 100]);
    expect(chunks.map((c) => c.length), [30, 30, 10]);
    final long = TranslationStore.chunks(['a' * 3000, 'b' * 3000, 'c' * 10]);
    expect(long.map((c) => c.length), [1, 2]);
  });

  List<dynamic> longLesson() => [
        {'type': 'text', 'content': 'Intro.'},
        for (var p = 1; p <= 4; p++) ...[
          {'type': 'section_title', 'title': 'Part title $p', 'emoji': '📖'},
          for (var i = 0; i < 3; i++) {'type': 'text', 'content': 'Explanation $p.$i'},
        ],
      ];

  test('long lessons are split at their section titles, short ones are not', () {
    final split = LessonParts.split(longLesson(), DynamicLessonPage.clean)!;
    expect(split.intro.length, 1);
    expect(split.parts.map((p) => p.title), ['Part title 1', 'Part title 2', 'Part title 3', 'Part title 4']);
    expect(split.parts.first.widgets.length, 3);
    expect(LessonParts.split(longLesson().take(6).toList(), DynamicLessonPage.clean), isNull);
  });

  testWidgets('a long lesson shows its parts; a part opens on its own page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final topic = LessonTopic(id: 'subj', title: 'Le subjonctif', subtitle: '', icon: '📘', description: '', content: longLesson());
    final split = LessonParts.split(topic.content, DynamicLessonPage.clean)!;
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LessonPartsList(
            topic: topic,
            parts: split.parts,
            buildPart: (widgets) => [for (final w in widgets) Text('${w['content']}')],
          ),
        ),
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('This lesson has 4 parts. Open one at a time.'), findsOneWidget);
    expect(find.text('Explanation 2.0'), findsNothing);

    await tester.tap(find.text('Part title 2'));
    await tester.pumpAndSettle();
    expect(find.text('Part 2 of 4'), findsOneWidget);
    expect(find.text('Explanation 2.0'), findsOneWidget);
    expect(find.text('Explanation 3.0'), findsNothing);

    await tester.tap(find.text('Next part').last);
    await tester.pumpAndSettle();
    expect(find.text('Part 3 of 4'), findsOneWidget);

    // Back on the overview, both visited parts are ticked.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('2 / 4 parts done'), findsOneWidget);
  });
}
