import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/pages/exam/model_essay_page.dart';
import 'package:french_course_b1/pages/exam/writing_practice_page.dart';
import 'package:french_course_b1/services/essay_service.dart';
import 'package:french_course_b1/services/exam_writing_service.dart';
import 'package:french_course_b1/services/language_provider.dart';
import 'package:french_course_b1/services/progress_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget page) => ChangeNotifierProvider(create: (_) => LanguageProvider(), child: MaterialApp(home: page));

void main() {
  late List<String> prompts;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProgressService.instance.reset();
    EssayService.instance.reset();
    prompts = [];
    EssayService.chat = (messages, {thinking = false, temperature, maxTokens}) async {
      final system = messages.first['content'] as String;
      prompts.add(system);
      if (system.startsWith("These photos are a learner's HANDWRITTEN")) {
        expect(system, contains('with ALL its mistakes'));
        return {
          'title': 'Mon week-end',
          'question': 'Racontez votre week-end.',
          'text': 'Samedi, je suis allé au marché avec ma soeur. Il faisait tres froid.',
          'words': 13,
        };
      }
      if (system.startsWith('These are photos')) {
        expect((messages.last['content'] as List).where((p) => (p as Map)['type'] == 'image_url'), hasLength(2));
        return {
          'questions': [
            {'title': 'Un voyage', 'question': 'Racontez un voyage inoubliable.', 'min_words': 100, 'max_words': 140},
            {'title': 'Ma ville', 'question': 'Décrivez votre ville et ce que vous voudriez changer.'},
            {'title': '', 'question': ''},
          ],
        };
      }
      return {
        'essay': "L'été dernier, je suis allé à Bruges avec ma sœur. Il faisait beau…",
        'notes': [
          {'fr': 'je suis allé', 'point': 'passé composé with être'},
        ],
      };
    };
  });

  test('class papers become saved questions, without duplicates', () async {
    final essays = EssayService.instance;
    final found = await essays.readPapers(['aaa', 'bbb'], 'image/jpeg');
    expect(found.map((q) => q.title), ['Un voyage', 'Ma ville']);
    expect(found.first.minWords, 100);
    expect(essays.addAll(found), 2);
    expect(essays.addAll(found), 0, reason: 'the same paper photographed twice');

    final typed = essays.addTyped('Écrivez un e-mail à votre voisin pour l\'inviter à une fête.');
    expect(essays.questions, hasLength(3));
    expect(typed.subject.instruction, contains('voisin'));
    final counted = essays.addTyped('Racontez votre dernier anniversaire. (100 mots)');
    expect([counted.minWords, counted.maxWords], [80, 120]);

    // Saved on the device.
    await pumpEventQueue();
    essays.reset();
    await essays.load();
    expect(essays.questions.map((q) => q.title), contains('Un voyage'));
  });

  test('the model essay uses simple A2–B1 words and is kept', () async {
    final essays = EssayService.instance;
    final q = essays.addTyped('Racontez un voyage inoubliable.');
    final model = await essays.writeModel(q.subject);
    expect(model.notes.single.french, 'je suis allé');
    expect(prompts.last, contains('SIMPLE A2–B1 VOCABULARY ONLY'));
    expect(prompts.last, contains('Bien que ce soit difficile'), reason: 'the joker phrases are suggested');

    essays.reset();
    await essays.load();
    expect(essays.models[q.subject.id]!.essay, startsWith("L'été dernier"));

    essays.remove(q.id);
    expect(essays.models, isEmpty);
  });

  testWidgets('Writing practice lists the class questions and opens them', (tester) async {
    tester.view.physicalSize = const Size(420, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    EssayService.instance.addTyped('Racontez un voyage inoubliable en Belgique.');
    await tester.pumpWidget(_app(const WritingPracticePage()));
    await tester.pumpAndSettle();
    expect(find.textContaining('My class questions'), findsOneWidget);
    expect(find.text('Racontez un voyage inoubliable en Belgique.'), findsOneWidget, reason: 'a short question is shown once');

    await tester.tap(find.text('Racontez un voyage inoubliable en Belgique.'));
    await tester.pumpAndSettle();
    expect(find.byType(WritingEditorPage), findsOneWidget);
    expect(find.text('AI model essay'), findsOneWidget);
  });

  testWidgets('the model essay page writes and shows the essay', (tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final q = EssayService.instance.addTyped('Racontez un voyage inoubliable.');
    await EssayService.instance.setCulture('Palestine', ''); // else the country is asked first
    await tester.pumpWidget(_app(ModelEssayPage(subject: q.subject)));
    await tester.pumpAndSettle();
    expect(find.textContaining("L'été dernier"), findsOneWidget);
    expect(find.text('je suis allé'), findsOneWidget);
    expect(find.text('Now write yours'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a handwritten essay: its text (with its mistakes) goes to the writing page', (tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final essays = EssayService.instance;
    final (question, text) = await essays.readHandwritten(['page1'], 'image/jpeg');
    expect(text, contains('tres froid'), reason: 'mistakes are kept for the correction');
    expect(question.question, 'Racontez votre week-end.');
    expect(essays.questions.single.title, 'Mon week-end');

    // Photographed again: the same topic is not added twice.
    final (again, _) = await essays.readHandwritten(['page1'], 'image/jpeg');
    expect(again.id, question.id);
    expect(essays.questions, hasLength(1));

    await ExamWritingService.saveDraft(question.subject.id, text);
    await tester.pumpWidget(_app(WritingEditorPage(subject: question.subject)));
    await tester.pumpAndSettle();
    expect(find.text(text), findsOneWidget);
  });

  test("essays about culture use the learner's country and traditions", () async {
    final essays = EssayService.instance;
    final q = essays.addTyped('Décrivez une fête importante dans votre pays.');
    await essays.writeModel(q.subject);
    expect(prompts.last, isNot(contains('The learner comes from')), reason: 'no country chosen yet');

    await essays.setCulture('Palestine', "musulman : l'Aïd el-Fitr, l'Aïd el-Adha");
    final model = await essays.writeModel(q.subject);
    expect(prompts.last, contains('The learner comes from Palestine'));
    expect(prompts.last, contains("l'Aïd el-Fitr"));
    expect(model.country, 'Palestine');

    // Kept on the device.
    essays.reset();
    await essays.load();
    expect(essays.country, 'Palestine');
    expect(essays.models[q.subject.id]!.country, 'Palestine');
  });
}
