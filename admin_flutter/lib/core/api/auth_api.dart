import 'dart:convert';

import 'api_client.dart';

class AuthApi {
  AuthApi(this._apiClient);

  final ApiClient _apiClient;

  Future<String> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      body: {'username': username, 'password': password},
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;

    if (token == null || token.isEmpty) {
      throw Exception('Token not found');
    }

    return token;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _apiClient.get('/api/auth/me', authenticated: true);

    if (response.statusCode != 200) {
      throw Exception('Failed to load current user');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
