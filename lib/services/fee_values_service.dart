import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jebby/constants/app_url.dart';

class FeeValuesService {
  FeeValuesService._();

  static Future<Map<String, dynamic>> fetchValues() async {
    final response = await http.get(Uri.parse(AppUrl.getValuesUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
      return Map<String, dynamic>.from(data as Map);
    }
    throw Exception('Failed to fetch fee values');
  }
}
