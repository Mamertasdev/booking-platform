import '../../../core/api/availability_api.dart';

class AvailabilityRepository {
  AvailabilityRepository({required AvailabilityApi availabilityApi})
    : _availabilityApi = availabilityApi;

  final AvailabilityApi _availabilityApi;

  Future<Map<String, dynamic>> getAvailability({
    required int businessId,
    required int specialistId,
    required int serviceId,
    required String targetDate,
  }) {
    return _availabilityApi.getAvailability(
      businessId: businessId,
      specialistId: specialistId,
      serviceId: serviceId,
      targetDate: targetDate,
    );
  }
}
