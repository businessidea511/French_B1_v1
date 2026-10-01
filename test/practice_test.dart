import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:french_course_b1/pages/exercises/exercises_page.dart';
import 'package:french_course_b1/services/story_service.dart';
import 'package:french_course_b1/services/topic_context.dart';

void main() {
  group('Exercises', () {
    test('sanitizeQuestions keeps the right answer and drops broken questions', () {
      final out = ExercisesPage.sanitize([
        {'question': 'Je ___ (aller).', 'options': ['vais', 'va', 'vais', 'allons'], 'correct': 0, 'explanation': 'x'},
        {'question': 'Bad index', 'options': ['a', 'b'], 'correct': 7},
        {'question': '', 'options': ['a', 'b'], 'correct': 0},
        {'question': 'One option only', 'options': ['a', 'a'], 'correct': 0},
        {'question': 'No explanation', 'options': ['oui', 'non'], 'correct': 1},
      ]);
      expect(out, hasLength(2));
      final first = out.first;
      expect(first['options'], hasLength(3), reason: 'duplicate "vais" removed');
      expect((first['options'] as List)[first['correct'] as int], 'vais');
      expect((out.last['options'] as List)[out.last['correct'] as int], 'non');
      expect(out.last['explanation'], '');
    });
  });

  test('TopicContext summarises rules, forms and examples but not long text', () {
    final summary = TopicContext.summarize([
      {'type': 'section_title', 'title': 'Formation'},
      {'type': 'text', 'content': 'A long explanation that should not be sent.'},
      {'type': 'tipbox', 'title': 'Formule', 'content': 'radical de nous + -ais'},
      {'type': 'example', 'french': 'Je parlais.'},
    ]);
    expect(summary, contains('## Formation'));
    expect(summary, contains('radical de nous'));
    expect(summary, contains('Je parlais.'));
    expect(summary, isNot(contains('long explanation')));
  });

  group('StoryService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('chapter 2 continues from the memory, cliffhanger and reader idea', () async {
      final prompts = <String>[];
      StoryService.chat = (messages, {thinking = false, temperature, maxTokens}) async {
        final system = messages.first['content'] as String;
        prompts.add(system);
        final n = system.contains('THIS IS CHAPTER 1.') ? 1 : 2;
        return {
          if (n == 1) 'series_title': 'Le vélo volé',
          'chapter_title': 'Chapitre $n : La vitrine',
          'pages': [
            {'text': 'Page de chapitre $n **qui finit mal**.', 'translation': 't', 'annotations': []},
            {'text': '   '},
          ],
          'questions': [],
          'memory': {'summary': 'summary after $n', 'cliffhanger': 'Le vélo a disparu ($n).'},
        };
      };

      final series = await StoryService.start(
        genre: 'mystery', theme: 'Liège', grammar: ['Imparfait'], lessons: [], language: 'Arabic');
      expect(series.title, 'Le vélo volé');
      expect(series.chapters.single['chapter_title'], 'La vitrine', reason: '"Chapitre 1 :" prefix removed');
      expect(series.chapters.single['pages'], hasLength(1), reason: 'empty page dropped');
      expect(prompts.single, contains('FIRST SENTENCE is the hook'));
      expect(prompts.single, contains('Imparfait'));

      final updated = await StoryService.continueSeries(series, readerIdea: 'le voisin ment');
      expect(updated.chapters, hasLength(2));
      expect(updated.chapters.last['number'], 2);
      final second = prompts.last;
      expect(second, contains('summary after 1'));
      expect(second, contains('qui finit mal'), reason: 'last page of chapter 1 is passed on');
      expect(second, contains('le voisin ment'));
      expect(second, contains('Do NOT end the story'));
      expect(updated.teaser, 'Le vélo a disparu (2).');

      final library = await StoryService.loadAll();
      expect(library.single.chapters, hasLength(2));
      await StoryService.delete(series.id);
      expect(await StoryService.loadAll(), isEmpty);
    });
  });
}
