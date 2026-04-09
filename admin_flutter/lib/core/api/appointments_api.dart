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
      throw Exception('Failed to load appointments: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;

    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> createAppointment({
    required int businessId,
    required int specialistId,
    required int serviceId,
    required String clientFullName,
    required String clientEmail,
    String? clientPhone,
    String? notes,
    required String appointmentStartIso,
  }) async {
    final response = await _apiClient.post(
      '/api/appointments',
      authenticated: true,
      body: {
        'business_id': businessId,
        'specialist_id': specialistId,
        'service_id': serviceId,
        'client_full_name': clientFullName,
        'client_email': clientEmail,
        'client_phone': clientPhone,
        'notes': notes,
        'appointment_start': appointmentStartIso,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create appointment: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAppointmentStatus({
    required int appointmentId,
    required String status,
  }) async {
    final response = await _apiClient.put(
      '/api/appointments/$appointmentId/status',
      authenticated: true,
      body: {'status': status},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update appointment status: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelAppointment({
    required int appointmentId,
  }) async {
    final response = await _apiClient.put(
      '/api/appointments/$appointmentId/cancel',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel appointment: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rescheduleAppointment({
    required int appointmentId,
    required String appointmentStartIso,
  }) async {
    final response = await _apiClient.put(
      '/api/appointments/$appointmentId/reschedule',
      authenticated: true,
      body: {'appointment_start': appointmentStartIso},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reschedule appointment: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
