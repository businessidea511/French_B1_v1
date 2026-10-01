import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:french_course_b1/services/language_provider.dart';
import 'package:french_course_b1/widgets/exercise_block.dart';

const _json = {
  'type': 'exercise',
  'title': 'Exercice 1 – Passé composé',
  'instruction': '',
  'items': [
    {'question': 'Je ___ au marché.', 'options': ['vais', 'va', 'allons'], 'correct': 0},
    {'question': 'Hier, nous ___ (aller) au cinéma.', 'answer': 'sommes allés', 'alternatives': ['sommes allées']},
    {'question': 'Décrivez votre quartier.', 'model_answer': "J'habite à Liège."},
    {'question': 'Broken: correct index out of range', 'options': ['a', 'b'], 'correct': 5},
    {'question': '', 'answer': 'empty question is dropped'},
  ],
};

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'selected_language': 'fr'});
  final block = ExerciseBlock.fromJson(_json)!;
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: block))),
  ));
  await tester.pumpAndSettle();
}

void main() {
  test('fromJson keeps valid items and drops malformed ones', () {
    final block = ExerciseBlock.fromJson(_json)!;
    expect(block.items.length, 3);
    expect(ExerciseBlock.fromJson({'items': []}), isNull);
  });

  testWidgets('multiple choice scores a correct tap', (tester) async {
    await _pump(tester);
    expect(find.text('0 / 2'), findsOneWidget);
    await tester.tap(find.text('vais'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('typed answer: accents hint, then alternative accepted', (tester) async {
    await _pump(tester);
    final field = find.byType(TextField);

    await tester.enterText(field, 'sommes alles');
    await tester.tap(find.text('Vérifier'));
    await tester.pumpAndSettle();
    expect(find.text('🟡 Presque ! Vérifiez les accents.'), findsOneWidget);

    await tester.enterText(field, '  Sommes  allées. ');
    await tester.tap(find.text('Vérifier'));
    await tester.pumpAndSettle();
    expect(find.text('✅ Correct !'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('open question reveals the model answer', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Voir un modèle de réponse'));
    await tester.pumpAndSettle();
    expect(find.text("J'habite à Liège."), findsOneWidget);
  });
}
