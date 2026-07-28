import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:jebby/res/app_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  static const _sessionKey = 'analytics_session_id';

  Future<String> _sessionId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_sessionKey);
    if (id == null || id.isEmpty) {
      id =
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
      await prefs.setString(_sessionKey, id);
    }
    return id;
  }

  Future<void> track(
    String eventName, {
    Map<String, dynamic>? props,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id');
      final role = prefs.getString('role');
      final sessionId = await _sessionId();

      final body = <String, dynamic>{
        'event_name': eventName,
        'session_id': sessionId,
        if (userId != null && userId.isNotEmpty)
          'user_id': int.tryParse(userId) ?? userId,
        if (role != null && role.isNotEmpty)
          'role': int.tryParse(role) ?? role,
        ...?props,
      };

      await http.post(
        Uri.parse(AppUrl.eventsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (_) {
      // Fire-and-forget: analytics must never block UI.
    }
  }
}
