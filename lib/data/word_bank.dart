/// Shared model for the word sections (Vocabulary, Expressions, Street French).
/// French stays French; [WordItem.en], [WordItem.note], [WordCategory.subtitle]
/// and [WordCategory.intro] are English and are translated on screen.
class WordItem {
  final String fr;
  final String en;
  final String example;
  final String note;

  /// '' (neutral), 'familier', 'vulgaire', 'belgique', 'france', 'verlan', 'sms', 'soutenu'.
  final String tag;

  const WordItem(this.fr, this.en, {this.example = '', this.note = '', this.tag = ''});
}

class WordCategory {
  final String id;
  final String icon;
  final String title; // French
  final String subtitle; // English
  final String group; // heading the category is listed under
  final String intro; // English explanation shown above the words
  final bool cognate; // [WordItem.en] is the English look-alike word
  final List<WordItem> items;

  const WordCategory({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.items,
    this.group = '',
    this.intro = '',
    this.cognate = false,
  });
}

class WordSection {
  final String id;
  final String icon;
  final String title;
  final String intro; // English
  final List<WordCategory> categories;

  const WordSection({
    required this.id,
    required this.icon,
    required this.title,
    required this.intro,
    required this.categories,
  });

  int get wordCount => categories.fold(0, (n, c) => n + c.items.length);
}

/// Short name used by the word lists in lib/data.
typedef W = WordItem;
