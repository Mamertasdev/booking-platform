import 'package:flutter/material.dart';

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/availability_api.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../data/availability_repository.dart';

class AppointmentRescheduleSlotPickerPage extends StatefulWidget {
  const AppointmentRescheduleSlotPickerPage({
    super.key,
    required this.businessId,
    required this.specialistId,
    required this.serviceId,
    required this.initialAppointmentStart,
    required this.onSubmit,
  });

  final int businessId;
  final int specialistId;
  final int serviceId;
  final String initialAppointmentStart;
  final Future<void> Function({required String appointmentStartIso}) onSubmit;

  @override
  State<AppointmentRescheduleSlotPickerPage> createState() =>
      _AppointmentRescheduleSlotPickerPageState();
}

class _AppointmentRescheduleSlotPickerPageState
    extends State<AppointmentRescheduleSlotPickerPage> {
  late final AvailabilityRepository _availabilityRepository;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _errorText;
  Map<String, dynamic>? _availabilityData;

  @override
  void initState() {
    super.initState();

    final parsed = DateTime.tryParse(widget.initialAppointmentStart)?.toLocal();
    if (parsed != null) {
      _selectedDate = parsed;
    }

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: 'http://100.80.21.21:8000',
      tokenStorage: tokenStorage,
    );
    final availabilityApi = AvailabilityApi(apiClient);

    _availabilityRepository = AvailabilityRepository(
      availabilityApi: availabilityApi,
    );

    _loadAvailability();
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

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final data = await _availabilityRepository.getAvailability(
        businessId: widget.businessId,
        specialistId: widget.specialistId,
        serviceId: widget.serviceId,
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

  DateTime? _buildAppointmentStartFromSlot(String slotStartTime) {
    final parts = slotStartTime.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );
  }

  Future<void> _submitSlot(Map<String, dynamic> slot) async {
    final slotStartTime = slot['start_time']?.toString() ?? '';
    final appointmentStart = _buildAppointmentStartFromSlot(slotStartTime);

    if (appointmentStart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko suformuoti naujo laiko')),
      );
      return;
    }

    try {
      await widget.onSubmit(
        appointmentStartIso: appointmentStart.toIso8601String(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _buildHeader() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Pasirinkite naują laiką',
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

    final slots = (_availabilityData?['slots'] as List<dynamic>? ?? []);

    if (slots.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'Šiai dienai laisvų laikų nėra',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadAvailability,
        child: ListView(
          padding: const EdgeInsets.all(16),
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

                return ActionChip(
                  label: Text('$startTime - $endTime'),
                  onPressed: () => _submitSlot(item),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Paspauskite ant laisvo laiko, kad perkeltumėte vizitą.',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perkelti vizitą')),
      body: Column(children: [_buildHeader(), _buildContent()]),
    );
  }
}
