import 'dart:convert';

import 'api_client.dart';

class AvailabilityApi {
  AvailabilityApi(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getAvailability({
    required int businessId,
    required int specialistId,
    required int serviceId,
    required String targetDate,
  }) async {
    final queryString =
        '?business_id=$businessId'
        '&specialist_id=$specialistId'
        '&service_id=$serviceId'
        '&target_date=$targetDate';

    final response = await _apiClient.get(
      '/api/availability$queryString',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load availability: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
