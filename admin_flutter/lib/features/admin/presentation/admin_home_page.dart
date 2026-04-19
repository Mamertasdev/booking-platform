import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/presentation/login_page.dart';
import 'admin_appointments_page.dart';
import 'admin_availability_exceptions_page.dart';
import 'admin_working_hours_page.dart';
import 'businesses_page.dart';
import 'specialists_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key, required this.user});

  final Map<String, dynamic> user;

  bool get _isAdmin =>
      (user['role']?.toString().toLowerCase() ?? '') == 'admin';
  bool get _isOwner =>
      (user['role']?.toString().toLowerCase() ?? '') == 'owner';

  String get _pageTitle {
    if (_isOwner) return 'Verslo valdymas';
    return 'Admin';
  }

  String get _userLabel {
    if (_isOwner) return 'Prisijungęs verslo savininkas';
    return 'Prisijungęs admin';
  }

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

  void _openAppointments(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminAppointmentsPage()));
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
        title: Text(_pageTitle),
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
                title: Text(_userLabel),
                subtitle: Text('$fullName'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  if (_isAdmin)
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
                      subtitle: Text(
                        _isOwner
                            ? 'Peržiūrėti ir valdyti savo verslo specialistus'
                            : 'Peržiūrėti ir kurti admin, owner bei specialistų vartotojus',
                      ),
                      onTap: () => _openSpecialists(context),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Rezervacijos'),
                      subtitle: Text(
                        _isOwner
                            ? 'Peržiūrėti savo verslo rezervacijas'
                            : 'Peržiūrėti visas rezervacijas su filtrais',
                      ),
                      onTap: () => _openAppointments(context),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Darbo laikai'),
                      subtitle: Text(
                        _isOwner
                            ? 'Peržiūrėti ir valdyti savo verslo darbo laikus'
                            : 'Peržiūrėti ir valdyti specialistų darbo laikus',
                      ),
                      onTap: () => _openWorkingHours(context),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Išimtys'),
                      subtitle: Text(
                        _isOwner
                            ? 'Peržiūrėti ir valdyti savo verslo išimtis'
                            : 'Peržiūrėti ir valdyti specialistų išimtis',
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
