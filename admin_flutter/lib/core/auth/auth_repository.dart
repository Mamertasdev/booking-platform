import '../api/auth_api.dart';
import '../storage/token_storage.dart';

class AuthRepository {
  AuthRepository({required AuthApi authApi, required TokenStorage tokenStorage})
    : _authApi = authApi,
      _tokenStorage = tokenStorage;

  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final token = await _authApi.login(username: username, password: password);

    await _tokenStorage.saveToken(token);
  }

  Future<Map<String, dynamic>?> restoreUser() async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      return await _authApi.getMe();
    } catch (_) {
      await _tokenStorage.clearToken();
      return null;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return _authApi.getMe();
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
  }
}
