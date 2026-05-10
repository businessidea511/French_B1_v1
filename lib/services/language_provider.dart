import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  french('Français', 'French', 'fr', 'fr_FR', false),
  arabic('العربية', 'Arabic', 'ar', 'ar_SA', true),
  english('English', 'English', 'en', 'en_US', false),
  ukrainian('Українська', 'Ukrainian', 'uk', 'uk_UA', false),
  italian('Italiano', 'Italian', 'it', 'it_IT', false),
  eritrean('ትግርኛ', 'Tigrinya', 'ti', 'ti_ER', false),
  turkish('Türkçe', 'Turkish', 'tr', 'tr_TR', false),
  indonesian('Bahasa Indonesia', 'Indonesian', 'id', 'id_ID', false);

  final String name;
  final String englishName;
  final String code;
  final String ttsCode;
  final bool isRTL;

  const AppLanguage(this.name, this.englishName, this.code, this.ttsCode, this.isRTL);
}

class LanguageProvider extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.english;
  static const String _prefKey = 'selected_language';

  LanguageProvider() {
    debugPrint("🌐 LanguageProvider initialized");
    _loadLanguage();
  }

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isRTL => _currentLanguage.isRTL;

  Future<void> _loadLanguage() async {
    try {
      debugPrint("🌐 Loading language from prefs...");
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null) {
        _currentLanguage = AppLanguage.values.firstWhere(
          (l) => l.code == savedCode,
          orElse: () => AppLanguage.english,
        );
        notifyListeners();
      }
      debugPrint("🌐 Language loaded: ${_currentLanguage.code}");
    } catch (e) {
      debugPrint("🌐 Language load error: $e");
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
        'lessons': 'Lessons',
        'verbs': 'Verbs',
        'examen': 'Examen',
        'essays': 'Essays',
        'dialogues': 'Dialogues',
        'daily_phrases': 'Daily Phrases',
        'listening': 'Listening',
        'select_language': 'Select Language',
        'ai_book': 'AI Story Book',
        'ai_book_desc': 'Interactive tales',
        'culture_vocab': 'Culture & Vocab',
        'daily_practice': 'Daily practice',
        'master_rules': 'Master the rules',
        'memorize_smart': 'Memorize smart',
        'conjugations': 'Conjugations',
        'common_talk': 'Common talk',
        'audio_skills': 'Audio skills',
        'ai_novelist': 'AI Novelist',
        'writing_novel': 'Professeur AI is writing your novel...',
        'building_story': 'Building an immersive story...',
        'create_magic_story': 'Create Your Magic Story ✨',
        'pick_topics': 'Pick your favorite grammar and vocabulary topics.',
        'grammar_to_use': 'Grammar to Use',
        'vocab_focus': 'Vocabulary Focus',
        'create_my_novel': 'Create My Novel',
        'learning_points': 'Learning Points',
        'new_story': 'New Story',
        'page': 'Page',
        'of': 'of',
        'select_topic_error': 'Please select at least one topic!',
      },
      'fr': {
        'greeting': 'Bonjour!',
        'subtitle': 'Que voulez-vous apprendre aujourd\'hui ?',
        'grammar': 'Grammaire',
        'exercises': 'Exercices',
        'flashcards': 'Cartes mémoire',
        'lessons': 'Leçons',
        'verbs': 'Verbes',
        'examen': 'Examen',
        'essays': 'Rédactions',
        'dialogues': 'Dialogues',
        'daily_phrases': 'Phrases quotidiennes',
        'listening': 'Écoute',
        'select_language': 'Choisir la langue',
        'ai_book': 'Livre de contes IA',
        'ai_book_desc': 'Contes interactifs',
        'culture_vocab': 'Culture & Vocab',
        'daily_practice': 'Pratique quotidienne',
        'master_rules': 'Maîtriser les règles',
        'memorize_smart': 'Mémoriser intelligemment',
        'conjugations': 'Conjugaisons',
        'common_talk': 'Conversations courantes',
        'audio_skills': 'Compétences audio',
        'ai_novelist': 'Romancier IA',
        'writing_novel': 'Professeur IA écrit votre roman...',
        'building_story': 'Création d\'une histoire immersive...',
        'create_magic_story': 'Créez votre histoire magique ✨',
        'pick_topics': 'Choisissez vos thèmes préférés.',
        'grammar_to_use': 'Grammaire à utiliser',
        'vocab_focus': 'Focus vocabulaire',
        'create_my_novel': 'Créer mon roman',
        'learning_points': 'Points d\'apprentissage',
        'new_story': 'Nouvelle histoire',
        'page': 'Page',
        'of': 'sur',
        'select_topic_error': 'Veuillez sélectionner au moins un sujet !',
      },
      'ar': {
        'greeting': 'مرحباً!',
        'subtitle': 'ماذا تود أن تتعلم اليوم؟',
        'grammar': 'القواعد',
        'exercises': 'تمارين',
        'flashcards': 'بطاقات تعليمية',
        'lessons': 'دروس',
        'verbs': 'الأفعال',
        'examen': 'امتحان',
        'essays': 'مقالات',
        'dialogues': 'حوارات',
        'daily_phrases': 'جمل يومية',
        'listening': 'استماع',
        'select_language': 'اختر اللغة',
        'ai_book': 'كتاب القصص الذكي',
        'ai_book_desc': 'قصص تفاعلية',
        'culture_vocab': 'الثقافة والمفردات',
        'daily_practice': 'ممارسة يومية',
        'master_rules': 'إتقان القواعد',
        'memorize_smart': 'حفظ بذكاء',
        'conjugations': 'تصريف الأفعال',
        'common_talk': 'محادثات شائعة',
        'audio_skills': 'مهارات الاستماع',
        'ai_novelist': 'روائي الذكاء الاصطناعي',
        'writing_novel': 'البروفيسور الذكي يكتب روايتك...',
        'building_story': 'بناء قصة غامرة بمواضيعك...',
        'create_magic_story': 'أنشئ قصتك السحرية ✨',
        'pick_topics': 'اختر مواضيع القواعد والمفردات المفضلة لديك.',
        'grammar_to_use': 'القواعد المستخدمة',
        'vocab_focus': 'تركيز المفردات',
        'create_my_novel': 'أنشئ روايتي',
        'learning_points': 'نقاط التعلم',
        'new_story': 'قصة جديدة',
        'page': 'صفحة',
        'of': 'من',
        'select_topic_error': 'يرجى اختيار موضوع واحد على الأقل!',
      },
      'uk': {
        'greeting': 'Привіт!',
        'subtitle': 'Що б ви хотіли вивчити сьогодні?',
        'grammar': 'Граматика',
        'exercises': 'Вправи',
        'flashcards': 'Картки',
        'lessons': 'Уроки',
        'verbs': 'Дієслова',
        'examen': 'Іспит',
        'essays': 'Твори',
        'dialogues': 'Діалоги',
        'daily_phrases': 'Щоденні фрази',
        'listening': 'Слухання',
        'select_language': 'Оберіть мову',
        'ai_book': 'AI Story Book',
        'ai_book_desc': 'Interactive tales',
        'culture_vocab': 'Culture & Vocab',
        'daily_practice': 'Daily practice',
        'master_rules': 'Master the rules',
        'memorize_smart': 'Memorize smart',
        'conjugations': 'Conjugations',
        'common_talk': 'Common talk',
        'audio_skills': 'Audio skills',
        'ai_novelist': 'AI Novelist',
        'writing_novel': 'Professeur AI is writing your novel...',
        'building_story': 'Building an immersive story...',
        'create_magic_story': 'Create Your Magic Story ✨',
        'pick_topics': 'Pick your favorite grammar and vocabulary topics.',
        'grammar_to_use': 'Grammar to Use',
        'vocab_focus': 'Vocabulary Focus',
        'create_my_novel': 'Create My Novel',
        'learning_points': 'Learning Points',
        'new_story': 'New Story',
        'page': 'Page',
        'of': 'of',
        'select_topic_error': 'Please select at least one topic!',
      },
      'it': {
        'greeting': 'Buongiorno!',
        'subtitle': 'Cosa ti piacerebbe imparare oggi?',
        'grammar': 'Grammatica',
        'exercises': 'Esercizi',
        'flashcards': 'Flashcard',
        'lessons': 'Lezioni',
        'verbs': 'Verbi',
        'examen': 'Esame',
        'essays': 'Saggi',
        'dialogues': 'Dialoghi',
        'daily_phrases': 'Frasi quotidiane',
        'listening': 'Ascolto',
        'select_language': 'Seleziona lingua',
        'ai_book': 'AI Story Book',
        'ai_book_desc': 'Interactive tales',
        'culture_vocab': 'Culture & Vocab',
        'daily_practice': 'Daily practice',
        'master_rules': 'Master the rules',
        'memorize_smart': 'Memorize smart',
        'conjugations': 'Conjugations',
        'common_talk': 'Common talk',
        'audio_skills': 'Audio skills',
        'ai_novelist': 'AI Novelist',
        'writing_novel': 'Professeur AI is writing your novel...',
        'building_story': 'Building an immersive story...',
        'create_magic_story': 'Create Your Magic Story ✨',
        'pick_topics': 'Pick your favorite grammar and vocabulary topics.',
        'grammar_to_use': 'Grammar to Use',
        'vocab_focus': 'Vocabulary Focus',
        'create_my_novel': 'Create My Novel',
        'learning_points': 'Learning Points',
        'new_story': 'New Story',
        'page': 'Page',
        'of': 'of',
        'select_topic_error': 'Please select at least one topic!',
      },
      'ti': {
        'greeting': 'ሰላም!',
        'subtitle': 'ሎሚ እንታይ ክትመሃር ትደሊ?',
        'grammar': 'ሰዋስው',
        'exercises': 'ልምምድ',
        'flashcards': 'ፍላሽካርድ',
        'lessons': 'ትምህርቲ',
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
        'lessons': 'Dersler',
        'verbs': 'Fiiller',
        'examen': 'Sınav',
        'essays': 'Kompozisyonlar',
        'dialogues': 'Diyaloglar',
        'daily_phrases': 'Günlük Kalıplar',
        'listening': 'Dinleme',
        'select_language': 'Dil Seçin',
      },
      'id': {
        'greeting': 'Halo!',
        'subtitle': 'Apa yang ingin kamu pelajari hari ini?',
        'grammar': 'Tata Bahasa',
        'exercises': 'Latihan',
        'flashcards': 'Kartu Belajar',
        'lessons': 'Pelajaran',
        'verbs': 'Kata Kerja',
        'examen': 'Ujian',
        'essays': 'Esai',
        'dialogues': 'Dialog',
        'daily_phrases': 'Frasa Harian',
        'listening': 'Mendengarkan',
        'select_language': 'Pilih Bahasa',
      },
    };

    return translations[_currentLanguage.code]?[key] ?? key;
  }
}
