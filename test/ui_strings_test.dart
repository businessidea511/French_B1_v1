import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/services/ui_strings.dart';

Set<String> placeholders(String s) => {for (final m in RegExp(r'\{(\w+)\}').allMatches(s)) m.group(1)!};

void main() {
  test('every interface text exists in every language with the same placeholders', () {
    for (final entry in UiStrings.table.entries) {
      expect(entry.value.length, UiStrings.languages.length, reason: entry.key);
      final english = UiStrings.get('en', entry.key);
      for (final (i, text) in entry.value.indexed) {
        expect(text.trim(), isNotEmpty, reason: '${entry.key} [${UiStrings.languages[i]}]');
        expect(placeholders(text), placeholders(english), reason: '${entry.key} [${UiStrings.languages[i]}]');
      }
    }
  });

  test('placeholders are filled and English is the fallback', () {
    expect(UiStrings.get('fr', 'Level {n}', {'n': 3}), 'Niveau 3');
    expect(UiStrings.get('en', 'Next {n} cards ({left} left)', {'n': 20, 'left': 45}), 'Next 20 cards (45 left)');
    expect(UiStrings.get('en', 'DICTEE_KEY'), contains('wrong or missing'));
    expect(UiStrings.get('ar', 'Not in the table'), 'Not in the table');
  });
}
