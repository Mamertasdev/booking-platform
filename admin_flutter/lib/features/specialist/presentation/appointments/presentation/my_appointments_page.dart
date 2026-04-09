import 'package:flutter/material.dart';

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/appointments_api.dart';
import '../../../../../core/storage/token_storage.dart';
import '../data/appointments_repository.dart';
import 'appointment_reschedule_slot_picker_page.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  late final AppointmentsRepository _appointmentsRepository;

  bool _isLoading = true;
  String? _errorText;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: 'http://100.80.21.21:8000',
      tokenStorage: tokenStorage,
    );
    final appointmentsApi = AppointmentsApi(apiClient);

    _appointmentsRepository = AppointmentsRepository(
      appointmentsApi: appointmentsApi,
    );

    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final data = await _appointmentsRepository.getMyAppointments();

      if (!mounted) return;

      setState(() {
        _appointments = data;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti vizitų';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateTime(String value) {
    try {
      final dateTime = DateTime.parse(value).toLocal();

      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year.toString();

      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return '$day.$month.$year $hour:$minute';
    } catch (_) {
      return value;
    }
  }

  Future<void> _openReschedulePage(Map<String, dynamic> appointment) async {
    final appointmentId = appointment['id'] as int;
    final appointmentStart = appointment['appointment_start']?.toString() ?? '';
    final businessId = appointment['business_id'] as int?;
    final specialistId = appointment['specialist_id'] as int?;
    final serviceId = appointment['service_id'] as int?;

    if (businessId == null || specialistId == null || serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko nustatyti vizito duomenų')),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AppointmentRescheduleSlotPickerPage(
          businessId: businessId,
          specialistId: specialistId,
          serviceId: serviceId,
          initialAppointmentStart: appointmentStart,
          onSubmit: ({required String appointmentStartIso}) {
            return _appointmentsRepository.rescheduleAppointment(
              appointmentId: appointmentId,
              appointmentStartIso: appointmentStartIso,
            );
          },
        ),
      ),
    );

    if (result == true) {
      await _loadAppointments();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vizitas perkeltas')));
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorText!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadAppointments,
                child: const Text('Bandyti dar kartą'),
              ),
            ],
          ),
        ),
      );
    }

    if (_appointments.isEmpty) {
      return const Center(
        child: Text('Vizitų nerasta', style: TextStyle(fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final appointment = _appointments[index];

          final clientName = appointment['client_full_name']?.toString() ?? '-';
          final appointmentId = appointment['id'] as int;
          final appointmentStart =
              appointment['appointment_start']?.toString() ?? '';
          final appointmentEnd =
              appointment['appointment_end']?.toString() ?? '';
          final status = appointment['status']?.toString() ?? '-';
          final serviceId = appointment['service_id']?.toString() ?? '-';
          final isActive = appointment['is_active'] as bool? ?? false;
          final email = appointment['client_email']?.toString();
          final phone = appointment['client_phone']?.toString();
          final notes = appointment['notes']?.toString();

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          clientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'reschedule') {
                            _openReschedulePage(appointment);
                          }
                        },
                        itemBuilder: (_) => [
                          if (isActive)
                            const PopupMenuItem(
                              value: 'reschedule',
                              child: Text('Perkelti laiką'),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Laikas: ${_formatDateTime(appointmentStart)} - ${_formatDateTime(appointmentEnd)}',
                  ),
                  const SizedBox(height: 4),
                  Text('Statusas: $status'),
                  const SizedBox(height: 4),
                  Text('Vizito ID: $appointmentId'),
                  const SizedBox(height: 4),
                  Text('Paslaugos ID: $serviceId'),
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('El. paštas: $email'),
                  ],
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Telefonas: $phone'),
                  ],
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Pastabos: $notes'),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mano vizitai')),
      body: _buildContent(),
    );
  }
}
