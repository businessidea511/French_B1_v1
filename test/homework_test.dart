import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/pages/homework/homework_page.dart';
import 'package:french_course_b1/services/homework_service.dart';
import 'package:french_course_b1/services/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget page) => ChangeNotifierProvider(create: (_) => LanguageProvider(), child: MaterialApp(home: page));

void main() {
  late List<String> prompts;
  late bool checkLosesItems;

  const sheet = {
    'title': 'Le passé composé',
    'text': '',
    'exercises': [
      {
        'label': 'Exercice 1',
        'instruction': 'Conjuguez au passé composé.',
        'items': [
          {'n': '1', 'question': 'Hier, elle ___ (aller) au marché.', 'options': [], 'student_answer': 'est allé'},
          {'n': '2', 'question': 'Nous ___ (finir) nos devoirs.', 'options': [], 'student_answer': ''},
        ],
      },
    ],
    'unreadable': [],
  };

  Map<String, dynamic> answer(String n, String a, String sentence, String student, String studentAnswer) => {
        'exercise': 'Exercice 1',
        'n': n,
        'question': '…',
        'answer': a,
        'sentence': sentence,
        'why': 'شرح القاعدة',
        'student_answer': studentAnswer,
        'student': student,
      };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HomeworkService.instance.reset();
    prompts = [];
    checkLosesItems = false;
    HomeworkService.chat = (messages, {thinking = false, temperature, maxTokens}) async {
      final system = messages.first['content'] as String;
      prompts.add(system);
      if (system.startsWith('These photos are a French homework sheet')) {
        expect((messages.last['content'] as List).where((p) => (p as Map)['type'] == 'image_url'), hasLength(2));
        return Map<String, dynamic>.from(sheet);
      }
      if (system.startsWith('A learner of French')) {
        return {
          'translation': 'التمرين 1: صرّف في الماضي المركّب.',
          'words': [
            {'fr': 'le marché', 'meaning': 'السوق', 'example': 'Hier, elle est allée au marché.'},
          ],
        };
      }
      // The solver and the checker both think before answering.
      if (system.startsWith('You are an expert French teacher')) {
        expect(thinking, isTrue);
        return {
          'answers': [
            answer('1', 'est allé', 'Hier, elle est allé au marché.', 'correct', 'est allé'), // mistake
            answer('2', 'avons fini', 'Nous avons fini nos devoirs.', 'none', ''),
          ],
        };
      }
      if (system.startsWith('You are a second French teacher')) {
        expect(thinking, isTrue);
        expect(messages.last['content'], contains('est allé'));
        if (checkLosesItems) return {'answers': [answer('1', 'x', 'x', 'none', '')]};
        return {
          'answers': [
            answer('1', 'est allée', 'Hier, elle est allée au marché.', 'wrong', 'est allé'),
            answer('2', 'avons fini', 'Nous avons fini nos devoirs.', 'none', ''),
          ],
        };
      }
      fail('Unexpected prompt: $system');
    };
  });

  test('reads, translates in the app language, solves, and the check fixes a mistake', () async {
    final steps = <HomeworkStep>[];
    final h = await HomeworkService.instance.solve(['aaa', 'bbb'], 'image/jpeg', AppLanguage.arabic, onStep: steps.add);

    expect(steps, HomeworkStep.values);
    expect(prompts.where((p) => p.contains('in Arabic')), isNotEmpty, reason: 'translation and words in the chosen language');
    expect(h.translation, startsWith('التمرين'));
    expect(h.words.single['meaning'], 'السوق');
    expect(h.answers.first.answer, 'est allée', reason: 'the second teacher fixed the agreement');
    expect(h.answers.first.student, 'wrong');
    expect(h.answers.first.studentAnswer, 'est allé');
    expect(h.byExercise.keys, ['Exercice 1']);
    expect(h.instructionOf('Exercice 1'), 'Conjuguez au passé composé.');

    // Kept for later, also after a restart.
    HomeworkService.instance.reset();
    await HomeworkService.instance.load();
    expect(HomeworkService.instance.history.single.answers[1].sentence, 'Nous avons fini nos devoirs.');
  });

  test('another app language: the help comes in that language', () async {
    await HomeworkService.instance.solve(['aaa', 'bbb'], 'image/jpeg', AppLanguage.ukrainian);
    expect(prompts.firstWhere((p) => p.startsWith('A learner of French')), contains('in Ukrainian'));
    expect(prompts.firstWhere((p) => p.startsWith('You are an expert')), contains('in Ukrainian'));
  });

  test('a check that loses answers is not trusted', () async {
    checkLosesItems = true;
    final h = await HomeworkService.instance.solve(['aaa', 'bbb'], 'image/jpeg', AppLanguage.english);
    expect(h.answers, hasLength(2));
  });

  testWidgets('the result shows the answers, the words and the translation', (tester) async {
    final h = await HomeworkService.instance.solve(['aaa', 'bbb'], 'image/jpeg', AppLanguage.arabic);
    await tester.pumpWidget(_app(HomeworkResultPage(homework: h)));
    await tester.pumpAndSettle();
    expect(find.textContaining('التمرين 1'), findsOneWidget);

    await tester.tap(find.textContaining('Answers'));
    await tester.pumpAndSettle();
    expect(find.text('est allée'), findsOneWidget);
    expect(find.textContaining('You wrote: est allé'), findsOneWidget);
    expect(find.textContaining('Your answers: 0 / 1 right'), findsOneWidget);

    await tester.tap(find.textContaining('Hard words'));
    await tester.pumpAndSettle();
    expect(find.text('le marché'), findsOneWidget);
  });
}
