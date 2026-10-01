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
}
