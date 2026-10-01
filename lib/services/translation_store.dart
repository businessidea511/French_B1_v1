import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/lessons/dynamic_lesson_page.dart';
import '../widgets/lesson_template.dart';
import 'api_client.dart';
import 'language_provider.dart';

/// Translations shared by every user.
///
/// The server keeps one translation per (language, text) in Supabase. The app
/// downloads all translations of the learner's language in one request, so
/// texts already translated for anyone show at once. Missing texts are
/// translated once by the server and saved for everybody. New grammar topics
/// and lessons are translated into every language when the admin saves them.
///
/// If the server store is not set up yet, [DeepSeekService] falls back to
/// translating on the device (the old way).
class TranslationStore {
  /// Languages the explanations are translated into (English is the source).
  static List<AppLanguage> get targets => [for (final l in AppLanguage.values) if (l != AppLanguage.english) l];

  /// 'ar' for 'العربية', 'Arabic' or 'ar'; null for English or unknown.
  static String? codeFor(String language) {
    for (final l in AppLanguage.values) {
      if (l.name == language || l.englishName == language || l.code == language) {
        return l == AppLanguage.english ? null : l.code;
      }
    }
    return null;
  }

  /// Short fingerprint of a text, the same on the server (sha1, 16 hex characters).
  static String hash(String text) => sha1.convert(utf8.encode(text)).toString().substring(0, 16);

  static final Map<String, String> _memory = {};
  static String _key(String code, String text) => '$code|${hash(text)}';

  static String? cached(String text, String language) {
    final code = codeFor(language);
    return code == null ? null : _memory[_key(code, text)];
  }

  /// Remembers a translation; [persist] also saves it on this device.
  static void remember(String code, String text, String translated, {bool persist = false}) {
    _memory[_key(code, text)] = translated;
    if (persist) {
      SharedPreferences.getInstance()
          .then((p) => p.setString('tr2_${code}_${hash(text)}', translated))
          .catchError((_) => false);
    }
  }

  /// Loads translations saved on this device (from earlier sessions).
  static Future<void> warmUp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (!key.startsWith('tr2_')) continue;
        final value = prefs.get(key);
        final parts = key.split('_');
        if (value is String && parts.length == 3) _memory['${parts[1]}|${parts[2]}'] = value;
      }
    } catch (e) {
      debugPrint('Could not load saved translations: $e');
    }
  }

  /// False once the server says the shared store is not set up (SQL not run).
  static bool serverAvailable = true;
  static final Map<String, Future<void>> _downloads = {};

  /// Downloads every shared translation of [language] (once per session).
  static Future<void> loadLanguage(String language) {
    final code = codeFor(language);
    if (code == null || !serverAvailable) return Future.value();
    return _downloads.putIfAbsent(code, () => _download(code));
  }

  static Future<void> _download(String code) async {
    try {
      final response = await http.get(ApiClient.uri('/api/translate?lang=$code')).timeout(const Duration(seconds: 25));
      if (response.statusCode == 503 || response.statusCode == 404) {
        serverAvailable = false;
        return;
      }
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
      final items = (jsonDecode(response.body) as Map)['items'];
      if (items is Map) {
        items.forEach((h, t) => _memory['$code|$h'] = '$t');
      }
      _dropOldCache();
    } catch (e) {
      debugPrint('Shared translations not loaded ($code): $e');
      _downloads.remove(code); // try again later
    }
  }

  /// The old per-device cache ('trans_…') is not needed once the shared one works.
  static bool _oldCacheDropped = false;
  static void _dropOldCache() {
    if (_oldCacheDropped) return;
    _oldCacheDropped = true;
    SharedPreferences.getInstance().then((prefs) async {
      for (final key in prefs.getKeys().where((k) => k.startsWith('trans_')).toList()) {
        await prefs.remove(key);
      }
    }).catchError((_) {});
  }

  /// Translates [texts] (at most 30, already missing) on the server, which saves
  /// them for everyone. Returns null for a text it could not translate.
  static Future<List<String?>> translateOnServer(List<String> texts, String code, {String? adminToken}) async {
    final response = await ApiClient.post(
      '/api/translate',
      {'lang': code, 'texts': texts},
      bearerToken: adminToken,
      timeout: const Duration(seconds: 90),
    );
    if (response.statusCode == 503 || response.statusCode == 404) serverAvailable = false;
    if (response.statusCode != 200) throw Exception('translate: ${ApiClient.errorMessage(response)}');
    final items = (jsonDecode(response.body) as Map)['items'];
    if (items is! List || items.length != texts.length) throw Exception('translate: wrong answer');
    return [
      for (var i = 0; i < texts.length; i++)
        if (items[i] is String && (items[i] as String).trim().isNotEmpty) items[i] as String else null,
    ];
  }

  /// Groups texts into requests of at most 30 texts and about 5000 characters.
  static List<List<String>> chunks(List<String> texts, {int maxItems = 30, int maxChars = 5000}) {
    final out = <List<String>>[];
    var chunk = <String>[];
    var chars = 0;
    for (final t in texts) {
      if (chunk.isNotEmpty && (chunk.length >= maxItems || chars + t.length > maxChars)) {
        out.add(chunk);
        chunk = [];
        chars = 0;
      }
      chunk.add(t);
      chars += t.length;
    }
    if (chunk.isNotEmpty) out.add(chunk);
    return out;
  }

  /// Translates [texts] into every language now and saves them for everyone.
  /// Used by the admin after creating a lesson or grammar topic, and by the
  /// "translate everything" button. Returns how many translations were added.
  static Future<int> pretranslate(
    List<String> texts, {
    String? adminToken,
    void Function(int done, int total)? onProgress,
  }) async {
    final unique = {for (final t in texts) if (t.trim().isNotEmpty) t}.toList();
    final jobs = <(String, List<String>)>[];
    for (final language in targets) {
      await loadLanguage(language.code);
      final missing = [for (final t in unique) if (!_memory.containsKey(_key(language.code, t))) t];
      for (final c in chunks(missing)) {
        jobs.add((language.code, c));
      }
    }
    if (!serverAvailable) throw Exception('The shared translation table is not set up yet (run supabase/translations.sql).');
    var done = 0;
    var added = 0;
    onProgress?.call(0, jobs.length);
    // Three requests at a time keeps the server and DeepSeek comfortable.
    var next = 0;
    Future<void> worker() async {
      while (next < jobs.length) {
        final (code, texts) = jobs[next++];
        try {
          final result = await translateOnServer(texts, code, adminToken: adminToken);
          for (var i = 0; i < texts.length; i++) {
            if (result[i] != null) {
              remember(code, texts[i], result[i]!);
              added++;
            }
          }
        } catch (e) {
          debugPrint('Pre-translation failed for a chunk ($code): $e');
        }
        onProgress?.call(++done, jobs.length);
      }
    }

    await Future.wait([for (var i = 0; i < 3; i++) worker()]);
    return added;
  }

  /// Progress of background pre-translation, shown in a small banner (null = hidden).
  static final ValueNotifier<String?> status = ValueNotifier(null);
  static Future<void> _backgroundJobs = Future.value();

  /// Pre-translates [texts] into every language in the background (one job
  /// after the other), showing progress in [status].
  static Future<void> pretranslateInBackground(String label, List<String> texts, {String? adminToken}) {
    final job = _backgroundJobs.then((_) async {
      status.value = '🌍 « $label » → ${targets.length} languages…';
      try {
        await pretranslate(texts, adminToken: adminToken, onProgress: (done, total) {
          if (total > 0) status.value = '🌍 « $label » → ${targets.length} languages… ${(100 * done / total).round()} %';
        });
        status.value = '✅ « $label » translated into ${targets.length} languages';
      } catch (e) {
        status.value = '⚠️ « $label » not translated in advance: $e';
      }
      await Future.delayed(const Duration(seconds: 5));
      status.value = null;
    });
    _backgroundJobs = job;
    return job;
  }

  /// Every English text a lesson or grammar topic shows translated — the same
  /// pieces the lesson widgets ask for — so it can be translated in advance.
  static List<String> lessonTexts(String title, List<dynamic>? content) {
    final out = <String>[title];
    void add(Object? value) {
      final text = DynamicLessonPage.clean('${value ?? ''}');
      if (text.isNotEmpty && !DynamicLessonPage.isPreamble(text)) out.add(text);
    }

    if (content == null || content.isEmpty) return out;
    final widgetFormat = content.first is Map && (content.first as Map).containsKey('type');
    for (final w in content) {
      if (w is! Map) continue;
      if (!widgetFormat) {
        add(w['title']);
        add(w['content']);
        continue;
      }
      switch ('${w['type'] ?? ''}') {
        case 'section_title':
          add(w['title']);
        case 'example':
          add(w['translation']);
        case 'french_tipbox':
          add(w['title'] ?? 'Vocabulary');
          for (final part in FrenchTipBox.translatedParts(DynamicLessonPage.clean('${w['frenchText'] ?? ''}'))) {
            out.add(part);
          }
        case 'tipbox':
          add(w['title'] ?? 'Note');
          add(w['content']);
        case 'table':
          final headers = [for (final h in (w['headers'] as List? ?? const [])) '$h'];
          out.addAll(headers.where((h) => h.trim().isNotEmpty));
          for (final row in (w['rows'] as List? ?? const [])) {
            if (row is! List) continue;
            for (var i = 0; i < row.length && i < headers.length; i++) {
              if (PremiumTable.shouldTranslateColumn(headers[i]) && '${row[i]}'.trim().isNotEmpty) out.add('${row[i]}');
            }
          }
        case 'exercise':
          if ('${w['instruction'] ?? ''}'.trim().isNotEmpty) out.add('${w['instruction']}');
          for (final item in (w['items'] as List? ?? const [])) {
            if (item is Map && '${item['explanation'] ?? ''}'.trim().isNotEmpty) out.add('${item['explanation']}');
          }
        case 'expression':
          if ('${w['meaning'] ?? ''}'.trim().isNotEmpty) out.add('${w['meaning']}');
        case 'mistake':
          if ('${w['why'] ?? ''}'.trim().isNotEmpty) out.add('${w['why']}');
        default:
          add(w['content']);
      }
    }
    return out;
  }
}
