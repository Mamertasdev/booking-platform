import 'dart:convert';

import 'api_client.dart';

class ServicesApi {
  ServicesApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getServices({
    bool includeInactive = false,
  }) async {
    final query = includeInactive ? '?include_inactive=true' : '';

    final response = await _apiClient.get(
      '/api/services$query',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load services: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;

    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> createService({
    required String name,
    required int durationMinutes,
    required int price,
  }) async {
    final response = await _apiClient.post(
      '/api/services',
      authenticated: true,
      body: {'name': name, 'duration_minutes': durationMinutes, 'price': price},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create service: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateService({
    required int serviceId,
    required String name,
    required int durationMinutes,
    required int price,
    required bool isActive,
  }) async {
    final response = await _apiClient.put(
      '/api/services/$serviceId',
      authenticated: true,
      body: {
        'name': name,
        'duration_minutes': durationMinutes,
        'price': price,
        'is_active': isActive,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update service: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> disableService({required int serviceId}) async {
    final response = await _apiClient.put(
      '/api/services/$serviceId/disable',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to disable service: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
