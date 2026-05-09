import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_topic.dart';

class LessonsProvider extends ChangeNotifier {
  List<LessonTopic> _customLessons = [];
  static const String _prefKey = 'custom_lessons';

  LessonsProvider() {
    _loadLessons();
  }

  List<LessonTopic> get allLessons => [...lessonTopics, ..._customLessons];

  Future<void> _loadLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lessonsJson = prefs.getString(_prefKey);
    if (lessonsJson != null) {
      final List<dynamic> decoded = jsonDecode(lessonsJson);
      _customLessons = decoded.map((item) => LessonTopic.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> addLesson(Map<String, dynamic> lessonData) async {
    final newLesson = LessonTopic(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: lessonData['title'],
      subtitle: lessonData['subtitle'],
      icon: lessonData['icon'],
      description: lessonData['sections'].map((s) => s['title']).join(', '),
      content: lessonData['sections'], // We need to add this field to LessonTopic
    );

    _customLessons.add(newLesson);
    notifyListeners();
    await _saveLessons();
  }

  Future<void> _saveLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_customLessons.map((l) => l.toJson()).toList());
    await prefs.setString(_prefKey, encoded);
  }

  Future<void> removeLesson(String id) async {
    _customLessons.removeWhere((l) => l.id == id);
    notifyListeners();
    await _saveLessons();
  }
}
