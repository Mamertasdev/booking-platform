import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/availability_api.dart';
import '../../../../core/api/services_api.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/availability_repository.dart';
import '../../services/data/services_repository.dart';

class SpecialistAvailabilityPage extends StatefulWidget {
  const SpecialistAvailabilityPage({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<SpecialistAvailabilityPage> createState() =>
      _SpecialistAvailabilityPageState();
}

class _SpecialistAvailabilityPageState
    extends State<SpecialistAvailabilityPage> {
  late final ServicesRepository _servicesRepository;
  late final AvailabilityRepository _availabilityRepository;

  DateTime _selectedDate = DateTime.now();
  bool _isLoadingServices = true;
  bool _isLoadingAvailability = false;
  String? _errorText;

  List<Map<String, dynamic>> _services = [];
  int? _selectedServiceId;
  Map<String, dynamic>? _availabilityData;

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: 'http://100.80.21.21:8000',
      tokenStorage: tokenStorage,
    );

    final servicesApi = ServicesApi(apiClient);
    final availabilityApi = AvailabilityApi(apiClient);

    _servicesRepository = ServicesRepository(servicesApi: servicesApi);
    _availabilityRepository = AvailabilityRepository(
      availabilityApi: availabilityApi,
    );

    _loadServices();
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

  String _normalizeTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;

    final hour = parts[0].padLeft(2, '0');
    final minute = parts[1].padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTimeToHourMinute(String value) {
    try {
      final dateTime = DateTime.parse(value).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return value;
    }
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case 0:
        return 'Pirmadienis';
      case 1:
        return 'Antradienis';
      case 2:
        return 'Trečiadienis';
      case 3:
        return 'Ketvirtadienis';
      case 4:
        return 'Penktadienis';
      case 5:
        return 'Šeštadienis';
      case 6:
        return 'Sekmadienis';
      default:
        return 'Nežinoma diena';
    }
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoadingServices = true;
      _errorText = null;
    });

    try {
      final data = await _servicesRepository.getServices(
        includeInactive: false,
      );

      if (!mounted) return;

      setState(() {
        _services = data;
        if (_services.isNotEmpty) {
          _selectedServiceId = _services.first['id'] as int;
        }
      });

      if (_selectedServiceId != null) {
        await _loadAvailability();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti paslaugų';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
    }
  }

  Future<void> _loadAvailability() async {
    final businessId = widget.user['business_id'] as int?;
    final specialistId = widget.user['id'] as int?;
    final serviceId = _selectedServiceId;

    if (businessId == null || specialistId == null || serviceId == null) {
      setState(() {
        _errorText = 'Nepavyko nustatyti reikiamų duomenų';
      });
      return;
    }

    setState(() {
      _isLoadingAvailability = true;
      _errorText = null;
    });

    try {
      final data = await _availabilityRepository.getAvailability(
        businessId: businessId,
        specialistId: specialistId,
        serviceId: serviceId,
        targetDate: _toApiDate(_selectedDate),
      );

      if (!mounted) return;

      setState(() {
        _availabilityData = data;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti laisvų laikų';
        _availabilityData = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAvailability = false;
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

    await _loadAvailability();
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadAvailability();
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadAvailability();
  }

  Widget _buildTopControls() {
    if (_isLoadingServices) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Nėra aktyvių paslaugų. Pirmiausia sukurkite bent vieną paslaugą.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              initialValue: _selectedServiceId,
              decoration: const InputDecoration(
                labelText: 'Paslauga',
                border: OutlineInputBorder(),
              ),
              items: _services.map((service) {
                final serviceId = service['id'] as int;
                final name = service['name']?.toString() ?? '-';
                final duration = service['duration_minutes']?.toString() ?? '?';

                return DropdownMenuItem<int>(
                  value: serviceId,
                  child: Text('$name ($duration min)'),
                );
              }).toList(),
              onChanged: _isLoadingAvailability
                  ? null
                  : (value) async {
                      if (value == null) return;
                      setState(() {
                        _selectedServiceId = value;
                      });
                      await _loadAvailability();
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

  Widget _buildSlotsSection(List<dynamic> slots) {
    if (slots.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Šiai dienai laisvų laikų nėra',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laisvi laikai',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) {
                final item = slot as Map<String, dynamic>;
                final startTime = _normalizeTime(
                  item['start_time']?.toString() ?? '',
                );
                final endTime = _normalizeTime(
                  item['end_time']?.toString() ?? '',
                );

                return Chip(label: Text('$startTime - $endTime'));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHoursSection(List<dynamic> workingHours) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Darbo laikai tai dienai',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (workingHours.isEmpty)
              const Text('Darbo laikų šiai dienai nėra')
            else
              ...workingHours.map((item) {
                final row = item as Map<String, dynamic>;
                final startTime = _normalizeTime(
                  row['start_time']?.toString() ?? '',
                );
                final endTime = _normalizeTime(
                  row['end_time']?.toString() ?? '',
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('$startTime - $endTime'),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsSection(List<dynamic> appointments) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esamos rezervacijos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (appointments.isEmpty)
              const Text('Rezervacijų šiai dienai nėra')
            else
              ...appointments.map((item) {
                final row = item as Map<String, dynamic>;
                final start = _formatDateTimeToHourMinute(
                  row['appointment_start']?.toString() ?? '',
                );
                final end = _formatDateTimeToHourMinute(
                  row['appointment_end']?.toString() ?? '',
                );
                final clientName = row['client_full_name']?.toString() ?? '-';
                final status = row['status']?.toString() ?? '-';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('$start - $end • $clientName • $status'),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildExceptionsSection(List<dynamic> exceptions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Išimtys',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (exceptions.isEmpty)
              const Text('Išimčių šiai dienai nėra')
            else
              ...exceptions.map((item) {
                final row = item as Map<String, dynamic>;
                final start = _formatDateTimeToHourMinute(
                  row['start_datetime']?.toString() ?? '',
                );
                final end = _formatDateTimeToHourMinute(
                  row['end_datetime']?.toString() ?? '',
                );
                final reason = row['reason']?.toString() ?? '-';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('$start - $end • $reason'),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityContent() {
    if (_isLoadingAvailability) {
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
                  onPressed: _loadAvailability,
                  child: const Text('Bandyti dar kartą'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_availabilityData == null) {
      return const Expanded(
        child: Center(
          child: Text(
            'Pasirinkite paslaugą ir datą',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final weekday = _availabilityData!['weekday'] as int? ?? 0;
    final serviceDuration =
        _availabilityData!['service_duration_minutes']?.toString() ?? '-';
    final slots = (_availabilityData!['slots'] as List<dynamic>? ?? []);
    final workingHours =
        (_availabilityData!['working_hours'] as List<dynamic>? ?? []);
    final appointments =
        (_availabilityData!['appointments'] as List<dynamic>? ?? []);
    final exceptions =
        (_availabilityData!['exceptions'] as List<dynamic>? ?? []);

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadAvailability,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Santrauka',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Diena: ${_weekdayLabel(weekday)}'),
                    const SizedBox(height: 4),
                    Text('Paslaugos trukmė: $serviceDuration min'),
                    const SizedBox(height: 4),
                    Text('Laisvų slotų kiekis: ${slots.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildSlotsSection(slots),
            const SizedBox(height: 12),
            _buildWorkingHoursSection(workingHours),
            const SizedBox(height: 12),
            _buildAppointmentsSection(appointments),
            const SizedBox(height: 12),
            _buildExceptionsSection(exceptions),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.user['full_name']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Laisvi laikai')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              child: ListTile(
                title: const Text('Specialistas'),
                subtitle: Text(fullName),
              ),
            ),
          ),
          _buildTopControls(),
          _buildAvailabilityContent(),
        ],
      ),
    );
  }
}
