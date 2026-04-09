import '../../../core/api/businesses_api.dart';

class BusinessesRepository {
  BusinessesRepository({required BusinessesApi businessesApi})
    : _businessesApi = businessesApi;

  final BusinessesApi _businessesApi;

  Future<List<Map<String, dynamic>>> getBusinesses({
    bool includeInactive = false,
  }) {
    return _businessesApi.getBusinesses(includeInactive: includeInactive);
  }

  Future<Map<String, dynamic>> createBusiness({required String name}) {
    return _businessesApi.createBusiness(name: name);
  }

  Future<Map<String, dynamic>> updateBusiness({
    required int businessId,
    required String name,
    required bool isActive,
  }) {
    return _businessesApi.updateBusiness(
      businessId: businessId,
      name: name,
      isActive: isActive,
    );
  }

  Future<Map<String, dynamic>> disableBusiness({required int businessId}) {
    return _businessesApi.disableBusiness(businessId: businessId);
  }
}
