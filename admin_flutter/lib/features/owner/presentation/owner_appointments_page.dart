import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/appointments_api.dart';
import '../../../core/api/specialists_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../admin/data/specialists_repository.dart';
import '../../specialist/presentation/appointments/data/appointments_repository.dart';
import '../../specialist/presentation/appointments/presentation/appointment_reschedule_slot_picker_page.dart';

class OwnerAppointmentsPage extends StatefulWidget {
  const OwnerAppointmentsPage({super.key});

  @override
  State<OwnerAppointmentsPage> createState() => _OwnerAppointmentsPageState();
}

class _OwnerAppointmentsPageState extends State<OwnerAppointmentsPage> {
  late final SpecialistsRepository _specialistsRepository;
  late final AppointmentsRepository _appointmentsRepository;

  bool _isLoadingFilters = true;
  bool _isLoadingAppointments = false;
  String? _errorText;

  List<Map<String, dynamic>> _specialists = [];
  List<Map<String, dynamic>> _appointments = [];

  int? _selectedSpecialistId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      tokenStorage: tokenStorage,
    );

    _specialistsRepository = SpecialistsRepository(
      specialistsApi: SpecialistsApi(apiClient),
    );

    _appointmentsRepository = AppointmentsRepository(
      appointmentsApi: AppointmentsApi(apiClient),
    );

    _loadInitialData();
  }

  String _toApiDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _toDisplayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
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

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Laukia patvirtinimo';
      case 'confirmed':
        return 'Patvirtintas';
      case 'completed':
        return 'Atliktas';
      case 'no_show':
        return 'Neatvyko';
      case 'cancelled_by_admin':
        return 'Atšauktas administratoriaus';
      case 'cancelled_by_client':
        return 'Atšauktas kliento';
      default:
        return status;
    }
  }

  String _specialistNameById(int? specialistId) {
    if (specialistId == null) return '-';

    for (final specialist in _specialists) {
      if (specialist['id'] == specialistId) {
        return specialist['full_name']?.toString() ?? '-';
      }
    }

    return 'ID: $specialistId';
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingFilters = true;
      _errorText = null;
    });

    try {
      final specialists = await _specialistsRepository.getSpecialists(
        includeInactive: true,
      );

      if (!mounted) return;

      setState(() {
        _specialists = specialists;
      });

      await _loadAppointments();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti specialistų';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFilters = false;
        });
      }
    }
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoadingAppointments = true;
      _errorText = null;
    });

    try {
      final appointments = await _appointmentsRepository.getAppointments(
        specialistId: _selectedSpecialistId,
        targetDate: _toApiDate(_selectedDate),
      );

      if (!mounted) return;

      setState(() {
        _appointments = appointments;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti rezervacijų';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAppointments = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });

    await _loadAppointments();
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadAppointments();
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadAppointments();
  }

  Future<void> _changeStatus({
    required int appointmentId,
    required String status,
  }) async {
    try {
      await _appointmentsRepository.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vizito statusas atnaujintas')),
      );

      await _loadAppointments();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko atnaujinti statuso')),
      );
    }
  }

  Future<void> _cancelAppointment({required int appointmentId}) async {
    try {
      await _appointmentsRepository.cancelAppointment(
        appointmentId: appointmentId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vizitas atšauktas')));

      await _loadAppointments();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nepavyko atšaukti vizito')));
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

  Widget _buildFiltersSection() {
    if (_isLoadingFilters) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<int?>(
              initialValue: _selectedSpecialistId,
              decoration: const InputDecoration(
                labelText: 'Specialistas',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Visi specialistai'),
                ),
                ..._specialists.map((specialist) {
                  final fullName = specialist['full_name']?.toString() ?? '-';
                  final role = specialist['role']?.toString() ?? '-';

                  return DropdownMenuItem<int?>(
                    value: specialist['id'] as int,
                    child: Text('$fullName ($role)'),
                  );
                }),
              ],
              onChanged: _isLoadingAppointments
                  ? null
                  : (value) async {
                      setState(() {
                        _selectedSpecialistId = value;
                      });

                      await _loadAppointments();
                    },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: _goToPreviousDay,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _toDisplayDate(_selectedDate),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _goToNextDay,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _pickDate,
              child: const Text('Pasirinkti datą'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsContent() {
    if (_isLoadingAppointments) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (_errorText != null) {
      return Expanded(
        child: Center(
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
        ),
      );
    }

    if (_appointments.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('Rezervacijų nerasta', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _appointments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final appointment = _appointments[index];

            final appointmentId = appointment['id'] as int;
            final clientName =
                appointment['client_full_name']?.toString() ?? '-';
            final appointmentStart =
                appointment['appointment_start']?.toString() ?? '';
            final appointmentEnd =
                appointment['appointment_end']?.toString() ?? '';
            final status = appointment['status']?.toString() ?? '-';
            final isActive = appointment['is_active'] as bool? ?? false;
            final specialistId = appointment['specialist_id'] as int?;
            final serviceId = appointment['service_id']?.toString() ?? '-';
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
                            if (value == 'confirmed') {
                              _changeStatus(
                                appointmentId: appointmentId,
                                status: 'confirmed',
                              );
                            } else if (value == 'completed') {
                              _changeStatus(
                                appointmentId: appointmentId,
                                status: 'completed',
                              );
                            } else if (value == 'no_show') {
                              _changeStatus(
                                appointmentId: appointmentId,
                                status: 'no_show',
                              );
                            } else if (value == 'cancelled_by_admin') {
                              _cancelAppointment(appointmentId: appointmentId);
                            } else if (value == 'reschedule') {
                              _openReschedulePage(appointment);
                            }
                          },
                          itemBuilder: (_) => [
                            if (isActive)
                              const PopupMenuItem(
                                value: 'confirmed',
                                child: Text('Patvirtinti'),
                              ),
                            if (isActive)
                              const PopupMenuItem(
                                value: 'completed',
                                child: Text('Pažymėti kaip atliktą'),
                              ),
                            if (isActive)
                              const PopupMenuItem(
                                value: 'no_show',
                                child: Text('Pažymėti kaip neatvykusį'),
                              ),
                            if (isActive)
                              const PopupMenuItem(
                                value: 'reschedule',
                                child: Text('Perkelti laiką'),
                              ),
                            if (isActive)
                              const PopupMenuItem(
                                value: 'cancelled_by_admin',
                                child: Text('Atšaukti vizitą'),
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
                    Text('Statusas: ${_statusLabel(status)}'),
                    const SizedBox(height: 4),
                    Text('Specialistas: ${_specialistNameById(specialistId)}'),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verslo rezervacijos')),
      body: Column(
        children: [_buildFiltersSection(), _buildAppointmentsContent()],
      ),
    );
  }
}
