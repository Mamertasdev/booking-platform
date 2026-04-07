import 'dart:convert';

import 'api_client.dart';

class WorkingHoursApi {
  WorkingHoursApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getWorkingHours({
    bool includeInactive = false,
  }) async {
    final query = includeInactive ? '?include_inactive=true' : '';

    final response = await _apiClient.get(
      '/api/working-hours$query',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load working hours: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> createWorkingHour({
    required int businessId,
    required int specialistId,
    required int weekday,
    required String startTime,
    required String endTime,
  }) async {
    final response = await _apiClient.post(
      '/api/working-hours',
      authenticated: true,
      body: {
        'business_id': businessId,
        'specialist_id': specialistId,
        'weekday': weekday,
        'start_time': startTime,
        'end_time': endTime,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create working hour: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateWorkingHour({
    required int workingHourId,
    required int weekday,
    required String startTime,
    required String endTime,
    required bool isActive,
  }) async {
    final response = await _apiClient.put(
      '/api/working-hours/$workingHourId',
      authenticated: true,
      body: {
        'weekday': weekday,
        'start_time': startTime,
        'end_time': endTime,
        'is_active': isActive,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update working hour: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> disableWorkingHour({
    required int workingHourId,
  }) async {
    final response = await _apiClient.put(
      '/api/working-hours/$workingHourId/disable',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to disable working hour: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
