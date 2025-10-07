// lib/api/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl = "http://103.47.149.49:6550/api/";

  Map<String, String> get _defaultHeaders => {
    "Content-Type": "application/json",
  };

  Future<Map<String, dynamic>> post(String endpoint,
      { Map<String, String>? headers, dynamic body}
      ) async {
    final url = Uri.parse(baseUrl + endpoint);
    final response = await http.post(
      url, headers: {..._defaultHeaders, ...?headers}, body: jsonEncode(body),);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("POST $endpoint failed: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> postWithQuery(
      String endpoint, {
        Map<String, String>? headers,
        dynamic body, Map<String, String>? queryParameters,
      }) async {

    final url = Uri.parse(baseUrl + endpoint).replace(
      queryParameters: queryParameters,
    );

    final response = await http.post(
      url,
      headers: {..._defaultHeaders, ...?headers},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("POST $endpoint failed: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> get(
      String endpoint, {
        Map<String, String>? queryParameters,
        Map<String, String>? headers,
      }) async {
    final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParameters);

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("GET $endpoint failed: ${response.statusCode} ${response.body}");
    }
  }
  Future<Map<String, dynamic>> getWithoutToken(
      String endpoint, {
        Map<String, String>? queryParameters
      }) async {
    final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParameters);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("GET $endpoint failed: ${response.statusCode} ${response.body}");
    }
  }


}
