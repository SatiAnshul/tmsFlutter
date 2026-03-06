// lib/api/api_client.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class ApiClient {

  void _logRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    assert(() {
      debugPrint("[$method]");
      debugPrint("URL: $url");
      final requestId = DateTime.now().millisecondsSinceEpoch;
      debugPrint("REQUEST ID: $requestId");
      if (headers != null) debugPrint("HEADERS: $headers");
      if (body != null) debugPrint("BODY: $body");
      return true;
    }());
  }

  void _logResponse(http.Response response) {
    assert(() {
      debugPrint("[RESPONSE]");
      debugPrint("URL: ${response.request?.url}");
      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");
      final requestId = DateTime.now().millisecondsSinceEpoch;
      debugPrint("REQUEST ID: $requestId");
      return true;
    }());
  }

  void _logError(Object error) {
    assert(() {
      debugPrint("[API ERROR]");
      debugPrint(error.toString());
      return true;
    }());
  }



  final String baseUrl = "http://103.47.149.49:6550/api/";

  Map<String, String> get _defaultHeaders => {
    "Content-Type": "application/json",
  };

  // Future<Map<String, dynamic>> post(String endpoint,
  //     { Map<String, String>? headers, dynamic body}
  //     ) async {
  //   final url = Uri.parse(baseUrl + endpoint);
  //   final response = await http.post(
  //     url, headers: {..._defaultHeaders, ...?headers}, body: jsonEncode(body),);
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception("POST $endpoint failed: ${response.statusCode}");
  //   }
  // }
  Future<Map<String, dynamic>> post(
      String endpoint, {
        Map<String, String>? headers,
        dynamic body,
      }) async {
    final url = Uri.parse(baseUrl + endpoint);

    _logRequest(
      method: "POST",
      url: url,
      headers: {..._defaultHeaders, ...?headers},
      body: body,
    );

    try {
      final response = await http.post(
        url,
        headers: {..._defaultHeaders, ...?headers},
        body: jsonEncode(body),
      );

      _logResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("POST $endpoint failed: ${response.statusCode}");
      }
    } catch (e) {
      _logError(e);
      rethrow;
    }
  }


  // Future<Map<String, dynamic>> postWithQuery(
  //     String endpoint, {
  //       Map<String, String>? headers,
  //       dynamic body, Map<String, String>? queryParameters,
  //     }) async {
  //
  //   final url = Uri.parse(baseUrl + endpoint).replace(
  //     queryParameters: queryParameters,
  //   );
  //
  //   final response = await http.post(
  //     url,
  //     headers: {..._defaultHeaders, ...?headers},
  //     body: jsonEncode(body),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception("POST $endpoint failed: ${response.statusCode}");
  //   }
  // }
  Future<Map<String, dynamic>> postWithQuery(
      String endpoint, {
        Map<String, String>? headers,
        Map<String, String>? queryParameters,
        dynamic body,
      }) async {
    final uri = Uri.parse(baseUrl + endpoint).replace(
      queryParameters: queryParameters,
    );

    final mergedHeaders = {
      ..._defaultHeaders,
      ...?headers,
    };

    _logRequest(
      method: "POST",
      url: uri,
      headers: mergedHeaders,
      body: body,
    );

    try {
      final response = await http.post(
        uri,
        headers: mergedHeaders,
        body: jsonEncode(body),
      );

      _logResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "POST $endpoint failed: ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      _logError(e);
      rethrow;
    }
  }


  // Future<Map<String, dynamic>> get(
  //     String endpoint, {
  //       Map<String, String>? queryParameters,
  //       Map<String, String>? headers,
  //     }) async {
  //   final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParameters);
  //
  //   final response = await http.get(uri, headers: headers);
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception("GET $endpoint failed: ${response.statusCode} ${response.body}");
  //   }
  // }

  Future<Map<String, dynamic>> get(
      String endpoint, {
        Map<String, String>? queryParameters,
        Map<String, String>? headers,
      }) async {
    final uri =
    Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParameters);

    _logRequest(
      method: "GET",
      url: uri,
      headers: headers,
    );

    try {
      final response = await http.get(uri, headers: headers);

      _logResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "GET $endpoint failed: ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      _logError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWithoutToken(
      String endpoint, {
        Map<String, String>? queryParameters,
      }) async {
    final uri =
    Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParameters);

    _logRequest(
      method: "GET",
      url: uri,
    );

    try {
      final response = await http.get(uri);

      _logResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "GET $endpoint failed: ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      _logError(e);
      rethrow;
    }
  }


// Future<Map<String, dynamic>> getWithoutToken(
  //     String endpoint, {
  //       Map<String, String>? queryParameters
  //     }) async {
  //   final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParameters);
  //
  //   final response = await http.get(uri);
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception("GET $endpoint failed: ${response.statusCode} ${response.body}");
  //   }
  // }


}
