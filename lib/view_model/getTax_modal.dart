import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:jebby/utils/api_headers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class GetreturnProduct {
  static Future<Map<String, dynamic>> fetchData() async {
    String Url = dotenv.env['baseUrlM'] ?? 'No url found';
    final SharedPreferences s = await SharedPreferences.getInstance();
    final response = await http.get(
      Uri.parse("${Url}/getAllExpiryOrdersByUserId/${s.getString('id')}"),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch data');
    }
  }
}

class GetreturnProduct2 {
  static Future<Map<String, dynamic>> fetchData() async {
    String Url = dotenv.env['baseUrlM'] ?? 'No url found';
    final SharedPreferences s = await SharedPreferences.getInstance();
    final response = await http.get(
      Uri.parse("${Url}/getAllExpiryOrdersByVendorId/${s.getString('id')}"),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch data');
    }
  }
}
