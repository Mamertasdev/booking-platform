import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/working_hours_api.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/working_hours_repository.dart';
import 'working_hour_form_page.dart';

class MyWorkingHoursPage extends StatefulWidget {
  const MyWorkingHoursPage({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<MyWorkingHoursPage> createState() => _MyWorkingHoursPageState();
}

class _MyWorkingHoursPageState extends State<MyWorkingHoursPage> {
  late final WorkingHoursRepository _workingHoursRepository;

  bool _isLoading = true;
  String? _errorText;
  List<Map<String, dynamic>> _workingHours = [];

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: 'http://100.80.21.21:8000',
      tokenStorage: tokenStorage,
    );
    final workingHoursApi = WorkingHoursApi(apiClient);

    _workingHoursRepository = WorkingHoursRepository(
      workingHoursApi: workingHoursApi,
    );

    _loadWorkingHours();
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

  String _normalizeTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;

    final hour = parts[0].padLeft(2, '0');
    final minute = parts[1].padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _loadWorkingHours() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final data = await _workingHoursRepository.getWorkingHours(
        includeInactive: true,
      );

      if (!mounted) return;

      setState(() {
        _workingHours = data;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti darbo laikų';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openCreatePage() async {
    final businessId = widget.user['business_id'] as int?;
    final specialistId = widget.user['id'] as int?;

    if (businessId == null || specialistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko nustatyti vartotojo duomenų')),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkingHourFormPage(
          title: 'Naujas darbo laikas',
          onSubmit:
              ({
                required int weekday,
                required String startTime,
                required String endTime,
                required bool isActive,
              }) {
                return _workingHoursRepository.createWorkingHour(
                  businessId: businessId,
                  specialistId: specialistId,
                  weekday: weekday,
                  startTime: startTime,
                  endTime: endTime,
                );
              },
        ),
      ),
    );

    if (result == true) {
      await _loadWorkingHours();
    }
  }

  Future<void> _openEditPage(Map<String, dynamic> workingHour) async {
    final workingHourId = workingHour['id'] as int;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkingHourFormPage(
          title: 'Redaguoti darbo laiką',
          initialData: workingHour,
          onSubmit:
              ({
                required int weekday,
                required String startTime,
                required String endTime,
                required bool isActive,
              }) {
                return _workingHoursRepository.updateWorkingHour(
                  workingHourId: workingHourId,
                  weekday: weekday,
                  startTime: startTime,
                  endTime: endTime,
                  isActive: isActive,
                );
              },
        ),
      ),
    );

    if (result == true) {
      await _loadWorkingHours();
    }
  }

  Future<void> _disableWorkingHour(Map<String, dynamic> workingHour) async {
    final workingHourId = workingHour['id'] as int;

    try {
      await _workingHoursRepository.disableWorkingHour(
        workingHourId: workingHourId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Darbo laikas išjungtas')));

      await _loadWorkingHours();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko išjungti darbo laiko')),
      );
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
                onPressed: _loadWorkingHours,
                child: const Text('Bandyti dar kartą'),
              ),
            ],
          ),
        ),
      );
    }

    if (_workingHours.isEmpty) {
      return const Center(
        child: Text('Darbo laikų nerasta', style: TextStyle(fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWorkingHours,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _workingHours.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final workingHour = _workingHours[index];

          final weekday = workingHour['weekday'] as int? ?? 0;
          final startTime = _normalizeTime(
            workingHour['start_time']?.toString() ?? '',
          );
          final endTime = _normalizeTime(
            workingHour['end_time']?.toString() ?? '',
          );
          final isActive = workingHour['is_active'] as bool? ?? false;

          return Card(
            child: ListTile(
              leading: Icon(
                isActive ? Icons.check_circle : Icons.cancel,
                color: isActive ? Colors.green : Colors.grey,
              ),
              title: Text(_weekdayLabel(weekday)),
              subtitle: Text('$startTime - $endTime'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openEditPage(workingHour);
                  } else if (value == 'disable') {
                    _disableWorkingHour(workingHour);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Redaguoti')),
                  if (isActive)
                    const PopupMenuItem(
                      value: 'disable',
                      child: Text('Išjungti'),
                    ),
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
    final fullName = widget.user['full_name']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Mano darbo laikai')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePage,
        child: const Icon(Icons.add),
      ),
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
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
