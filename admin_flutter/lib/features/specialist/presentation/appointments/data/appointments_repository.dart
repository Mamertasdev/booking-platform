import '../../../../../core/api/appointments_api.dart';

class AppointmentsRepository {
  AppointmentsRepository({required AppointmentsApi appointmentsApi})
    : _appointmentsApi = appointmentsApi;

  final AppointmentsApi _appointmentsApi;

  Future<List<Map<String, dynamic>>> getMyAppointments() async {
    return _appointmentsApi.getAppointments();
  }
}
