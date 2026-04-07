import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';

class ApiClient {
  ApiClient({required this.baseUrl, required this.tokenStorage});

  final String baseUrl;
  final TokenStorage tokenStorage;

  Future<Map<String, String>> _buildHeaders({
    bool authenticated = false,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authenticated) {
      final token = await tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<http.Response> get(String path, {bool authenticated = false}) async {
    final headers = await _buildHeaders(authenticated: authenticated);

    return http.get(Uri.parse('$baseUrl$path'), headers: headers);
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    bool authenticated = false,
  }) async {
    final headers = await _buildHeaders(authenticated: authenticated);

    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    bool authenticated = false,
  }) async {
    final headers = await _buildHeaders(authenticated: authenticated);

    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
  }
}
