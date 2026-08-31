import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GetJebbyfee {
  static Future<Map<String, dynamic>> fetchData() async {
    String Url = dotenv.env['baseUrlM'] ?? 'No url found';
    final response = await http.get(Uri.parse("${Url}/GetValues"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch data');
    }
  }
}
