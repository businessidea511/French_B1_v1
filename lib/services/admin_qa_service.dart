import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents a single saved Q&A entry from the admin AI assistant.
class AdminQA {
  final String id;
  final String question;
  final String answer;
  final String language;
  final DateTime createdAt;

  const AdminQA({
    required this.id,
    required this.question,
    required this.answer,
    required this.language,
    required this.createdAt,
  });

  factory AdminQA.fromMap(Map<String, dynamic> map) {
    return AdminQA(
      id: map['id'] as String,
      question: map['question'] as String,
      answer: map['answer'] as String,
      language: map['language'] as String? ?? 'English',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'question': question,
        'answer': answer,
        'language': language,
      };
}

/// Service for managing saved Admin AI Q&As in Supabase.
class AdminQAService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _table = 'admin_ai_saved_qas';

  /// Fetches all saved Q&As, newest first.
  static Future<List<AdminQA>> fetchAll() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((e) => AdminQA.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('AdminQAService.fetchAll error: $e');
      rethrow;
    }
  }

  /// Inserts a new Q&A row. Returns the created [AdminQA] with its UUID.
  static Future<AdminQA> insert({
    required String question,
    required String answer,
    required String language,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .insert({
            'question': question,
            'answer': answer,
            'language': language,
          })
          .select()
          .single();

      return AdminQA.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('AdminQAService.insert error: $e');
      rethrow;
    }
  }

  /// Deletes a Q&A row by its UUID.
  static Future<void> delete(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      debugPrint('AdminQAService.delete error: $e');
      rethrow;
    }
  }
}
