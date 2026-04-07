import '../../../core/api/specialists_api.dart';

class SpecialistsRepository {
  SpecialistsRepository({required SpecialistsApi specialistsApi})
    : _specialistsApi = specialistsApi;

  final SpecialistsApi _specialistsApi;

  Future<List<Map<String, dynamic>>> getSpecialists({
    int? businessId,
    bool includeInactive = false,
  }) {
    return _specialistsApi.getSpecialists(
      businessId: businessId,
      includeInactive: includeInactive,
    );
  }

  Future<Map<String, dynamic>> createSpecialist({
    required int businessId,
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) {
    return _specialistsApi.createSpecialist(
      businessId: businessId,
      username: username,
      password: password,
      fullName: fullName,
      role: role,
    );
  }

  Future<Map<String, dynamic>> disableSpecialist({required int specialistId}) {
    return _specialistsApi.disableSpecialist(specialistId: specialistId);
  }
}
