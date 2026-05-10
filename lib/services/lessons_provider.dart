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

  final _supabase = Supabase.instance.client;

  LessonsProvider() {
    _loadData();
  }

  List<LessonTopic> get allLessons => [...lessonTopics, ..._customLessons];
  List<GrammarTopic> get allGrammar => [...grammarTopics, ..._customGrammar];

  Future<void> _loadData() async {
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
    
    // 2. Sync from Supabase Cloud (Background)
    await syncFromCloud();
  }

  Future<void> syncFromCloud() async {
    try {
      debugPrint('☁️ Syncing from Supabase Cloud...');
      // Sync Lessons
      final List<dynamic> cloudLessons = await _supabase.from('lessons').select();
      _customLessons = cloudLessons.map((item) => LessonTopic.fromJson(item)).toList();
      
      // Sync Grammar
      final List<dynamic> cloudGrammar = await _supabase.from('grammar').select();
      _customGrammar = cloudGrammar.map((item) => GrammarTopic.fromJson(item)).toList();

      notifyListeners();
      await _saveLocalData();
      debugPrint('✅ Cloud Sync Complete');
    } catch (e) {
      debugPrint('⚠️ Cloud sync failed: $e');
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
    try {
      await _supabase.from('lessons').upsert({
        'id': id,
        'title': newLesson.title,
        'subtitle': newLesson.subtitle,
        'icon': newLesson.icon,
        'description': newLesson.description,
        'content': newLesson.content,
      });
    } catch (e) {
      debugPrint('Cloud insert error: $e');
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
      try {
        await _supabase.from('lessons').upsert({
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
    try {
      await _supabase.from('grammar').upsert({
        'id': id,
        'title': newGrammar.title,
        'subtitle': newGrammar.subtitle,
        'icon': newGrammar.icon,
        'description': newGrammar.description,
        'content': newGrammar.content,
      });
    } catch (e) {
      debugPrint('Cloud grammar insert error: $e');
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
      try {
        await _supabase.from('grammar').upsert({
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

  Future<void> removeLesson(String id) async {
    _customLessons.removeWhere((l) => l.id == id);
    notifyListeners();
    await _saveLocalData();
    try {
      await _supabase.from('lessons').delete().eq('id', id);
    } catch (_) {}
  }

  Future<void> removeGrammar(String id) async {
    _customGrammar.removeWhere((g) => g.id == id);
    notifyListeners();
    await _saveLocalData();
    try {
      await _supabase.from('grammar').delete().eq('id', id);
    } catch (_) {}
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedLessons = jsonEncode(_customLessons.map((l) => l.toJson()).toList());
    await prefs.setString(_prefKeyLessons, encodedLessons);
    final String encodedGrammar = jsonEncode(_customGrammar.map((g) => g.toJson()).toList());
    await prefs.setString(_prefKeyGrammar, encodedGrammar);
  }
}
