/// Detects when a new topic title is the same subject as an existing one,
/// e.g. "L'Impératif" vs "Impératif", or "COD / COI" vs
/// "COD et COI (Compléments d'Objet Direct et Indirect)".
class TopicMatch {
  static const _stopWords = {
    'le', 'la', 'les', 'l', 'un', 'une', 'des', 'de', 'du', 'd', 'et', 'en', 'avec',
    'the', 'and', 'of', 'a', 'an', 'in', 'french', 'francais',
  };

  static const _accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'î': 'i', 'ï': 'i',
    'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'œ': 'oe', 'æ': 'ae',
  };

  /// Meaningful words of a title: lowercase, no accents, no articles or punctuation.
  static Set<String> words(String title) {
    var t = title.toLowerCase();
    _accents.forEach((k, v) => t = t.replaceAll(k, v));
    return t
        .split(RegExp(r"[^a-z0-9]+"))
        .where((w) => w.isNotEmpty && !_stopWords.contains(w))
        .toSet();
  }

  /// True when one title's meaningful words are all contained in the other's.
  static bool sameSubject(String a, String b) {
    final wa = words(a), wb = words(b);
    if (wa.isEmpty || wb.isEmpty) return false;
    final (small, large) = wa.length <= wb.length ? (wa, wb) : (wb, wa);
    return small.any((w) => w.length >= 3) && large.containsAll(small);
  }

  /// The first item whose title is the same subject as [title], or null.
  static T? find<T>(Iterable<T> items, String title, String Function(T) titleOf) {
    for (final item in items) {
      if (sameSubject(titleOf(item), title)) return item;
    }
    return null;
  }
}
