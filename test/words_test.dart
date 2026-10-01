import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:french_course_b1/data/vocabulary_data.dart';
import 'package:french_course_b1/pages/flashcards/flashcards_page.dart';
import 'package:french_course_b1/pages/verbs/verbs_page.dart';
import 'package:french_course_b1/pages/words/word_category_page.dart';
import 'package:french_course_b1/services/language_provider.dart';
import 'package:french_course_b1/services/word_decks.dart';

Future<void> _pump(WidgetTester tester, Widget page) async {
  SharedPreferences.setMockInitialValues({'selected_language': 'en'});
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp(home: page),
  ));
  await tester.pumpAndSettle();
}

void main() {
  test('every word list is complete and has unique ids', () {
    final ids = <String>{};
    const tags = {'', 'familier', 'vulgaire', 'belgique', 'france', 'verlan', 'sms', 'soutenu'};
    for (final section in WordDecks.sections) {
      expect(section.categories, isNotEmpty);
      for (final c in section.categories) {
        expect(ids.add('${section.id}/${c.id}'), isTrue, reason: 'duplicate id ${c.id}');
        expect(c.items.length, greaterThanOrEqualTo(10), reason: '${c.id} is too short');
        final seen = <String>{};
        for (final w in c.items) {
          expect(w.fr.trim(), isNotEmpty);
          expect(w.en.trim(), isNotEmpty, reason: '${w.fr} has no meaning');
          expect(tags, contains(w.tag), reason: '${w.fr}: unknown tag ${w.tag}');
          expect(seen.add(w.fr), isTrue, reason: '${w.fr} appears twice in ${c.id}');
        }
      }
    }
  });

  test('flashcards from a cognate list show the English word as a tip', () {
    final category = vocabularySection.categories.firstWhere((c) => c.id == 'cog_tion');
    final glosses = [for (final w in category.items) WordGloss('translated', w.note)];
    final cards = WordDecks.cards(category, glosses);
    expect(cards.first['front'], 'la nation');
    expect(cards.first['back'], 'translated');
    expect(cards.first['tip'], contains('🇬🇧 nation'));
  });

  testWidgets('a word list opens its flashcards', (tester) async {
    final category = vocabularySection.categories.firstWhere((c) => c.id == 'faux_amis');
    await _pump(tester, WordCategoryPage(category: category));
    expect(find.text('actuellement'), findsOneWidget);
    expect(find.text('currently, at the moment'), findsOneWidget);

    await tester.tap(find.text('Flashcards · ${category.items.length}'));
    await tester.pumpAndSettle();
    expect(find.byType(FlashcardsPage), findsOneWidget);
    expect(find.text('1 / 20'), findsOneWidget, reason: 'big lists are studied 20 cards at a time');

    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je savais'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 20'), findsOneWidget);
  });

  testWidgets('a verb in the vocabulary opens its conjugation', (tester) async {
    final verbs = vocabularySection.categories.firstWhere((c) => c.id == 'verbes');
    await _pump(tester, WordCategoryPage(category: verbs));
    await tester.tap(find.byTooltip('Conjugaison').first);
    await tester.pumpAndSettle();
    expect(find.byType(VerbsPage), findsOneWidget);
    expect(find.text('je suis'), findsOneWidget);
  });

  testWidgets('verbs page shows every mood and conjugates any verb', (tester) async {
    await _pump(tester, const VerbsPage());
    expect(find.text('je parle'), findsOneWidget);

    await tester.tap(find.text('Subjonctif'));
    await tester.pumpAndSettle();
    expect(find.text('que je parle'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'se souvenir');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('que je me souvienne'), findsOneWidget, reason: 'the chosen mood is kept');
    expect(find.text('Auxiliaire : être'), findsOneWidget);
  });
}
