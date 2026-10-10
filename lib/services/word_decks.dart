import 'package:flutter/painting.dart';
import '../data/expressions_data.dart';
import '../data/street_french_data.dart';
import '../data/vocabulary_data.dart';
import '../data/word_bank.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'deepseek_service.dart';
import 'progress_service.dart';
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
          'en': category.items[i].en, // the meaning follows a later change of language
          'example': category.items[i].example,
          'tip': [
            if (category.cognate && glosses[i].meaning != category.items[i].en) '🇬🇧 ${category.items[i].en}',
            if (glosses[i].note.isNotEmpty) glosses[i].note,
          ].join('\n'),
        }
    ];
  }

  static Map<String, String>? _bank;

  /// The English meaning of a card: kept on the card, or found in the word lists.
  static String? englishOf(Map<String, String> card) {
    final en = card['en']?.trim();
    if (en != null && en.isNotEmpty) return en;
    _bank ??= {
      for (final section in sections)
        for (final category in section.categories)
          for (final w in category.items) w.fr: w.en,
    };
    return _bank![card['front']?.trim()];
  }

  /// The cards with their meaning ("back") in [language]. A card saved while
  /// the app was in another language shows the meaning in the current one.
  /// Cards whose English meaning is unknown (or whose answer is French) stay as they are.
  static Future<List<Map<String, String>>> localize(List<Map<String, String>> cards, AppLanguage language) async {
    final english = cards.map(englishOf).whereType<String>().where((e) => e.isNotEmpty).toSet().toList();
    if (english.isEmpty) return cards;
    final translated = language == AppLanguage.english
        ? english
        : await DeepSeekService.translateBatch(english, language.name);
    final meaning = {for (var i = 0; i < english.length; i++) english[i]: translated[i]};
    return [
      for (final c in cards)
        if (englishOf(c) case final en? when meaning.containsKey(en)) {...c, 'en': en, 'back': meaning[en]!} else c,
    ];
  }

  static Future<void>? _repairing;

  /// Saved words (photo → words) kept from before the English meaning was
  /// saved: ask the AI once for it, so they follow the app language too.
  /// Returns French → English for the words it repaired.
  static Future<Map<String, String>> repairSavedWords() async {
    final progress = ProgressService.instance;
    final missing = [
      for (final w in progress.savedWords)
        if (englishOf(w) == null && (w['front'] ?? '').trim().isNotEmpty) w['front']!,
    ];
    if (missing.isEmpty) return const {};
    final found = <String, String>{};
    _repairing ??= () async {
      try {
        final r = await DeepSeekService.chatJson([
          {
            'role': 'system',
            'content': 'Give the short English meaning (1-4 words) of each French word or expression. '
                'Return JSON: {"en": {"<French exactly as given>": "<English>"}}',
          },
          {'role': 'user', 'content': jsonEncode(missing)},
        ], temperature: 0.1, maxTokens: 1500);
        for (final e in ((r['en'] as Map?) ?? const {}).entries) {
          if ('${e.value}'.trim().isNotEmpty) found['${e.key}'] = '${e.value}'.trim();
        }
        if (found.isNotEmpty) progress.setSavedEnglish(found);
      } catch (_) {
        // Keep the meanings saved with the words.
      }
    }();
    await _repairing;
    _repairing = null;
    return {
      for (final w in progress.savedWords)
        if (missing.contains(w['front']) && w['en'] != null) w['front']!: w['en']!,
    };
  }

  static Color get masculine => AppTheme.masculine;
  static Color get feminine => AppTheme.feminine;

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
