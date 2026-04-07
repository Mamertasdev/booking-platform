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

  Future<Map<String, dynamic>> disableBusiness({required int businessId}) {
    return _businessesApi.disableBusiness(businessId: businessId);
  }
}
