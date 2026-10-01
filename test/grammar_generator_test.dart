import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:french_course_b1/services/grammar_generator.dart';
import 'package:french_course_b1/services/language_provider.dart';
import 'package:french_course_b1/services/topic_match.dart';
import 'package:french_course_b1/widgets/grammar_cards.dart';

Map<String, dynamic> _section(String id) => {'type': 'section_title', 'title': 'rule $id'};

/// Fake AI: a 5-rule plan; the first writer call "forgets" r2.
class _FakeAi {
  final calls = <String>[];
  bool thinkingUsedForPlan = false;
  int writerCalls = 0;

  Future<Map<String, dynamic>> call(List<Map<String, dynamic>> messages,
      {bool thinking = false, double? temperature, int? maxTokens}) async {
    final system = messages.first['content'] as String;
    final user = messages.last['content'] as String;
    if (system.contains('designing the COMPLETE syllabus')) {
      calls.add('plan');
      thinkingUsedForPlan = thinking;
      return {
        'title': "L'Imparfait",
        'subtitle': 'Imperfect tense',
        'icon': '🕰️',
        'rules': [for (var i = 1; i <= 5; i++) {'name': 'Règle $i', 'teach': 'point $i'}],
        'expressions': [],
      };
    }
    if (system.contains('RULES TO WRITE') || user.startsWith('RULES TO WRITE')) {
      writerCalls++;
      calls.add('write');
      final ids = (jsonDecode(user.substring(user.indexOf('['))) as List).map((r) => r['id'] as String);
      return {
        'by_rule': {
          for (final id in ids)
            if (!(writerCalls == 1 && id == 'r2'))
              id: [
                _section(id),
                if (id == 'r1') {'type': 'mistake', 'wrong': 'Je parlais.', 'right': 'Je parlais !'},
                if (id == 'r3') {'type': 'mistake', 'wrong': 'bad', 'right': 'wrong fix'},
              ]
        }
      };
    }
    if (system.contains('opening and closing parts')) {
      calls.add('wrap');
      return {
        'intro': [{'type': 'section_title', 'title': 'intro'}],
        'expressions': [],
        'summary': [{'type': 'section_title', 'title': 'résumé'}],
        'quiz': [
          {'type': 'section_title', 'title': 'quiz'},
          {
            'type': 'exercise',
            'title': 'Quiz',
            'items': [
              {'question': "Qu'est-ce que l'imparfait ?", 'options': ['a', 'b'], 'correct': 0},
              {'question': 'Je ___ (parler).', 'answer': 'parlais'},
            ],
          },
        ],
      };
    }
    if (system.contains('strict examiner')) {
      calls.add('review');
      final entries = jsonDecode(user.substring(user.indexOf('{'))) as Map<String, dynamic>;
      final mistakeId = entries.keys.firstWhere((k) => entries[k]['type'] == 'mistake');
      final quizId = entries.keys.firstWhere((k) => k.endsWith('.q0'));
      return {
        'fixes': [
          {'id': mistakeId, 'action': 'replace', 'value': {'wrong': "J'ai allé", 'right': 'Je suis allé', 'why': 'être'}},
          {'id': quizId, 'action': 'remove'},
          {'id': 'w999', 'action': 'remove'},
        ]
      };
    }
    if (system.contains('Convert EVERY exercise')) {
      calls.add('book');
      return {
        'widgets': [
          {'type': 'section_title', 'title': 'book'},
          {'type': 'exercise', 'title': 'Ex 1', 'items': []},
        ]
      };
    }
    throw StateError('unexpected prompt');
  }
}

void main() {
  group('GrammarGenerator', () {
    test('covers every planned rule in order, re-writing skipped ones', () async {
      final fake = _FakeAi();
      GrammarGenerator.chat = fake.call;

      final result = await GrammarGenerator.generate('imparfait');
      final widgets = result['widgets'] as List;
      final titles = widgets.where((w) => w['type'] == 'section_title').map((w) => w['title']).toList();

      expect(fake.thinkingUsedForPlan, isTrue);
      expect(titles, ['intro', 'rule r1', 'rule r2', 'rule r3', 'rule r4', 'rule r5', 'résumé', 'quiz']);
      expect(fake.writerCalls, 3, reason: '2 batches of ≤3 rules + 1 retry for the skipped rule');
      expect(fake.calls.contains('book'), isFalse, reason: 'no book exercises without a source');

      // Broken mistake (wrong == right) dropped; examiner fix applied; bad quiz item removed.
      final mistakes = widgets.where((w) => w['type'] == 'mistake').toList();
      expect(mistakes, hasLength(1));
      expect(mistakes.single['right'], 'Je suis allé');
      expect(mistakes.single['type'], 'mistake');
      final quiz = widgets.firstWhere((w) => w['type'] == 'exercise');
      expect((quiz['items'] as List).map((i) => i['question']), ['Je ___ (parler).']);
      expect(result['title'], "L'Imparfait");
    });

    test('adds book exercises before the quiz when generated from pages', () async {
      final fake = _FakeAi();
      GrammarGenerator.chat = fake.call;

      final result = await GrammarGenerator.generate('imparfait', sourceText: 'Exercice 1 …');
      final titles = (result['widgets'] as List).map((w) => w['title']).toList();
      expect(titles.indexOf('book'), titles.indexOf('quiz') - 2, reason: 'book section + its exercise, then the quiz');
    });
  });

  group('TopicMatch', () {
    test('finds the same subject despite articles, accents and extra words', () {
      expect(TopicMatch.sameSubject("L'Impératif", 'imperatif'), isTrue);
      expect(TopicMatch.sameSubject('COD / COI', "COD et COI (Compléments d'Objet Direct et Indirect)"), isTrue);
      expect(TopicMatch.sameSubject('Le Conditionnel', 'Conditionnel'), isTrue);
    });

    test('keeps different subjects apart', () {
      expect(TopicMatch.sameSubject('Futur Proche', 'Futur Simple'), isFalse);
      expect(TopicMatch.sameSubject('Le Comparatif', 'Le Superlatif'), isFalse);
      expect(TopicMatch.sameSubject('Passé Composé', 'Imparfait'), isFalse);
    });
  });

  testWidgets('expression and mistake cards render', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_language': 'en'});
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MaterialApp(
        home: Scaffold(
          body: Column(children: [
            ExpressionCard.fromJson({
              'expression': 'Il faisait caillant',
              'meaning': 'It was freezing cold',
              'example': 'Hier, il faisait caillant à Liège.',
              'region': 'belgium',
              'register': 'familier',
            })!,
            MistakeCard.fromJson({'wrong': "J'ai allé", 'right': 'Je suis allé', 'why': 'aller uses être'})!,
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('En Belgique'), findsOneWidget);
    expect(find.text('« Il faisait caillant »'), findsOneWidget);
    expect(find.text('✅  Je suis allé'), findsOneWidget);
    expect(ExpressionCard.fromJson({'expression': ''}), isNull);
    expect(MistakeCard.fromJson({'wrong': 'x'}), isNull);
  });
}
