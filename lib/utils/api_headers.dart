import 'package:shared_preferences/shared_preferences.dart';

class ApiHeaders {
  static Future<Map<String, String>> _authHeaders() async {
    final headers = <String, String>{};
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, String>> json() async {
    final headers = await _authHeaders();
    headers['Content-type'] = 'application/json';
    return headers;
  }

  /// Authorization only — use for Dio multipart uploads.
  static Future<Map<String, String>> authOnly() async {
    return _authHeaders();
  }
}
