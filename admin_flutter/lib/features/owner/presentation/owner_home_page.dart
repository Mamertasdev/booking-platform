import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../admin/presentation/admin_availability_exceptions_page.dart';
import '../../admin/presentation/admin_working_hours_page.dart';
import '../../auth/presentation/login_page.dart';
import 'owner_appointments_page.dart';
import 'owner_specialists_page.dart';

class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key, required this.user});

  final Map<String, dynamic> user;

  void _openSpecialists(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const OwnerSpecialistsPage()));
  }

  void _openAppointments(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const OwnerAppointmentsPage()));
  }

  void _openWorkingHours(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminWorkingHoursPage()));
  }

  void _openAvailabilityExceptions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AdminAvailabilityExceptionsPage(),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
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
        title: const Text('Verslo valdymas'),
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
                title: const Text('Prisijungęs verslo savininkas'),
                subtitle: Text('$fullName'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  Card(
                    child: ListTile(
                      title: const Text('Specialistai'),
                      subtitle: const Text(
                        'Peržiūrėti ir valdyti savo verslo specialistus',
                      ),
                      onTap: () => _openSpecialists(context),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Rezervacijos'),
                      subtitle: const Text(
                        'Peržiūrėti savo verslo rezervacijas',
                      ),
                      onTap: () => _openAppointments(context),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Darbo laikai'),
                      subtitle: const Text(
                        'Peržiūrėti ir valdyti savo verslo darbo laikus',
                      ),
                      onTap: () => _openWorkingHours(context),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Išimtys'),
                      subtitle: const Text(
                        'Peržiūrėti ir valdyti savo verslo išimtis',
                      ),
                      onTap: () => _openAvailabilityExceptions(context),
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
