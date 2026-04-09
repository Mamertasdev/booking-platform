import 'dart:convert';

import 'api_client.dart';

class BusinessesApi {
  BusinessesApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getBusinesses({
    bool includeInactive = false,
  }) async {
    final query = includeInactive ? '?include_inactive=true' : '';

    final response = await _apiClient.get(
      '/api/businesses$query',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load businesses: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> createBusiness({required String name}) async {
    final response = await _apiClient.post(
      '/api/businesses',
      authenticated: true,
      body: {'name': name},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create business: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBusiness({
    required int businessId,
    required String name,
    required bool isActive,
  }) async {
    final response = await _apiClient.put(
      '/api/businesses/$businessId',
      authenticated: true,
      body: {'name': name, 'is_active': isActive},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update business: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> disableBusiness({
    required int businessId,
  }) async {
    final response = await _apiClient.put(
      '/api/businesses/$businessId/disable',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to disable business: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
