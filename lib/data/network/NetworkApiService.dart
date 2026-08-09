import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:jebby/data/app_excaptions.dart';
import 'package:jebby/data/network/BaseApiServices.dart';
import 'package:jebby/utils/api_headers.dart';
import 'package:http/http.dart' as http;

class NetworkApiService extends BaseApiServices {
  @override
  Future getGetApiResponse(String url) async {
    dynamic responseJson;
    try {
      final response = await http
          .get(Uri.parse(url), headers: await ApiHeaders.json())
          .timeout(const Duration(seconds: 10));
      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }

    return responseJson;
  }

  @override
  Future getPostApiResponse(String url, dynamic data) async {
    dynamic responseJson;
    try {
      final headers = await ApiHeaders.json();
      final body = data is Map || data is List ? jsonEncode(data) : data;

      Response response = await post(
        Uri.parse(url),
        body: body,
        headers: headers,
      ).timeout(Duration(seconds: 10));

      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }

    return responseJson;
  }

  dynamic returnResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        dynamic responseJson = jsonDecode(response.body);
        return responseJson;
      case 400:
        throw BadRequestException(response.body.toString());
      case 401:
      case 403:
        throw UnauthorisedException(response.body.toString());
      case 500:
      case 404:
        throw UnauthorisedException(response.body.toString());
      default:
        throw FetchDataException(
          'Error accured while communicating with server' +
              'with status code' +
              response.statusCode.toString(),
        );
    }
  }
}
