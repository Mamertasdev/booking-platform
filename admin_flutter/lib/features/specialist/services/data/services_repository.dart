import '../../../../core/api/services_api.dart';

class ServicesRepository {
  ServicesRepository({required ServicesApi servicesApi})
    : _servicesApi = servicesApi;

  final ServicesApi _servicesApi;

  Future<List<Map<String, dynamic>>> getServices({
    bool includeInactive = false,
  }) {
    return _servicesApi.getServices(includeInactive: includeInactive);
  }

  Future<Map<String, dynamic>> createService({
    required String name,
    required int durationMinutes,
    required int price,
  }) {
    return _servicesApi.createService(
      name: name,
      durationMinutes: durationMinutes,
      price: price,
    );
  }

  Future<Map<String, dynamic>> updateService({
    required int serviceId,
    required String name,
    required int durationMinutes,
    required int price,
    required bool isActive,
  }) {
    return _servicesApi.updateService(
      serviceId: serviceId,
      name: name,
      durationMinutes: durationMinutes,
      price: price,
      isActive: isActive,
    );
  }

  Future<Map<String, dynamic>> disableService({required int serviceId}) {
    return _servicesApi.disableService(serviceId: serviceId);
  }
}
