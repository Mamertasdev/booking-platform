import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_client.dart';

class AuthApi {
  AuthApi(this._apiClient);

  final ApiClient _apiClient;

  Future<String> login({
    required String username,
    required String password,
  }) async {
    debugPrint('AUTH LOGIN START');
    debugPrint('AUTH LOGIN USERNAME: "${username.trim()}"');
    debugPrint('AUTH LOGIN PATH: /api/auth/login');

    final response = await _apiClient.post(
      '/api/auth/login',
      body: {'username': username, 'password': password},
    );

    debugPrint('AUTH LOGIN STATUS: ${response.statusCode}');
    debugPrint('AUTH LOGIN BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;

    if (token == null || token.isEmpty) {
      throw Exception('Token not found');
    }

    debugPrint('AUTH LOGIN SUCCESS, TOKEN RECEIVED');

    return token;
  }

  Future<Map<String, dynamic>> getMe() async {
    debugPrint('AUTH ME START');

    final response = await _apiClient.get('/api/auth/me', authenticated: true);

    debugPrint('AUTH ME STATUS: ${response.statusCode}');
    debugPrint('AUTH ME BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to load current user: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
