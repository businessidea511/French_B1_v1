import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'admin_auth.dart';
import 'api_client.dart';

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

/// Service for managing saved Admin AI Q&As in Supabase. The table is private,
/// so every call goes through /api/content with the admin session token.
class AdminQAService {
  static Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    final token = AdminAuth.token;
    if (token == null) throw Exception('Admin session expired. Please log in again.');
    final response = await ApiClient.post('/api/content', body, bearerToken: token);
    if (response.statusCode != 200) throw Exception(ApiClient.errorMessage(response));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Fetches all saved Q&As, newest first.
  static Future<List<AdminQA>> fetchAll() async {
    try {
      final data = await _call({'action': 'list_qas'});
      return (data['rows'] as List<dynamic>)
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
      final data = await _call({
        'action': 'insert_qa',
        'question': question,
        'answer': answer,
        'language': language,
      });
      return AdminQA.fromMap(Map<String, dynamic>.from(data['row']));
    } catch (e) {
      debugPrint('AdminQAService.insert error: $e');
      rethrow;
    }
  }

  /// Deletes a Q&A row by its UUID.
  static Future<void> delete(String id) async {
    try {
      await _call({'action': 'delete', 'table': 'admin_ai_saved_qas', 'id': id});
    } catch (e) {
      debugPrint('AdminQAService.delete error: $e');
      rethrow;
    }
  }
}
