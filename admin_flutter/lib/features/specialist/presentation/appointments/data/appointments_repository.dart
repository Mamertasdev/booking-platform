import '../../../../../core/api/appointments_api.dart';

class AppointmentsRepository {
  AppointmentsRepository({required AppointmentsApi appointmentsApi})
    : _appointmentsApi = appointmentsApi;

  final AppointmentsApi _appointmentsApi;

  Future<List<Map<String, dynamic>>> getMyAppointments() async {
    return _appointmentsApi.getAppointments();
  }

  Future<List<Map<String, dynamic>>> getMyAppointmentsForDate({
    required String targetDate,
  }) async {
    return _appointmentsApi.getAppointments(targetDate: targetDate);
  }

  Future<List<Map<String, dynamic>>> getAppointments({
    int? businessId,
    int? specialistId,
    String? targetDate,
  }) async {
    return _appointmentsApi.getAppointments(
      businessId: businessId,
      specialistId: specialistId,
      targetDate: targetDate,
    );
  }
}
