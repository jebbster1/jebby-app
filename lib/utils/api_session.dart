import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jebby/views/screens/auth/login.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/view_models/user_view_model.dart';

class ApiSession {
  static bool _redirecting = false;

  /// Returns true when [response] was a handled 401 (session cleared + login shown).
  static Future<bool> handleUnauthorized(http.Response response) async {
    if (response.statusCode != 401) return false;
    if (_redirecting) return true;

    _redirecting = true;
    try {
      var message = 'Your session expired. Please sign in again.';
      try {
        final body = json.decode(response.body);
        if (body is Map && body['message'] != null) {
          final parsed = body['message'].toString().trim();
          if (parsed.isNotEmpty) {
            message = parsed;
          }
        }
      } catch (_) {}

      await UserViewModel().remove();
      showAppErrorSnackbar(message, title: 'Session expired');
      Get.offAll(() => const LoginScreen());
      return true;
    } finally {
      _redirecting = false;
    }
  }
}
