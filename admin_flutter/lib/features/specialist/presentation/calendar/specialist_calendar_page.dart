import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/appointments_api.dart';
import '../../../../core/storage/token_storage.dart';
import '../appointments/data/appointments_repository.dart';

class SpecialistCalendarPage extends StatefulWidget {
  const SpecialistCalendarPage({super.key});

  @override
  State<SpecialistCalendarPage> createState() => _SpecialistCalendarPageState();
}

class _SpecialistCalendarPageState extends State<SpecialistCalendarPage> {
  late final AppointmentsRepository _appointmentsRepository;

  DateTime _selectedDate = DateTime.now();
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

    _loadAppointmentsForSelectedDate();
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

      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    } catch (_) {
      return value;
    }
  }

  Future<void> _loadAppointmentsForSelectedDate() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final data = await _appointmentsRepository.getMyAppointmentsForDate(
        targetDate: _toApiDate(_selectedDate),
      );

      if (!mounted) return;

      setState(() {
        _appointments = data;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti dienos vizitų';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

    await _loadAppointmentsForSelectedDate();
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadAppointmentsForSelectedDate();
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadAppointmentsForSelectedDate();
  }

  Widget _buildHeader() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Dienos kalendorius',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                onPressed: _loadAppointmentsForSelectedDate,
                child: const Text('Bandyti dar kartą'),
              ),
            ],
          ),
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Text(
          'Šiai dienai vizitų nėra',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointmentsForSelectedDate,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final appointment = _appointments[index];

          final clientName = appointment['client_full_name']?.toString() ?? '-';
          final appointmentStart =
              appointment['appointment_start']?.toString() ?? '';
          final appointmentEnd =
              appointment['appointment_end']?.toString() ?? '';
          final status = appointment['status']?.toString() ?? '-';
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
                  Text(
                    clientName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Laikas: ${_formatDateTime(appointmentStart)} - ${_formatDateTime(appointmentEnd)}',
                  ),
                  const SizedBox(height: 4),
                  Text('Statusas: $status'),
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
      appBar: AppBar(title: const Text('Kalendorius')),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
