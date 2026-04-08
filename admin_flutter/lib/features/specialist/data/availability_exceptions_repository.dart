import '../../../core/api/availability_exceptions_api.dart';

class AvailabilityExceptionsRepository {
  AvailabilityExceptionsRepository({
    required AvailabilityExceptionsApi availabilityExceptionsApi,
  }) : _availabilityExceptionsApi = availabilityExceptionsApi;

  final AvailabilityExceptionsApi _availabilityExceptionsApi;

  Future<List<Map<String, dynamic>>> getAvailabilityExceptions({
    int? businessId,
    int? specialistId,
    String? targetDate,
    bool includeInactive = false,
  }) {
    return _availabilityExceptionsApi.getAvailabilityExceptions(
      businessId: businessId,
      specialistId: specialistId,
      targetDate: targetDate,
      includeInactive: includeInactive,
    );
  }

  Future<Map<String, dynamic>> createAvailabilityException({
    required int businessId,
    required int specialistId,
    required String startDateTimeIso,
    required String endDateTimeIso,
    String? reason,
  }) {
    return _availabilityExceptionsApi.createAvailabilityException(
      businessId: businessId,
      specialistId: specialistId,
      startDateTimeIso: startDateTimeIso,
      endDateTimeIso: endDateTimeIso,
      reason: reason,
    );
  }

  Future<Map<String, dynamic>> updateAvailabilityException({
    required int exceptionId,
    required String startDateTimeIso,
    required String endDateTimeIso,
    String? reason,
    required bool isActive,
  }) {
    return _availabilityExceptionsApi.updateAvailabilityException(
      exceptionId: exceptionId,
      startDateTimeIso: startDateTimeIso,
      endDateTimeIso: endDateTimeIso,
      reason: reason,
      isActive: isActive,
    );
  }

  Future<Map<String, dynamic>> disableAvailabilityException({
    required int exceptionId,
  }) {
    return _availabilityExceptionsApi.disableAvailabilityException(
      exceptionId: exceptionId,
    );
  }
}
