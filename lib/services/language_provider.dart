import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  french('Français', 'fr', 'fr_FR', false),
  arabic('العربية', 'ar', 'ar_SA', true),
  english('English', 'en', 'en_US', false),
  ukrainian('Українська', 'uk', 'uk_UA', false),
  italian('Italiano', 'it', 'it_IT', false),
  eritrean('ትግርኛ', 'ti', 'ti_ER', false),
  turkish('Türkçe', 'tr', 'tr_TR', false);

  final String name;
  final String code;
  final String ttsCode;
  final bool isRTL;

  const AppLanguage(this.name, this.code, this.ttsCode, this.isRTL);
}

class LanguageProvider extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.english;
  static const String _prefKey = 'selected_language';

  LanguageProvider() {
    _loadLanguage();
  }

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isRTL => _currentLanguage.isRTL;

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefKey);
    if (savedCode != null) {
      _currentLanguage = AppLanguage.values.firstWhere(
        (l) => l.code == savedCode,
        orElse: () => AppLanguage.english,
      );
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, language.code);
  }

  // Helper for basic UI strings
  String translate(String key) {
    // This is a simple mapper for core UI strings that don't need AI
    final translations = {
      'en': {
        'greeting': 'Bonjour!',
        'subtitle': 'What would you like to master today?',
        'grammar': 'Grammar',
        'exercises': 'Exercises',
        'flashcards': 'Flashcards',
        'verbs': 'Verbs',
        'examen': 'Examen',
        'essays': 'Essays',
        'dialogues': 'Dialogues',
        'daily_phrases': 'Daily Phrases',
        'listening': 'Listening',
        'select_language': 'Select Language',
      },
      'fr': {
        'greeting': 'Bonjour!',
        'subtitle': 'Que voulez-vous apprendre aujourd\'hui ?',
        'grammar': 'Grammaire',
        'exercises': 'Exercices',
        'flashcards': 'Cartes mémoire',
        'verbs': 'Verbes',
        'examen': 'Examen',
        'essays': 'Rédactions',
        'dialogues': 'Dialogues',
        'daily_phrases': 'Phrases quotidiennes',
        'listening': 'Écoute',
        'select_language': 'Choisir la langue',
      },
      'ar': {
        'greeting': 'مرحباً!',
        'subtitle': 'ماذا تود أن تتعلم اليوم؟',
        'grammar': 'القواعد',
        'exercises': 'تمارين',
        'flashcards': 'بطاقات تعليمية',
        'verbs': 'الأفعال',
        'examen': 'امتحان',
        'essays': 'مقالات',
        'dialogues': 'حوارات',
        'daily_phrases': 'جمل يومية',
        'listening': 'استماع',
        'select_language': 'اختر اللغة',
      },
      'uk': {
        'greeting': 'Привіт!',
        'subtitle': 'Що б ви хотіли вивчити сьогодні?',
        'grammar': 'Граматика',
        'exercises': 'Вправи',
        'flashcards': 'Картки',
        'verbs': 'Дієслова',
        'examen': 'Іспит',
        'essays': 'Твори',
        'dialogues': 'Діалоги',
        'daily_phrases': 'Щоденні фрази',
        'listening': 'Слухання',
        'select_language': 'Оберіть мову',
      },
      'it': {
        'greeting': 'Buongiorno!',
        'subtitle': 'Cosa ti piacerebbe imparare oggi?',
        'grammar': 'Grammatica',
        'exercises': 'Esercizi',
        'flashcards': 'Flashcard',
        'verbs': 'Verbi',
        'examen': 'Esame',
        'essays': 'Saggi',
        'dialogues': 'Dialoghi',
        'daily_phrases': 'Frasi quotidiane',
        'listening': 'Ascolto',
        'select_language': 'Seleziona lingua',
      },
      'ti': {
        'greeting': 'ሰላም!',
        'subtitle': 'ሎሚ እንታይ ክትመሃር ትደሊ?',
        'grammar': 'ሰዋስው',
        'exercises': 'ልምምድ',
        'flashcards': 'ፍላሽካርድ',
        'verbs': 'ግስታት',
        'examen': 'ፈተና',
        'essays': 'ጽሑፋት',
        'dialogues': 'ምልልስ',
        'daily_phrases': 'መዓልታዊ ሓረጋት',
        'listening': 'ምስማዕ',
        'select_language': 'ቋንቋ ምረጽ',
      },
      'tr': {
        'greeting': 'Merhaba!',
        'subtitle': 'Bugün ne öğrenmek istersin?',
        'grammar': 'Dilbilgisi',
        'exercises': 'Alıştırmalar',
        'flashcards': 'Bilgi Kartları',
        'verbs': 'Fiiller',
        'examen': 'Sınav',
        'essays': 'Kompozisyonlar',
        'dialogues': 'Diyaloglar',
        'daily_phrases': 'Günlük Kalıplar',
        'listening': 'Dinleme',
        'select_language': 'Dil Seçin',
      },
    };

    return translations[_currentLanguage.code]?[key] ?? key;
  }
}
