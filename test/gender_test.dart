import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/widgets/gender_text.dart';

List<String> marked(String text) =>
    [for (final s in GenderMarker.find(text)) '${s.gender}:${text.substring(s.start, s.end)}'];

void main() {
  test('articles + nouns are marked masculine or feminine', () {
    expect(marked('Le chat mange une pomme.'), ['m:Le chat', 'f:une pomme']);
    expect(marked('Je vais au marché acheter du pain.'), ['m:au marché', 'm:du pain']);
    expect(marked('Cette voiture est plus rapide que le train.'), ['f:Cette voiture', 'm:le train']);
  });

  test('adjectives before the noun are included', () {
    expect(marked('Il a une petite maison et un grand jardin.'), ['f:une petite maison', 'm:un grand jardin']);
  });

  test('pronouns le/la are not marked', () {
    expect(marked('Je le vois tous les jours.'), isEmpty);
    expect(marked('Tu la connais ?'), isEmpty);
    expect(marked('Je ne le sais pas.'), isEmpty);
    expect(marked('Il faut le faire.'), isEmpty);
    expect(marked('Donne-le à Marie.'), isEmpty);
  });

  test('superlatives and plurals are skipped', () {
    expect(marked('C\'est le plus beau.'), isEmpty);
    expect(marked('Les enfants jouent.'), isEmpty);
  });

  test('negation keeps the article', () {
    expect(marked("Il n'a pas le temps."), ['m:le temps']);
  });
}
