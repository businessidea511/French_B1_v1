import 'dart:convert';
import 'package:http/http.dart' as http;

/// Reads the public tables (lessons, grammar) straight from Supabase's REST
/// API. Visitors only read; writes go through /api/content with an admin
/// session. A few lines instead of the whole Supabase package keep the app
/// small and quick to start.
class SupabaseRest {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get configured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Tests replace the HTTP client.
  static http.Client client = http.Client();

  /// `select columns from table` (all rows, or the first [limit]).
  static Future<List<dynamic>> select(String table, {String columns = '*', int? limit}) async {
    if (!configured) throw StateError('Supabase is not configured');
    final query = {'select': columns, if (limit != null) 'limit': '$limit'};
    final uri = Uri.parse('$url/rest/v1/$table').replace(queryParameters: query);
    final response = await client
        .get(uri, headers: {'apikey': anonKey, 'Authorization': 'Bearer $anonKey'})
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Supabase $table: HTTP ${response.statusCode} ${response.body}');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! List) throw Exception('Supabase $table: unexpected answer');
    return body;
  }
}
