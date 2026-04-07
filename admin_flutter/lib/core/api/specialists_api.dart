import 'dart:convert';

import 'api_client.dart';

class SpecialistsApi {
  SpecialistsApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getSpecialists({
    int? businessId,
    bool includeInactive = false,
  }) async {
    final queryParameters = <String, String>{};

    if (businessId != null) {
      queryParameters['business_id'] = businessId.toString();
    }

    if (includeInactive) {
      queryParameters['include_inactive'] = 'true';
    }

    final queryString = queryParameters.entries.isEmpty
        ? ''
        : '?${queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}';

    final response = await _apiClient.get(
      '/api/specialists$queryString',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load specialists: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> createSpecialist({
    required int businessId,
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final response = await _apiClient.post(
      '/api/specialists',
      authenticated: true,
      body: {
        'business_id': businessId,
        'username': username,
        'password': password,
        'full_name': fullName,
        'role': role,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create specialist: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> disableSpecialist({
    required int specialistId,
  }) async {
    final response = await _apiClient.put(
      '/api/specialists/$specialistId/disable',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to disable specialist: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
