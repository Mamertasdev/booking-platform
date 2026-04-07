import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/presentation/login_page.dart';
import 'businesses_page.dart';
import 'specialists_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key, required this.user});

  final Map<String, dynamic> user;

  void _openBusinesses(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BusinessesPage()));
  }

  void _openSpecialists(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SpecialistsPage()));
  }

  Future<void> _logout(BuildContext context) async {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: 'http://100.80.21.21:8000',
      tokenStorage: tokenStorage,
    );
    final authApi = AuthApi(apiClient);

    final authRepository = AuthRepository(
      authApi: authApi,
      tokenStorage: tokenStorage,
    );

    await authRepository.logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = user['full_name'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Prisijungęs admin'),
                subtitle: Text('$fullName'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  Card(
                    child: ListTile(
                      title: const Text('Verslai'),
                      subtitle: const Text('Peržiūrėti ir kurti verslus'),
                      onTap: () => _openBusinesses(context),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Vartotojai'),
                      subtitle: const Text(
                        'Peržiūrėti ir kurti admin bei specialistų vartotojus',
                      ),
                      onTap: () => _openSpecialists(context),
                    ),
                  ),
                  const Card(
                    child: ListTile(
                      title: Text('Rezervacijos'),
                      subtitle: Text('Čia bus visų rezervacijų sąrašas'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
