import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/services/language_provider.dart';
import 'package:french_course_b1/services/progress_service.dart';
import 'package:french_course_b1/services/translation_store.dart';
import 'package:french_course_b1/services/word_decks.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProgressService.instance.reset();
    TranslationStore.serverAvailable = false; // no network in tests
  });

  test('a word saved in English is shown in Arabic after a change of language', () async {
    // Saved from a photo while the app was in English.
    final saved = {'front': 'la bouilloire', 'back': 'kettle', 'en': 'kettle', 'example': '', 'tip': ''};
    TranslationStore.remember('ar', 'kettle', 'غلاية');

    final arabic = await WordDecks.localize([saved], AppLanguage.arabic);
    expect(arabic.single['back'], 'غلاية');
    expect(arabic.single['en'], 'kettle', reason: 'the English meaning stays on the card');

    final english = await WordDecks.localize(arabic, AppLanguage.english);
    expect(english.single['back'], 'kettle');
  });

  test('cards from the word lists find their English meaning even if saved without it', () async {
    final listWord = WordDecks.sections.first.categories.first.items.first;
    final oldCard = {'front': listWord.fr, 'back': 'saved long ago in another language'};
    expect(WordDecks.englishOf(oldCard), listWord.en);

    // A French answer (conjugation card) is never "translated".
    final conjugation = {'front': 'aller → nous (imparfait)', 'back': 'nous allions'};
    expect(await WordDecks.localize([conjugation], AppLanguage.arabic), [conjugation]);
  });

  test('old photo words get their English meaning, review cards too', () {
    final progress = ProgressService.instance;
    progress.saveWords([
      {'front': 'la bouilloire', 'back': 'kettle', 'example': '', 'tip': ''},
    ]);
    expect(WordDecks.englishOf(progress.savedWords.single), isNull);

    progress.setSavedEnglish({'la bouilloire': 'kettle'});
    expect(progress.savedWords.single['en'], 'kettle');
    expect(progress.dueCards.single['en'], 'kettle');
  });
}
