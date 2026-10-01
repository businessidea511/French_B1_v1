import 'dart:convert';
import 'package:http/http.dart' as http;

/// Calls the app's own serverless API (the functions in /api on Vercel).
/// All third-party keys live there; the app never holds them.
class ApiClient {
  // Empty on the deployed site, where /api is same-origin. For local
  // `flutter run -d chrome`, pass --dart-define=API_BASE=https://<your-app>.vercel.app
  static const String _base = String.fromEnvironment('API_BASE');

  static Uri uri(String path) {
    if (_base.isNotEmpty) {
      return Uri.parse('${_base.replaceAll(RegExp(r'/+$'), '')}$path');
    }
    return Uri.base.resolve(path);
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    String? bearerToken,
    Duration timeout = const Duration(seconds: 130),
  }) {
    return http
        .post(
          uri(path),
          headers: {
            'Content-Type': 'application/json',
            if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
  }

  /// Extracts the "error" field from an API error response, if any.
  static String errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] != null) {
        final error = decoded['error'];
        return error is Map ? (error['message'] ?? '$error').toString() : error.toString();
      }
    } catch (_) {}
    return 'HTTP ${response.statusCode}';
  }
}
