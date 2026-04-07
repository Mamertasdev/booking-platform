import '../../../core/api/working_hours_api.dart';

class WorkingHoursRepository {
  WorkingHoursRepository({required WorkingHoursApi workingHoursApi})
    : _workingHoursApi = workingHoursApi;

  final WorkingHoursApi _workingHoursApi;

  Future<List<Map<String, dynamic>>> getWorkingHours({
    bool includeInactive = false,
  }) {
    return _workingHoursApi.getWorkingHours(includeInactive: includeInactive);
  }

  Future<Map<String, dynamic>> createWorkingHour({
    required int businessId,
    required int specialistId,
    required int weekday,
    required String startTime,
    required String endTime,
  }) {
    return _workingHoursApi.createWorkingHour(
      businessId: businessId,
      specialistId: specialistId,
      weekday: weekday,
      startTime: startTime,
      endTime: endTime,
    );
  }

  Future<Map<String, dynamic>> updateWorkingHour({
    required int workingHourId,
    required int weekday,
    required String startTime,
    required String endTime,
    required bool isActive,
  }) {
    return _workingHoursApi.updateWorkingHour(
      workingHourId: workingHourId,
      weekday: weekday,
      startTime: startTime,
      endTime: endTime,
      isActive: isActive,
    );
  }

  Future<Map<String, dynamic>> disableWorkingHour({
    required int workingHourId,
  }) {
    return _workingHoursApi.disableWorkingHour(workingHourId: workingHourId);
  }
}
