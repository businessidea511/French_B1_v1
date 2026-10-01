import 'package:flutter_test/flutter_test.dart';
import 'package:french_course_b1/services/tts_service.dart';

void main() {
  test('only the French sentence is read aloud', () {
    expect(TtsService.speakableText('Je parle à mon ami. (COI : à qui ? → à mon ami)'), 'Je parle à mon ami.');
    expect(TtsService.speakableText('Il se souvient de son enfance. (COI : de quoi ? → de son enfance)'),
        'Il se souvient de son enfance.');
    expect(TtsService.speakableText("qu'il/elle soit allé(e)"), "qu'il soit allé");
    expect(TtsService.speakableText('ils/elles sont allé(e)s'), 'ils sont allés');
    expect(TtsService.speakableText('✅ **Je mange** une pomme 🍎'), 'Je mange une pomme');
  });

  test('symbols are never read aloud', () {
    expect(TtsService.speakableText('« Bonjour ! » (salut'), 'Bonjour!');
    expect(TtsService.speakableText('le / la collègue'), 'le, la collègue');
    expect(TtsService.speakableText('Tu viens ?'), 'Tu viens?');
    expect(TtsService.speakableText('Tu viens ? Oui !', plainPunctuation: true), 'Tu viens. Oui.');
    expect(TtsService.speakableText('peut-être… demain'), 'peut-être. demain');
  });

  test('natural voices beat novelty voices', () {
    expect(TtsService.voiceScore('Thomas', 'fr-FR'), greaterThan(TtsService.voiceScore('Eddy (French (France))', 'fr-FR')));
    expect(TtsService.voiceScore('Grandma (French (France))', 'fr-FR'), lessThan(0));
    expect(TtsService.voiceScore('Microsoft Denise Online (Natural) - French (France)', 'fr-FR'),
        greaterThan(TtsService.voiceScore('Microsoft Hortense - French (France)', 'fr-FR')));
  });
}
