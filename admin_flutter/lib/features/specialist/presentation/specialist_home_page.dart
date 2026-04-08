import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/presentation/login_page.dart';
import '../services/data/presentation/my_services_page.dart';
import 'appointments/presentation/my_appointments_page.dart';
import 'availability/specialist_availability_page.dart';
import 'calendar/specialist_calendar_page.dart';
import 'exceptions/my_availability_exceptions_page.dart';
import 'working_hours/my_working_hours_page.dart';

class SpecialistHomePage extends StatelessWidget {
  const SpecialistHomePage({super.key, required this.user});

  final Map<String, dynamic> user;

  void _openAppointments(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MyAppointmentsPage()));
  }

  void _openServices(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MyServicesPage()));
  }

  void _openWorkingHours(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => MyWorkingHoursPage(user: user)));
  }

  void _openCalendar(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SpecialistCalendarPage()));
  }

  void _openAvailability(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SpecialistAvailabilityPage(user: user)),
    );
  }

  void _openExceptions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyAvailabilityExceptionsPage(user: user),
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
        title: const Text('Specialistas'),
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
                title: const Text('Prisijungęs specialistas'),
                subtitle: Text('$fullName'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  Card(
                    child: ListTile(
                      title: const Text('Vizitai'),
                      subtitle: const Text('Atidaryti specialisto vizitus'),
                      onTap: () => _openAppointments(context),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Paslaugos'),
                      subtitle: const Text('Atidaryti specialisto paslaugas'),
                      onTap: () => _openServices(context),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Darbo laikas'),
                      subtitle: const Text(
                        'Atidaryti specialisto darbo laikus',
                      ),
                      onTap: () => _openWorkingHours(context),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Išimtys'),
                      subtitle: const Text('Valdyti darbo grafiko išimtis'),
                      onTap: () => _openExceptions(context),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Kalendorius'),
                      subtitle: const Text('Peržiūrėti dienos užimtumą'),
                      onTap: () => _openCalendar(context),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Laisvi laikai'),
                      subtitle: const Text(
                        'Peržiūrėti galimus rezervacijos slotus',
                      ),
                      onTap: () => _openAvailability(context),
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
