import 'package:flutter/painting.dart';
import '../data/expressions_data.dart';
import '../data/street_french_data.dart';
import '../data/vocabulary_data.dart';
import '../data/word_bank.dart';
import 'deepseek_service.dart';
import 'language_provider.dart';

/// Meaning and note of a word, in the learner's language.
class WordGloss {
  final String meaning;
  final String note;
  const WordGloss(this.meaning, this.note);
}

class WordDecks {
  static const List<WordSection> sections = [vocabularySection, expressionsSection, streetFrenchSection];

  /// Translates the English meanings and notes of [items] into [language]
  /// (one or two requests, cached on the device).
  static Future<List<WordGloss>> glosses(List<WordItem> items, AppLanguage language) async {
    if (language == AppLanguage.english) {
      return [for (final w in items) WordGloss(w.en, w.note)];
    }
    final texts = [for (final w in items) w.en, for (final w in items) w.note];
    final translated = await DeepSeekService.translateBatch(texts, language.name);
    return [
      for (var i = 0; i < items.length; i++) WordGloss(translated[i], translated[items.length + i]),
    ];
  }

  /// Flashcards for a category: French on the front, meaning on the back.
  static List<Map<String, String>> cards(WordCategory category, List<WordGloss> glosses) {
    return [
      for (var i = 0; i < category.items.length; i++)
        {
          'front': category.items[i].fr,
          'back': glosses[i].meaning,
          'example': category.items[i].example,
          'tip': [
            if (category.cognate && glosses[i].meaning != category.items[i].en) '🇬🇧 ${category.items[i].en}',
            if (glosses[i].note.isNotEmpty) glosses[i].note,
          ].join('\n'),
        }
    ];
  }

  static const Color masculine = Color(0xFF60A5FA);
  static const Color feminine = Color(0xFFF472B6);

  /// 'm', 'f' or null, from the article: le/un/(m) → masculine, la/une/(f) → feminine.
  /// Pairs like « le / la collègue » or « le père / la mère » have no single gender.
  static String? gender(String french) {
    final f = french.toLowerCase().trim();
    if (f.contains('/') || f.contains('(m/f)')) return null;
    if (f.startsWith('le ') || f.startsWith('un ') || f.contains('(m)')) return 'm';
    if (f.startsWith('la ') || f.startsWith('une ') || f.contains('(f)')) return 'f';
    return null;
  }

  static String tagLabel(String tag) => switch (tag) {
        'familier' => '💬 familier',
        'vulgaire' => '⚠️ vulgaire',
        'belgique' => '🇧🇪 Belgique',
        'france' => '🇫🇷 France',
        'verlan' => '🔄 verlan',
        'sms' => '📱 SMS',
        'soutenu' => '🎩 soutenu',
        _ => '',
      };
}
