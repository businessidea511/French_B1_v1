import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson_topic.dart';
import '../models/grammar_topic.dart';
import 'admin_auth.dart';
import 'api_client.dart';

class LessonsProvider extends ChangeNotifier {
  List<LessonTopic> _customLessons = [];
  List<GrammarTopic> _customGrammar = [];
  List<String> _hiddenLessons = [];
  List<String> _hiddenGrammar = [];
  
  static const String _prefKeyLessons = 'custom_lessons';
  static const String _prefKeyGrammar = 'custom_grammar';
  static const String _prefKeyHiddenLessons = 'hidden_lessons';
  static const String _prefKeyHiddenGrammar = 'hidden_grammar';

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  LessonsProvider() {
    debugPrint("📚 LessonsProvider initialized");
    _init();
  }

  Future<void> _init() async {
    await _loadData();
    await seedData(); // Ensure original content is in cloud
  }

  List<LessonTopic> get allLessons {
    final Map<String, LessonTopic> merged = {};
    // Add hardcoded first
    for (var l in lessonTopics) {
      if (!_hiddenLessons.contains(l.id)) {
        merged[l.id] = l;
      }
    }
    // Overwrite with cloud/custom versions if they exist
    for (var l in _customLessons) {
      if (!_hiddenLessons.contains(l.id)) {
        merged[l.id] = l;
      }
    }
    return merged.values.toList();
  }

  List<GrammarTopic> get allGrammar {
    final Map<String, GrammarTopic> merged = {};
    for (var g in grammarTopics) {
      if (!_hiddenGrammar.contains(g.id)) {
        merged[g.id] = g;
      }
    }
    for (var g in _customGrammar) {
      if (!_hiddenGrammar.contains(g.id)) {
        merged[g.id] = g;
      }
    }
    return merged.values.toList();
  }

  Future<void> _loadData() async {
    try {
      debugPrint("📚 Loading lessons from prefs...");
      final prefs = await SharedPreferences.getInstance();
      
      // Load hidden lists
      _hiddenLessons = prefs.getStringList(_prefKeyHiddenLessons) ?? [];
      _hiddenGrammar = prefs.getStringList(_prefKeyHiddenGrammar) ?? [];
      
      // 1. Load Local Data first (Instant UI)
      final String? lessonsJson = prefs.getString(_prefKeyLessons);
      if (lessonsJson != null) {
        final List<dynamic> decoded = jsonDecode(lessonsJson);
        _customLessons = decoded.map((item) => LessonTopic.fromJson(item)).toList();
        notifyListeners();
      }

      final String? grammarJson = prefs.getString(_prefKeyGrammar);
      if (grammarJson != null) {
        final List<dynamic> decoded = jsonDecode(grammarJson);
        _customGrammar = decoded.map((item) => GrammarTopic.fromJson(item)).toList();
        notifyListeners();
      }
      debugPrint("📚 Local data loaded");
    } catch (e) {
      debugPrint("📚 Local data load error: $e");
    }
    
    // 2. Sync from Supabase Cloud (Background)
    syncFromCloud(); // Don't await here to prevent blocking UI
  }

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  String? _lastError;
  String? get lastError => _lastError;

  Future<Map<String, dynamic>> testConnection() async {
    final client = _supabase;
    if (client == null) return {'status': 'error', 'message': 'Supabase not initialized'};
    
    try {
      final startTime = DateTime.now();
      // Test simple select
      final response = await client.from('lessons').select('id').limit(1);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      // Test schema (check if columns exist)
      bool schemaOk = true;
      String schemaMsg = 'Schema OK';
      try {
        await client.from('lessons').select('description, content').limit(1);
      } catch (e) {
        schemaOk = false;
        schemaMsg = 'Missing columns: description or content. Run the SQL fix.';
      }
      
      return {
        'status': 'success',
        'latency': '${duration}ms',
        'rows': response.length,
        'schema': schemaMsg,
        'schemaOk': schemaOk,
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<void> syncFromCloud() async {
    if (_isSyncing) return;
    
    try {
      _isSyncing = true;
      _lastError = null;
      notifyListeners();
      
      debugPrint('☁️ Syncing from Supabase Cloud...');
      final client = _supabase;
      if (client == null) {
        debugPrint('❌ Supabase client is NULL');
        _isSyncing = false;
        notifyListeners();
        return;
      }

      // Sync Lessons - pull ALL cloud items (both custom and updated hardcoded)
      final List<dynamic> cloudLessons = await client.from('lessons').select();
      _customLessons = cloudLessons
          .map((item) => LessonTopic.fromJson(item))
          .toList();
      
      // Sync Grammar - pull ALL cloud items
      final List<dynamic> cloudGrammar = await client.from('grammar').select();
      _customGrammar = cloudGrammar
          .map((item) => GrammarTopic.fromJson(item))
          .toList();

      notifyListeners();
      await _saveLocalData();
      debugPrint('✅ Cloud Sync Complete: ${_customLessons.length} lessons, ${_customGrammar.length} grammar items pulled.');
      
      // Verification log for specifically requested topic
      final metiersCloud = _customLessons.where((l) => l.id == 'metiers').firstOrNull;
      if (metiersCloud != null) {
        debugPrint('💼 "Les Métiers" found in cloud sync. Widgets: ${metiersCloud.content?.length ?? 0}');
      } else {
        debugPrint('💼 "Les Métiers" NOT found in cloud sync.');
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('⚠️ Cloud sync failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> addLesson(Map<String, dynamic> lessonData) async {
    final String id = 'custom_lesson_${DateTime.now().millisecondsSinceEpoch}';
    
    // Intelligent content extraction & normalization
    final dynamic rawContent = lessonData['widgets'] ?? lessonData['sections'] ?? lessonData['content'] ?? [];
    final List<dynamic> rawWidgets = rawContent is List ? rawContent : [];
    final List<Map<String, dynamic>> normalizedWidgets = rawWidgets.map((w) {
      if (w is! Map) return <String, dynamic>{};
      final Map<String, dynamic> map = Map<String, dynamic>.from(w);
      // Map common alternative keys to standard ones
      if (map.containsKey('meaning')) map['translation'] = map['meaning'];
      if (map.containsKey('english') && !map.containsKey('translation')) map['translation'] = map['english'];
      if (map.containsKey('arabic') && !map.containsKey('translation')) map['translation'] = map['arabic'];
      if (map.containsKey('explanation') && !map.containsKey('content')) map['content'] = map['explanation'];
      if (map.containsKey('text') && !map.containsKey('content')) map['content'] = map['text'];
      return map;
    }).where((w) => w.isNotEmpty).toList();

    // Robust Title extraction
    String title = lessonData['title'] ?? lessonData['topic'] ?? 'Untitled Lesson';
    if (title == 'Untitled Lesson' && normalizedWidgets.isNotEmpty) {
      final first = normalizedWidgets.first;
      title = first['title'] ?? first['content']?.toString().split('\n').first ?? title;
    }

    final newLesson = LessonTopic(
      id: id,
      title: title,
      subtitle: lessonData['subtitle'] ?? lessonData['description'] ?? '',
      icon: lessonData['icon'] ?? '📖',
      description: lessonData['subtitle'] ?? title,
      content: normalizedWidgets,
    );

    if (normalizedWidgets.isEmpty) {
      debugPrint('⚠️ Warning: Generated lesson has no widgets!');
    }

    _customLessons.add(newLesson);
    notifyListeners();
    await _saveLocalData();

    // Push to Cloud
    try {
      debugPrint('☁️ Pushing lesson to Supabase: $id');
      await _cloudUpsert('lessons', [{
        'id': id,
        'title': newLesson.title,
        'subtitle': newLesson.subtitle,
        'icon': newLesson.icon,
        'description': newLesson.description,
        'content': newLesson.content,
      }]);
      debugPrint('✅ Lesson saved to cloud');
    } catch (e, stack) {
      _lastError = e.toString();
      notifyListeners();
      debugPrint('❌ Cloud insert error: $e');
      debugPrint('Stack: $stack');
      // Rethrow so UI can show the real error
      rethrow;
    }
  }



  Future<void> updateLesson(String id, Map<String, dynamic> lessonData) async {
    final original = allLessons.where((l) => l.id == id).firstOrNull;
    final List<dynamic> originalWidgets = List<dynamic>.from(original?.content ?? []);

    // ── APPEND-ONLY MERGE ──
    // AI now returns ONLY new widgets in "new_widgets" key
    final List<dynamic> newWidgets;
    if (lessonData.containsKey('new_widgets')) {
      // New append-only format: AI returned only new content
      final raw = lessonData['new_widgets'];
      newWidgets = raw is List ? List<dynamic>.from(raw) : [];
    } else {
      // Legacy fallback: AI returned full "widgets" array
      // Safety check: if returned widgets are fewer than original, treat as new-only
      final raw = lessonData['widgets'] ?? lessonData['content'] ?? lessonData['sections'] ?? [];
      final List<dynamic> returned = raw is List ? List<dynamic>.from(raw) : [];
      if (returned.length < originalWidgets.length) {
        debugPrint('⚠️ SAFETY: AI returned ${returned.length} widgets but original has ${originalWidgets.length}. Treating as NEW widgets only.');
        newWidgets = returned;
      } else {
        // AI returned more widgets than original - extract only the new tail
        newWidgets = returned.sublist(originalWidgets.length);
        debugPrint('📊 Extracted ${newWidgets.length} new widgets from ${returned.length} total (original had ${originalWidgets.length})');
      }
    }

    // Build final merged content: original + new
    final List<dynamic> mergedContent = [...originalWidgets, ...newWidgets];
    debugPrint('✅ MERGE RESULT: ${originalWidgets.length} original + ${newWidgets.length} new = ${mergedContent.length} total widgets');

    final updated = LessonTopic(
      id: id,
      title: lessonData['title'] ?? original?.title ?? 'Untitled',
      subtitle: lessonData['subtitle'] ?? original?.subtitle ?? '',
      icon: lessonData['icon'] ?? original?.icon ?? '📖',
      description: lessonData['description'] ?? lessonData['subtitle'] ?? original?.description ?? '',
      content: mergedContent,
    );

    final index = _customLessons.indexWhere((l) => l.id == id);
    if (index != -1) {
      _customLessons[index] = updated;
    } else {
      debugPrint('📥 Adding hardcoded lesson "$id" to custom list for update');
      _customLessons.add(updated);
    }
    notifyListeners();
    await _saveLocalData();

    // Update Cloud
    try {
      await _cloudUpsert('lessons', [{
        'id': id,
        'title': updated.title,
        'subtitle': updated.subtitle,
        'icon': updated.icon,
        'description': updated.description,
        'content': updated.content,
      }]);
      debugPrint('☁️ Lesson "$id" updated in cloud (${mergedContent.length} widgets)');
    } catch (e) {
      debugPrint('Cloud update error: $e');
      // Surface the failure: the change is only saved on this device.
      rethrow;
    }
  }

  Future<void> addGrammar(Map<String, dynamic> grammarData) async {
    final String id = 'custom_grammar_${DateTime.now().millisecondsSinceEpoch}';
    // Support new 'widgets' format AND old 'sections'/'content' format
    final dynamic rawContent = grammarData['widgets'] ?? grammarData['sections'] ?? grammarData['content'] ?? [];
    final newGrammar = GrammarTopic(
      id: id,
      title: grammarData['title'] ?? 'Untitled',
      subtitle: grammarData['subtitle'] ?? '',
      icon: grammarData['icon'] ?? '📖',
      description: grammarData['description'] ?? grammarData['subtitle'] ?? grammarData['title'] ?? '',
      content: rawContent is List ? rawContent : [],
    );

    _customGrammar.add(newGrammar);
    notifyListeners();
    await _saveLocalData();

    // Push to Cloud
    try {
      debugPrint('☁️ Pushing grammar to Supabase: $id');
      await _cloudUpsert('grammar', [{
        'id': id,
        'title': newGrammar.title,
        'subtitle': newGrammar.subtitle,
        'icon': newGrammar.icon,
        'description': newGrammar.description,
        'content': newGrammar.content,
      }]);
      debugPrint('✅ Grammar saved to cloud');
    } catch (e, stack) {
      debugPrint('❌ Cloud grammar insert error: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  Future<void> updateGrammar(String id, Map<String, dynamic> grammarData) async {
    final original = allGrammar.where((g) => g.id == id).firstOrNull;
    final List<dynamic> originalWidgets = List<dynamic>.from(original?.content ?? []);

    // ── APPEND-ONLY MERGE ──
    final List<dynamic> newWidgets;
    if (grammarData.containsKey('new_widgets')) {
      final raw = grammarData['new_widgets'];
      newWidgets = raw is List ? List<dynamic>.from(raw) : [];
    } else {
      final raw = grammarData['widgets'] ?? grammarData['content'] ?? grammarData['sections'] ?? [];
      final List<dynamic> returned = raw is List ? List<dynamic>.from(raw) : [];
      if (returned.length < originalWidgets.length) {
        debugPrint('⚠️ SAFETY: AI returned ${returned.length} widgets but original has ${originalWidgets.length}. Treating as NEW widgets only.');
        newWidgets = returned;
      } else {
        newWidgets = returned.sublist(originalWidgets.length);
        debugPrint('📊 Extracted ${newWidgets.length} new widgets from ${returned.length} total');
      }
    }

    final List<dynamic> mergedContent = [...originalWidgets, ...newWidgets];
    debugPrint('✅ MERGE RESULT: ${originalWidgets.length} original + ${newWidgets.length} new = ${mergedContent.length} total widgets');

    final updated = GrammarTopic(
      id: id,
      title: grammarData['title'] ?? original?.title ?? 'Untitled',
      subtitle: grammarData['subtitle'] ?? original?.subtitle ?? '',
      icon: grammarData['icon'] ?? original?.icon ?? '📖',
      description: grammarData['description'] ?? grammarData['subtitle'] ?? original?.description ?? '',
      content: mergedContent,
    );

    final index = _customGrammar.indexWhere((g) => g.id == id);
    if (index != -1) {
      _customGrammar[index] = updated;
    } else {
      debugPrint('📥 Adding hardcoded grammar "$id" to custom list for update');
      _customGrammar.add(updated);
    }
    notifyListeners();
    await _saveLocalData();

    // Update Cloud
    try {
      await _cloudUpsert('grammar', [{
        'id': id,
        'title': updated.title,
        'subtitle': updated.subtitle,
        'icon': updated.icon,
        'description': updated.description,
        'content': updated.content,
      }]);
      debugPrint('☁️ Grammar "$id" updated in cloud (${mergedContent.length} widgets)');
    } catch (e) {
      debugPrint('Cloud grammar update error: $e');
      // Surface the failure: the change is only saved on this device.
      rethrow;
    }
  }

  /// Replaces a grammar topic's whole content (used by "Rebuild"), keeping its id.
  Future<void> replaceGrammar(String id, Map<String, dynamic> grammarData) async {
    final original = allGrammar.where((g) => g.id == id).firstOrNull;
    final rawContent = grammarData['widgets'] ?? grammarData['content'] ?? [];
    final updated = GrammarTopic(
      id: id,
      title: grammarData['title'] ?? original?.title ?? 'Untitled',
      subtitle: grammarData['subtitle'] ?? original?.subtitle ?? '',
      icon: grammarData['icon'] ?? original?.icon ?? '📘',
      description: grammarData['description'] ?? grammarData['subtitle'] ?? original?.description ?? '',
      content: rawContent is List ? rawContent : [],
    );

    final index = _customGrammar.indexWhere((g) => g.id == id);
    if (index != -1) {
      _customGrammar[index] = updated;
    } else {
      _customGrammar.add(updated);
    }
    notifyListeners();
    await _saveLocalData();
    await _cloudUpsert('grammar', [updated.toJson()]);
  }

  /// Delete a custom lesson by ID (local + cloud)
  Future<void> removeLesson(String id) async {
    _customLessons.removeWhere((l) => l.id == id);
    notifyListeners();
    await _saveLocalData();
    try {
      await _cloudDelete('lessons', id);
      debugPrint('🗑️ Lesson deleted from cloud: $id');
    } catch (e) {
      debugPrint('Cloud delete lesson error: $e');
    }
  }

  /// Delete a custom grammar topic by ID (local + cloud)
  Future<void> removeGrammar(String id) async {
    _customGrammar.removeWhere((g) => g.id == id);
    notifyListeners();
    await _saveLocalData();
    try {
      await _cloudDelete('grammar', id);
      debugPrint('🗑️ Grammar deleted from cloud: $id');
    } catch (e) {
      debugPrint('Cloud delete grammar error: $e');
    }
  }

  /// Reset a core lesson to its default hardcoded state by removing database overrides
  Future<void> resetLessonToDefault(String id) async {
    _customLessons.removeWhere((l) => l.id == id);
    notifyListeners();
    await _saveLocalData();
    try {
      await _cloudDelete('lessons', id);
      debugPrint('🗑️ Custom lesson override deleted from cloud: $id');
    } catch (e) {
      debugPrint('Cloud reset lesson error: $e');
    }
  }

  /// Hide a lesson from the main list
  Future<void> hideLesson(String id) async {
    if (!_hiddenLessons.contains(id)) {
      _hiddenLessons.add(id);
      notifyListeners();
      await _saveLocalData();
    }
  }

  /// Reset a core grammar topic to its default hardcoded state by removing database overrides
  Future<void> resetGrammarToDefault(String id) async {
    _customGrammar.removeWhere((g) => g.id == id);
    notifyListeners();
    await _saveLocalData();
    try {
      await _cloudDelete('grammar', id);
      debugPrint('🗑️ Custom grammar override deleted from cloud: $id');
    } catch (e) {
      debugPrint('Cloud reset grammar error: $e');
    }
  }

  /// Hide a grammar topic from the main list
  Future<void> hideGrammar(String id) async {
    if (!_hiddenGrammar.contains(id)) {
      _hiddenGrammar.add(id);
      notifyListeners();
      await _saveLocalData();
    }
  }

  /// Uploads any built-in lesson/grammar topic missing from the cloud.
  /// Needs an admin session, so it only runs for a logged-in admin.
  Future<void> seedData() async {
    final client = _supabase;
    if (client == null || !AdminAuth.isLoggedIn) return;

    try {
      final lessonIds = (await client.from('lessons').select('id') as List)
          .map((r) => r['id'] as String)
          .toSet();
      final missingLessons = lessonTopics.where((l) => !lessonIds.contains(l.id)).toList();
      if (missingLessons.isNotEmpty) {
        debugPrint('📤 Seeding ${missingLessons.length} original lesson(s)');
        await _cloudUpsert('lessons', missingLessons.map((l) => l.toJson()).toList());
      }

      final grammarIds = (await client.from('grammar').select('id') as List)
          .map((r) => r['id'] as String)
          .toSet();
      final missingGrammar = grammarTopics.where((g) => !grammarIds.contains(g.id)).toList();
      if (missingGrammar.isNotEmpty) {
        debugPrint('📤 Seeding ${missingGrammar.length} original grammar topic(s)');
        await _cloudUpsert('grammar', missingGrammar.map((g) => g.toJson()).toList());
      }
      debugPrint('✅ Seeding check complete');
    } catch (e) {
      debugPrint('⚠️ Seeding error: $e');
    }
  }

  /// Cloud writes go through /api/content, which requires an admin session.
  /// Visitors can only read the tables directly.
  Future<void> _cloudUpsert(String table, List<Map<String, dynamic>> rows) async {
    final token = AdminAuth.token;
    if (token == null) throw Exception('Admin session expired. Please enter the admin password again.');
    final response = await ApiClient.post(
      '/api/content',
      {'action': 'upsert', 'table': table, 'rows': rows},
      bearerToken: token,
    );
    if (response.statusCode != 200) {
      throw Exception('Cloud save failed: ${ApiClient.errorMessage(response)}');
    }
  }

  Future<void> _cloudDelete(String table, String id) async {
    final token = AdminAuth.token;
    if (token == null) throw Exception('Admin session expired. Please enter the admin password again.');
    final response = await ApiClient.post(
      '/api/content',
      {'action': 'delete', 'table': table, 'id': id},
      bearerToken: token,
    );
    if (response.statusCode != 200) {
      throw Exception('Cloud delete failed: ${ApiClient.errorMessage(response)}');
    }
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedLessons = jsonEncode(_customLessons.map((l) => l.toJson()).toList());
    await prefs.setString(_prefKeyLessons, encodedLessons);
    final String encodedGrammar = jsonEncode(_customGrammar.map((g) => g.toJson()).toList());
    await prefs.setString(_prefKeyGrammar, encodedGrammar);
    await prefs.setStringList(_prefKeyHiddenLessons, _hiddenLessons);
    await prefs.setStringList(_prefKeyHiddenGrammar, _hiddenGrammar);
  }
}
