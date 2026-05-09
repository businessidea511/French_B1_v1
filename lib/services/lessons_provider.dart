import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_topic.dart';
import '../models/grammar_topic.dart';

class LessonsProvider extends ChangeNotifier {
  List<LessonTopic> _customLessons = [];
  List<GrammarTopic> _customGrammar = [];
  
  static const String _prefKeyLessons = 'custom_lessons';
  static const String _prefKeyGrammar = 'custom_grammar';

  LessonsProvider() {
    _loadData();
  }

  List<LessonTopic> get allLessons => [...lessonTopics, ..._customLessons];
  List<GrammarTopic> get allGrammar => [...grammarTopics, ..._customGrammar];

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Lessons
    final String? lessonsJson = prefs.getString(_prefKeyLessons);
    if (lessonsJson != null) {
      final List<dynamic> decoded = jsonDecode(lessonsJson);
      _customLessons = decoded.map((item) => LessonTopic.fromJson(item)).toList();
    }

    // Load Grammar
    final String? grammarJson = prefs.getString(_prefKeyGrammar);
    if (grammarJson != null) {
      final List<dynamic> decoded = jsonDecode(grammarJson);
      _customGrammar = decoded.map((item) => GrammarTopic.fromJson(item)).toList();
    }
    
    notifyListeners();
  }

  Future<void> addLesson(Map<String, dynamic> lessonData) async {
    final newLesson = LessonTopic(
      id: 'custom_lesson_${DateTime.now().millisecondsSinceEpoch}',
      title: lessonData['title'],
      subtitle: lessonData['subtitle'],
      icon: lessonData['icon'],
      description: lessonData['sections'].map((s) => s['title']).join(', '),
      content: lessonData['sections'],
    );

    _customLessons.add(newLesson);
    notifyListeners();
    await _saveData();
  }

  Future<void> addGrammar(Map<String, dynamic> grammarData) async {
    final newGrammar = GrammarTopic(
      id: 'custom_grammar_${DateTime.now().millisecondsSinceEpoch}',
      title: grammarData['title'],
      subtitle: grammarData['subtitle'],
      icon: grammarData['icon'],
      description: grammarData['sections'].map((s) => s['title']).join(', '),
      content: grammarData['sections'],
    );

    _customGrammar.add(newGrammar);
    notifyListeners();
    await _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String encodedLessons = jsonEncode(_customLessons.map((l) => l.toJson()).toList());
    await prefs.setString(_prefKeyLessons, encodedLessons);

    final String encodedGrammar = jsonEncode(_customGrammar.map((g) => g.toJson()).toList());
    await prefs.setString(_prefKeyGrammar, encodedGrammar);
  }

  Future<void> removeLesson(String id) async {
    _customLessons.removeWhere((l) => l.id == id);
    notifyListeners();
    await _saveData();
  }

  Future<void> removeGrammar(String id) async {
    _customGrammar.removeWhere((g) => g.id == id);
    notifyListeners();
    await _saveData();
  }
}
