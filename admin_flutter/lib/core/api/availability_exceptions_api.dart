import 'dart:convert';

import 'api_client.dart';

class AvailabilityExceptionsApi {
  AvailabilityExceptionsApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getAvailabilityExceptions({
    int? businessId,
    int? specialistId,
    String? targetDate,
    bool includeInactive = false,
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

    if (includeInactive) {
      queryParameters['include_inactive'] = 'true';
    }

    final queryString = queryParameters.entries.isEmpty
        ? ''
        : '?${queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}';

    final response = await _apiClient.get(
      '/api/availability-exceptions$queryString',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load availability exceptions: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> createAvailabilityException({
    required int businessId,
    required int specialistId,
    required String startDateTimeIso,
    required String endDateTimeIso,
    String? reason,
  }) async {
    final response = await _apiClient.post(
      '/api/availability-exceptions',
      authenticated: true,
      body: {
        'business_id': businessId,
        'specialist_id': specialistId,
        'start_datetime': startDateTimeIso,
        'end_datetime': endDateTimeIso,
        'reason': reason,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to create availability exception: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAvailabilityException({
    required int exceptionId,
    required String startDateTimeIso,
    required String endDateTimeIso,
    String? reason,
    required bool isActive,
  }) async {
    final response = await _apiClient.put(
      '/api/availability-exceptions/$exceptionId',
      authenticated: true,
      body: {
        'start_datetime': startDateTimeIso,
        'end_datetime': endDateTimeIso,
        'reason': reason,
        'is_active': isActive,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update availability exception: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> disableAvailabilityException({
    required int exceptionId,
  }) async {
    final response = await _apiClient.put(
      '/api/availability-exceptions/$exceptionId/disable',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to disable availability exception: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
