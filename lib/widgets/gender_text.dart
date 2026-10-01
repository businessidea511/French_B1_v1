import 'package:flutter/material.dart';
import '../data/verb_list.dart';
import '../theme/app_theme.dart';
import '../services/ui_strings.dart';

/// One coloured piece of a French sentence: an article + its noun, 'm' or 'f'.
class GenderSpan {
  final int start, end;
  final String gender;
  const GenderSpan(this.start, this.end, this.gender);
}

/// Finds « le livre », « une petite maison », « du pain »… in French text, so
/// lessons can colour masculine nouns blue and feminine nouns pink.
class GenderMarker {
  static const _masculine = {'le', 'un', 'du', 'au', 'cet'};
  static const _feminine = {'la', 'une', 'cette'};

  /// « Je le vois », « tu la connais »: here le/la are pronouns, not articles.
  static const _pronounsBefore = {
    'je', 'j', 'tu', 'il', 'elle', 'on', 'nous', 'vous', 'ils', 'elles', 'ne', 'n', 'me', 'm', 'te', 't', 'se', 's',
    'qui', 'faut', 'peut', 'peux', 'veux', 'veut', 'dois', 'doit', 'vais', 'va', 'allons',
    'allez', 'vont', 'pouvez', 'voulez', 'devez', 'pouvons', 'voulons', 'devons', 'aller',
  };

  /// Words after le/la that are not nouns.
  static const _notNouns = {
    'plus', 'moins', 'mieux', 'pire', 'y', 'en', 'lui', 'leur', 'leurs', 'même', 'mêmes', 'mien', 'tien', 'sien',
    'mienne', 'tienne', 'sienne', 'nôtre', 'vôtre', 'tout', 'toute', 'à', 'de', 'des', 'et', 'ou',
    'peu',
  };

  /// Adjectives that come before the noun: « un petit chien » colours both words.
  static const _beforeNoun = {
    'petit', 'petite', 'grand', 'grande', 'bon', 'bonne', 'beau', 'bel', 'belle', 'nouveau', 'nouvel', 'nouvelle',
    'vieux', 'vieil', 'vieille', 'jeune', 'gros', 'grosse', 'mauvais', 'mauvaise', 'joli', 'jolie', 'premier',
    'première', 'dernier', 'dernière', 'autre', 'meilleur', 'meilleure', 'vrai', 'vraie', 'long', 'longue', 'haut',
    'haute', 'deuxième', 'troisième', 'prochain', 'prochaine', 'seul', 'seule',
  };

  static final _word = RegExp(r"[\p{L}]+(?:-[\p{L}]+)*", unicode: true);

  static List<GenderSpan> find(String text) {
    final words = _word.allMatches(text).toList();
    final spans = <GenderSpan>[];
    for (var i = 0; i < words.length - 1; i++) {
      final article = words[i].group(0)!.toLowerCase();
      final gender = _masculine.contains(article) ? 'm' : (_feminine.contains(article) ? 'f' : null);
      if (gender == null) continue;
      // Only a space between the article and the next word (not « le, » or « la. »).
      if (text.substring(words[i].end, words[i + 1].start).trim().isNotEmpty) continue;
      if (i > 0 && (article == 'le' || article == 'la')) {
        final before = words[i - 1].group(0)!.toLowerCase();
        final gap = text.substring(words[i - 1].end, words[i].start);
        if (gap.trim().isEmpty || gap.trim() == "'" || gap.trim() == '’') {
          if (_pronounsBefore.contains(before)) continue;
        }
        // « Donne-le », « Regarde-la »
        if (text.substring(0, words[i].start).endsWith('-')) continue;
      }
      var next = i + 1;
      var noun = words[next].group(0)!.toLowerCase();
      if (_notNouns.contains(noun) || commonVerbs.containsKey(noun)) continue;
      if (_beforeNoun.contains(noun) &&
          next + 1 < words.length &&
          text.substring(words[next].end, words[next + 1].start).trim().isEmpty) {
        final after = words[next + 1].group(0)!.toLowerCase();
        if (!_notNouns.contains(after) && !commonVerbs.containsKey(after)) next++;
      }
      spans.add(GenderSpan(words[i].start, words[next].end, gender));
      i = next;
    }
    return spans;
  }
}

/// French text with masculine nouns in blue and feminine nouns in pink.
class GenderText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool softWrap;

  const GenderText(this.text, {super.key, this.style, this.softWrap = true});

  @override
  Widget build(BuildContext context) {
    final spans = GenderMarker.find(text);
    if (spans.isEmpty) return Text(text, style: style, softWrap: softWrap);
    final children = <InlineSpan>[];
    var at = 0;
    for (final s in spans) {
      if (s.start > at) children.add(TextSpan(text: text.substring(at, s.start)));
      children.add(TextSpan(
        text: text.substring(s.start, s.end),
        style: TextStyle(color: s.gender == 'm' ? AppTheme.masculine : AppTheme.feminine),
      ));
      at = s.end;
    }
    if (at < text.length) children.add(TextSpan(text: text.substring(at)));
    return Text.rich(TextSpan(style: style, children: children), softWrap: softWrap);
  }
}

/// « ♂ le livre · ♀ la maison » key shown at the top of lessons.
class GenderLegend extends StatelessWidget {
  const GenderLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget chip(String sign, String example, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$sign $example', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        );
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip('♂', 'le livre', AppTheme.masculine),
        chip('♀', 'la maison', AppTheme.feminine),
        Text(tr(context, 'Blue = masculine, pink = feminine'),
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
      ],
    );
  }
}
