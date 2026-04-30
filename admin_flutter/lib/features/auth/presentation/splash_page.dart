import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../admin/presentation/admin_home_page.dart';
import '../../owner/presentation/owner_home_page.dart';
import '../../specialist/presentation/specialist_home_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      tokenStorage: tokenStorage,
    );
    final authApi = AuthApi(apiClient);

    _authRepository = AuthRepository(
      authApi: authApi,
      tokenStorage: tokenStorage,
    );

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = await _authRepository.restoreUser();

    if (!mounted) return;

    if (user == null) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }

    final role = (user['role'] as String? ?? '').toLowerCase();

    if (role == 'admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminHomePage(user: user)),
      );
      return;
    }

    if (role == 'owner') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OwnerHomePage(user: user)),
      );
      return;
    }

    if (role == 'specialist') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SpecialistHomePage(user: user)),
      );
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
