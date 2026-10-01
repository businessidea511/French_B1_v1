import 'dart:math';
import '../data/expressions_data.dart';
import '../data/verb_list.dart';
import '../data/vocabulary_data.dart';
import '../data/word_bank.dart';
import 'conjugator.dart';

/// Removes French accents: "élève" → "eleve".
String stripAccents(String s) => s
    .replaceAll(RegExp('[àâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[ùûü]'), 'u')
    .replaceAll('ç', 'c')
    .replaceAll('œ', 'oe');

// ── Conjugation game ─────────────────────────────────────────────────────────

class ConjQuestion {
  final String verb;
  final String mood;
  final String tense;
  final String prefix; // shown before the blank: "nous", "que j'", "qu'elle", "(tu)"
  final String answer; // expected words after the prefix, e.g. "avons pris", "allé(e)"
  final String fullForm;

  const ConjQuestion(this.verb, this.mood, this.tense, this.prefix, this.answer, this.fullForm);

  String get tenseLabel => mood == 'Indicatif' ? tense : '$mood ${tense.toLowerCase()}';
}

enum AnswerResult { correct, accents, wrong }

class ConjugationQuiz {
  static const Map<String, List<(String, String)>> levels = {
    'Facile': [('Indicatif', 'Présent'), ('Indicatif', 'Passé composé'), ('Indicatif', 'Futur proche')],
    'Moyen': [
      ('Indicatif', 'Présent'), ('Indicatif', 'Passé composé'), ('Indicatif', 'Imparfait'),
      ('Indicatif', 'Futur simple'), ('Conditionnel', 'Présent'), ('Impératif', 'Présent'),
    ],
    'Difficile': [
      ('Indicatif', 'Imparfait'), ('Indicatif', 'Futur simple'), ('Indicatif', 'Plus-que-parfait'),
      ('Conditionnel', 'Présent'), ('Conditionnel', 'Passé'), ('Subjonctif', 'Présent'), ('Subjonctif', 'Passé'),
    ],
  };

  static final List<String> _verbs =
      commonVerbs.keys.where((v) => v != 'falloir' && v != 'pleuvoir').take(120).toList();

  static final _subject = RegExp(r"^((?:que |qu')?(?:je |j'|tu |il/elle |nous |vous |ils/elles ))(.+)$");

  static ConjQuestion make(Random random, String level) {
    final tenses = levels[level] ?? levels['Facile']!;
    while (true) {
      final verb = _verbs[random.nextInt(_verbs.length)];
      final (mood, tense) = tenses[random.nextInt(tenses.length)];
      final forms = Conjugator.conjugate(verb)?.find(mood, tense)?.forms;
      if (forms == null || forms.isEmpty) continue;
      final i = random.nextInt(forms.length);
      final form = forms[i];
      if (mood == 'Impératif') {
        return ConjQuestion(verb, mood, tense, '(${['tu', 'nous', 'vous'][i]})', form, form);
      }
      final m = _subject.firstMatch(form);
      if (m == null) continue;
      var prefix = m.group(1)!.trim();
      if (prefix.contains('il/elle') || prefix.contains('ils/elles')) {
        final feminine = random.nextBool();
        prefix = prefix
            .replaceAll('ils/elles', feminine ? 'elles' : 'ils')
            .replaceAll('il/elle', feminine ? 'elle' : 'il');
      }
      return ConjQuestion(verb, mood, tense, prefix, m.group(2)!, form);
    }
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll(RegExp(r'[.!?,;]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _tokensMatch(List<String> input, List<String> expected, bool ignoreAccents) {
    if (input.length != expected.length) return false;
    for (var i = 0; i < expected.length; i++) {
      var exp = expected[i];
      var got = input[i];
      if (ignoreAccents) {
        exp = stripAccents(exp);
        got = stripAccents(got);
      }
      if (exp.contains('(')) {
        // allé(e)(s) accepts allé, allée, allés, allées
        final base = exp.replaceAll(RegExp(r'\([^)]*\)'), '');
        if (!{exp, base, '${base}e', '${base}s', '${base}es'}.contains(got)) return false;
      } else if (exp != got) {
        return false;
      }
    }
    return true;
  }

  static AnswerResult check(String input, String expected) {
    final got = _normalize(input).split(' ');
    final exp = _normalize(expected).split(' ');
    if (_tokensMatch(got, exp, false)) return AnswerResult.correct;
    if (_tokensMatch(got, exp, true)) return AnswerResult.accents;
    return AnswerResult.wrong;
  }

  /// Wrong but plausible options for a multiple-choice version (duel).
  static List<String> distractors(ConjQuestion q, Random random) {
    final table = Conjugator.conjugate(q.verb)!;
    final pool = <String>{};
    for (final t in table.tenses) {
      if (t.labels != null) continue;
      for (final f in t.forms) {
        final m = _subject.firstMatch(f);
        final rest = m?.group(2) ?? f;
        if (rest != q.answer) pool.add(rest);
      }
    }
    final list = pool.toList()..shuffle(random);
    return list.take(3).toList();
  }
}

// ── Dictée ───────────────────────────────────────────────────────────────────

enum WordMark { ok, accent, wrong, missing }

class DicteeWord {
  final String word;
  final WordMark mark;
  const DicteeWord(this.word, this.mark);
}

class Dictee {
  static const levels = ['Facile', 'Moyen', 'Difficile'];

  static List<String>? _pool;

  /// Example sentences from the word lists (no slang or swear words).
  static List<String> get pool => _pool ??= {
        for (final section in [vocabularySection, expressionsSection])
          for (final c in section.categories)
            for (final WordItem w in c.items)
              if (w.example.isNotEmpty &&
                  w.tag != 'vulgaire' &&
                  RegExp(r'[.!?]$').hasMatch(w.example) &&
                  !w.example.contains('—') &&
                  !w.example.contains('/'))
                w.example,
      }.toList();

  static int wordCount(String s) => s.trim().split(RegExp(r'\s+')).length;

  static List<String> sentences(String level, Random random, {int count = 8}) {
    bool fits(String s) {
      final n = wordCount(s);
      return switch (level) { 'Facile' => n <= 5, 'Moyen' => n >= 6 && n <= 9, _ => n >= 10 };
    }

    final list = pool.where(fits).toList()..shuffle(random);
    return list.take(count).toList();
  }

  static List<String> _tokens(String s) =>
      s.replaceAll('’', "'").split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

  static String _clean(String t) => t.toLowerCase().replaceAll(RegExp(r'''[.,!?;:«»"()]'''), '');

  /// Compares what was typed with the sentence, word by word (longest common
  /// subsequence), and marks every word of the sentence.
  static List<DicteeWord> compare(String typed, String sentence) {
    final exp = _tokens(sentence);
    final got = _tokens(typed);
    final e = [for (final t in exp) _clean(t)];
    final g = [for (final t in got) _clean(t)];
    final ea = [for (final t in e) stripAccents(t)];
    final ga = [for (final t in g) stripAccents(t)];
    final n = e.length, m = g.length;
    final dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));
    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        dp[i][j] = ea[i] == ga[j] ? dp[i + 1][j + 1] + 1 : max(dp[i + 1][j], dp[i][j + 1]);
      }
    }
    final out = <DicteeWord>[];
    var i = 0, j = 0;
    while (i < n) {
      if (j < m && ea[i] == ga[j]) {
        out.add(DicteeWord(exp[i], e[i] == g[j] ? WordMark.ok : WordMark.accent));
        i++;
        j++;
      } else if (j < m && dp[i][j + 1] >= dp[i + 1][j]) {
        j++; // extra word typed
      } else {
        out.add(DicteeWord(exp[i], WordMark.missing));
        i++;
      }
    }
    return out;
  }

  /// 0–100: full points per correct word, half for an accent mistake, minus
  /// extra words typed.
  static int score(String typed, String sentence) {
    final marks = compare(typed, sentence);
    if (marks.isEmpty) return 0;
    final points = marks.fold<double>(
        0, (p, w) => p + (w.mark == WordMark.ok ? 1 : (w.mark == WordMark.accent ? 0.5 : 0)));
    final extra = max(0, _tokens(typed).length - marks.where((w) => w.mark != WordMark.missing).length);
    return ((points - extra * 0.5).clamp(0, marks.length) / marks.length * 100).round();
  }
}

// ── Word of the day ──────────────────────────────────────────────────────────

class WordOfTheDay {
  static List<WordItem>? _pool;

  static List<WordItem> get pool => _pool ??= [
        for (final c in expressionsSection.categories) ...c.items,
        for (final c in vocabularySection.categories)
          if (c.id == 'faux_amis' || c.id == 'cog_circonflexe') ...c.items,
      ];

  static WordItem forDay(DateTime day) {
    final days = DateTime(day.year, day.month, day.day).difference(DateTime(2024, 1, 1)).inDays;
    return pool[(days * 7919) % pool.length];
  }
}
