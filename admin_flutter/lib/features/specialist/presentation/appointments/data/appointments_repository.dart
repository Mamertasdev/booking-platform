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
    return _appointmentsApi.createAppointment(
      businessId: businessId,
      specialistId: specialistId,
      serviceId: serviceId,
      clientFullName: clientFullName,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
      notes: notes,
      appointmentStartIso: appointmentStartIso,
    );
  }
}
