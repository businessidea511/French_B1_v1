import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/services/conjugator.dart';

List<String> forms(String verb, String mood, String tense) =>
    Conjugator.conjugate(verb)!.find(mood, tense)!.forms;

void main() {
  test('regular groups', () {
    expect(forms('parler', 'Indicatif', 'Présent'),
        ['je parle', 'tu parles', 'il/elle parle', 'nous parlons', 'vous parlez', 'ils/elles parlent']);
    expect(forms('finir', 'Subjonctif', 'Présent').first, 'que je finisse');
    expect(forms('vendre', 'Indicatif', 'Présent')[2], 'il/elle vend');
    expect(forms('aimer', 'Indicatif', 'Futur simple').first, "j'aimerai");
  });

  test('-er spelling changes', () {
    expect(forms('commencer', 'Indicatif', 'Présent')[3], 'nous commençons');
    expect(forms('commencer', 'Indicatif', 'Imparfait')[3], 'nous commencions');
    expect(forms('manger', 'Indicatif', 'Imparfait').first, 'je mangeais');
    expect(forms('acheter', 'Indicatif', 'Présent').first, "j'achète");
    expect(forms('appeler', 'Indicatif', 'Futur simple').first, "j'appellerai");
    expect(forms('préférer', 'Indicatif', 'Présent').last, 'ils/elles préfèrent');
    expect(forms('préférer', 'Indicatif', 'Futur simple').first, 'je préférerai');
    expect(forms('envoyer', 'Indicatif', 'Futur simple').first, "j'enverrai");
    expect(forms('payer', 'Indicatif', 'Présent').first, 'je paie');
    expect(forms('chercher', 'Indicatif', 'Présent').first, 'je cherche', reason: 'no è in chercher');
  });

  test('irregular verbs and prefixed verbs', () {
    expect(forms('être', 'Subjonctif', 'Présent')[3], 'que nous soyons');
    expect(forms('avoir', 'Subjonctif', 'Présent').first, "que j'aie");
    expect(forms('aller', 'Subjonctif', 'Présent').first, "que j'aille");
    expect(forms('faire', 'Subjonctif', 'Présent')[2], "qu'il/elle fasse");
    expect(forms('pouvoir', 'Subjonctif', 'Présent').first, 'que je puisse');
    expect(forms('devenir', 'Indicatif', 'Passé composé').first, 'je suis devenu(e)');
    expect(forms('comprendre', 'Indicatif', 'Présent').last, 'ils/elles comprennent');
    expect(forms('connaître', 'Indicatif', 'Passé simple').first, 'je connus');
    expect(forms('naître', 'Indicatif', 'Passé simple').first, 'je naquis');
    expect(forms('recevoir', 'Indicatif', 'Présent').first, 'je reçois');
    expect(forms('venir', 'Indicatif', 'Passé simple')[3], 'nous vînmes');
    expect(forms('dire', 'Indicatif', 'Présent')[4], 'vous dites');
    expect(forms('interdire', 'Indicatif', 'Présent')[4], 'vous interdisez');
    expect(forms('installer', 'Indicatif', 'Présent').first, "j'installe", reason: 'not matched as aller');
    expect(forms('falloir', 'Indicatif', 'Présent'), ['il faut']);
  });

  test('pronominal verbs, compound tenses and imperative', () {
    final t = Conjugator.conjugate("s'habiller")!;
    expect(t.auxiliary, 'être');
    expect(t.find('Indicatif', 'Présent')!.forms.first, "je m'habille");
    expect(t.find('Indicatif', 'Passé composé')!.forms[1], "tu t'es habillé(e)");
    expect(t.find('Impératif', 'Présent')!.forms, ['habille-toi', 'habillons-nous', 'habillez-vous']);
    expect(forms('se lever', 'Indicatif', 'Futur proche').first, 'je vais me lever');
    expect(forms('arriver', 'Indicatif', 'Passé récent').first, "je viens d'arriver");
    expect(forms('aller', 'Indicatif', 'Plus-que-parfait')[3], 'nous étions allé(e)s');
    expect(forms('parler', 'Conditionnel', 'Passé').first, "j'aurais parlé");
    expect(forms('aller', 'Impératif', 'Présent').first, 'va');
    final nonPersonal = Conjugator.conjugate('finir')!.find('Participe & infinitif', 'Formes')!;
    expect(nonPersonal.forms, contains('en finissant'));
  });

  test('rejects things that are not verbs', () {
    expect(Conjugator.conjugate('xyz'), isNull);
    expect(Conjugator.conjugate('pouvoi'), isNull);
    expect(Conjugator.speakable("qu'il/elle soit allé(e)"), "qu'il soit allé");
  });
}
