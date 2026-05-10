import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson_topic.dart';
import '../models/grammar_topic.dart';

class LessonsProvider extends ChangeNotifier {
  List<LessonTopic> _customLessons = [];
  List<GrammarTopic> _customGrammar = [];
  
  static const String _prefKeyLessons = 'custom_lessons';
  static const String _prefKeyGrammar = 'custom_grammar';

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
      merged[l.id] = l;
    }
    // Overwrite with cloud/custom versions if they exist
    for (var l in _customLessons) {
      merged[l.id] = l;
    }
    return merged.values.toList();
  }

  List<GrammarTopic> get allGrammar {
    final Map<String, GrammarTopic> merged = {};
    for (var g in grammarTopics) {
      merged[g.id] = g;
    }
    for (var g in _customGrammar) {
      merged[g.id] = g;
    }
    return merged.values.toList();
  }

  Future<void> _loadData() async {
    try {
      debugPrint("📚 Loading lessons from prefs...");
      final prefs = await SharedPreferences.getInstance();
      
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

      // Sync Lessons
      final List<dynamic> cloudLessons = await client.from('lessons').select();
      _customLessons = cloudLessons
          .where((item) => (item['id'] as String).startsWith('custom_'))
          .map((item) => LessonTopic.fromJson(item))
          .toList();
      
      // Sync Grammar
      final List<dynamic> cloudGrammar = await client.from('grammar').select();
      _customGrammar = cloudGrammar
          .where((item) => (item['id'] as String).startsWith('custom_'))
          .map((item) => GrammarTopic.fromJson(item))
          .toList();

      notifyListeners();
      await _saveLocalData();
      debugPrint('✅ Cloud Sync Complete: ${_customLessons.length} custom lessons found');
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
    final newLesson = LessonTopic(
      id: id,
      title: lessonData['title'],
      subtitle: lessonData['subtitle'],
      icon: lessonData['icon'],
      description: (lessonData['sections'] ?? lessonData['content'] ?? []).map((s) => s['title']).join(', '),
      content: lessonData['sections'] ?? lessonData['content'],
    );

    _customLessons.add(newLesson);
    notifyListeners();
    await _saveLocalData();

    // Push to Cloud
    final client = _supabase;
    if (client == null) {
      debugPrint('⚠️ Supabase client is NULL - skipping cloud push');
      return;
    }
    try {
      debugPrint('☁️ Pushing lesson to Supabase: $id');
      final response = await client.from('lessons').upsert({
        'id': id,
        'title': newLesson.title,
        'subtitle': newLesson.subtitle,
        'icon': newLesson.icon,
        'description': newLesson.description,
        'content': newLesson.content,
      }).select();
      debugPrint('✅ Lesson saved to cloud: ${response.length} rows affected');
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
    final index = _customLessons.indexWhere((l) => l.id == id);
    if (index != -1) {
      final updated = LessonTopic(
        id: id,
        title: lessonData['title'],
        subtitle: lessonData['subtitle'],
        icon: lessonData['icon'],
        description: (lessonData['content'] ?? lessonData['sections'] as List).map((s) => s['title']).join(', '),
        content: lessonData['content'] ?? lessonData['sections'],
      );
      _customLessons[index] = updated;
      notifyListeners();
      await _saveLocalData();

      // Update Cloud
      final client = _supabase;
      if (client != null) {
        try {
          await client.from('lessons').upsert({
            'id': id,
            'title': updated.title,
            'subtitle': updated.subtitle,
            'icon': updated.icon,
            'description': updated.description,
            'content': updated.content,
          });
        } catch (e) {
          debugPrint('Cloud update error: $e');
        }
      }
    }
  }

  Future<void> addGrammar(Map<String, dynamic> grammarData) async {
    final String id = 'custom_grammar_${DateTime.now().millisecondsSinceEpoch}';
    final newGrammar = GrammarTopic(
      id: id,
      title: grammarData['title'],
      subtitle: grammarData['subtitle'],
      icon: grammarData['icon'],
      description: (grammarData['sections'] ?? grammarData['content'] ?? []).map((s) => s['title']).join(', '),
      content: grammarData['sections'] ?? grammarData['content'],
    );

    _customGrammar.add(newGrammar);
    notifyListeners();
    await _saveLocalData();

    // Push to Cloud
    final client = _supabase;
    if (client == null) {
      debugPrint('⚠️ Supabase client is NULL - skipping cloud push');
      return;
    }
    try {
      debugPrint('☁️ Pushing grammar to Supabase: $id');
      final response = await client.from('grammar').upsert({
        'id': id,
        'title': newGrammar.title,
        'subtitle': newGrammar.subtitle,
        'icon': newGrammar.icon,
        'description': newGrammar.description,
        'content': newGrammar.content,
      }).select();
      debugPrint('✅ Grammar saved to cloud: ${response.length} rows affected');
    } catch (e, stack) {
      debugPrint('❌ Cloud grammar insert error: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  Future<void> updateGrammar(String id, Map<String, dynamic> grammarData) async {
    final index = _customGrammar.indexWhere((g) => g.id == id);
    if (index != -1) {
      final updated = GrammarTopic(
        id: id,
        title: grammarData['title'],
        subtitle: grammarData['subtitle'],
        icon: grammarData['icon'],
        description: (grammarData['content'] ?? grammarData['sections'] as List).map((s) => s['title']).join(', '),
        content: grammarData['content'] ?? grammarData['sections'],
      );
      _customGrammar[index] = updated;
      notifyListeners();
      await _saveLocalData();

      // Update Cloud
      final client = _supabase;
      if (client != null) {
        try {
          await client.from('grammar').upsert({
            'id': id,
            'title': updated.title,
            'subtitle': updated.subtitle,
            'icon': updated.icon,
            'description': updated.description,
            'content': updated.content,
          });
        } catch (e) {
          debugPrint('Cloud grammar update error: $e');
        }
      }
    }
  }

  Future<void> seedData() async {
    final client = _supabase;
    if (client == null) return;

    debugPrint('🌱 Seeding original content to cloud...');
    
    // Seed Lessons
    for (var lesson in lessonTopics) {
      try {
        await client.from('lessons').upsert({
          'id': lesson.id,
          'title': lesson.title,
          'subtitle': lesson.subtitle,
          'icon': lesson.icon,
          'description': lesson.description,
          'content': lesson.content,
        }, onConflict: 'id'); // Don't overwrite if already changed in cloud
      } catch (e) {
        debugPrint('Seed error (lesson ${lesson.id}): $e');
      }
    }

    // Seed Grammar
    for (var grammar in grammarTopics) {
      try {
        await client.from('grammar').upsert({
          'id': grammar.id,
          'title': grammar.title,
          'subtitle': grammar.subtitle,
          'icon': grammar.icon,
          'description': grammar.description,
          'content': grammar.content,
        }, onConflict: 'id');
      } catch (e) {
        debugPrint('Seed error (grammar ${grammar.id}): $e');
      }
    }
    debugPrint('✅ Seeding complete');
  }

  Future<void> removeLesson(String id) async {
    _customLessons.removeWhere((l) => l.id == id);
    notifyListeners();
    await _saveLocalData();
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('lessons').delete().eq('id', id);
      } catch (_) {}
    }
  }

  Future<void> removeGrammar(String id) async {
    _customGrammar.removeWhere((g) => g.id == id);
    notifyListeners();
    await _saveLocalData();
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('grammar').delete().eq('id', id);
      } catch (_) {}
    }
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedLessons = jsonEncode(_customLessons.map((l) => l.toJson()).toList());
    await prefs.setString(_prefKeyLessons, encodedLessons);
    final String encodedGrammar = jsonEncode(_customGrammar.map((g) => g.toJson()).toList());
    await prefs.setString(_prefKeyGrammar, encodedGrammar);
  }
}
