import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

/// Admin session. The password is checked by the server (/api/admin), which
/// returns a signed token that admin-only API calls must carry.
class AdminAuth {
  static const String _prefToken = 'admin_token';
  static const String _prefExpiry = 'admin_token_expiry';

  static String? _token;
  static DateTime? _expiresAt;

  static bool get isLoggedIn =>
      _token != null && _expiresAt != null && _expiresAt!.isAfter(DateTime.now());

  static String? get token => isLoggedIn ? _token : null;

  /// Reloads a still-valid token saved by a previous login.
  static Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_prefToken);
      final expiry = prefs.getInt(_prefExpiry);
      if (token != null && expiry != null) {
        _token = token;
        _expiresAt = DateTime.fromMillisecondsSinceEpoch(expiry);
      }
    } catch (e) {
      debugPrint('AdminAuth.restore error: $e');
    }
  }

  /// Returns true when the server accepts [password].
  static Future<bool> login(String password) async {
    try {
      final response = await ApiClient.post('/api/admin', {'password': password},
          timeout: const Duration(seconds: 20));
      if (response.statusCode != 200) {
        debugPrint('Admin login rejected: ${ApiClient.errorMessage(response)}');
        return false;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _token = data['token'] as String;
      _expiresAt = DateTime.fromMillisecondsSinceEpoch((data['expiresAt'] as num).toInt());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefToken, _token!);
      await prefs.setInt(_prefExpiry, _expiresAt!.millisecondsSinceEpoch);
      return true;
    } catch (e) {
      debugPrint('Admin login error: $e');
      return false;
    }
  }
}
