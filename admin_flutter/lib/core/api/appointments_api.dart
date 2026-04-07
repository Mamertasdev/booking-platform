import 'dart:convert';

import 'api_client.dart';

class AppointmentsApi {
  AppointmentsApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getAppointments({
    int? businessId,
    int? specialistId,
    String? targetDate,
  }) async {
    final queryParameters = <String, String>{};

    if (businessId != null) {
      queryParameters['business_id'] = businessId.toString();
    }

    if (specialistId != null) {
      queryParameters['specialist_id'] = specialistId.toString();
    }

    if (targetDate != null && targetDate.isNotEmpty) {
      queryParameters['target_date'] = targetDate;
    }

    final queryString = queryParameters.entries.isEmpty
        ? ''
        : '?${queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}';

    final response = await _apiClient.get(
      '/api/appointments$queryString',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load appointments');
    }

    final data = jsonDecode(response.body) as List<dynamic>;

    return data.map((item) => item as Map<String, dynamic>).toList();
  }
}
