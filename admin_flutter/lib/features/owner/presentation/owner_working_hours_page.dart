import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/api/specialists_api.dart';
import '../../../core/api/working_hours_api.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../admin/data/specialists_repository.dart';
import '../../specialist/data/working_hours_repository.dart';
import '../../specialist/presentation/working_hours/working_hour_form_page.dart';

class OwnerWorkingHoursPage extends StatefulWidget {
  const OwnerWorkingHoursPage({super.key});

  @override
  State<OwnerWorkingHoursPage> createState() => _OwnerWorkingHoursPageState();
}

class _OwnerWorkingHoursPageState extends State<OwnerWorkingHoursPage> {
  late final WorkingHoursRepository _workingHoursRepository;
  late final SpecialistsRepository _specialistsRepository;
  late final AuthRepository _authRepository;

  bool _isLoadingFilters = true;
  bool _isLoadingItems = false;
  String? _errorText;

  int? _ownerBusinessId;
  int? _selectedSpecialistId;

  List<Map<String, dynamic>> _specialists = [];
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      tokenStorage: tokenStorage,
    );

    _workingHoursRepository = WorkingHoursRepository(
      workingHoursApi: WorkingHoursApi(apiClient),
    );

    _specialistsRepository = SpecialistsRepository(
      specialistsApi: SpecialistsApi(apiClient),
    );

    _authRepository = AuthRepository(
      authApi: AuthApi(apiClient),
      tokenStorage: tokenStorage,
    );

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingFilters = true;
      _errorText = null;
    });

    try {
      final user = await _authRepository.getCurrentUser();
      final role = user['role']?.toString().toLowerCase() ?? '';
      final businessId = user['business_id'] as int?;

      if (role != 'owner' || businessId == null) {
        throw Exception('Neturite prieigos prie verslo darbo laikų');
      }

      final specialists = await _specialistsRepository.getSpecialists(
        includeInactive: false,
      );

      if (!mounted) return;

      final businessSpecialists = specialists.where((specialist) {
        final specialistBusinessId = specialist['business_id'] as int?;
        final specialistRole =
            specialist['role']?.toString().toLowerCase() ?? '';

        return specialistBusinessId == businessId &&
            (specialistRole == 'owner' || specialistRole == 'specialist');
      }).toList();

      setState(() {
        _ownerBusinessId = businessId;
        _specialists = businessSpecialists;
      });

      await _loadItems();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti darbo laikų duomenų';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFilters = false;
        });
      }
    }
  }

  Future<void> _loadItems() async {
    final businessId = _ownerBusinessId;

    if (businessId == null) {
      setState(() {
        _isLoadingItems = false;
      });
      return;
    }

    setState(() {
      _isLoadingItems = true;
      _errorText = null;
    });

    try {
      final allItems = await _workingHoursRepository.getWorkingHours(
        includeInactive: true,
      );

      if (!mounted) return;

      final filtered = allItems.where((item) {
        final itemBusinessId = item['business_id'] as int?;
        final itemSpecialistId = item['specialist_id'] as int?;

        if (itemBusinessId != businessId) {
          return false;
        }

        if (_selectedSpecialistId != null &&
            itemSpecialistId != _selectedSpecialistId) {
          return false;
        }

        return true;
      }).toList();

      setState(() {
        _items = filtered;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti darbo laikų';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
        });
      }
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

  String _normalizeTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;

    final hour = parts[0].padLeft(2, '0');
    final minute = parts[1].padLeft(2, '0');
    return '$hour:$minute';
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

  Future<void> _openCreatePage() async {
    final businessId = _ownerBusinessId;
    final specialistId = _selectedSpecialistId;

    if (businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko nustatyti verslo')),
      );
      return;
    }

    if (specialistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pirmiausia pasirinkite specialistą')),
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
      await _loadItems();
    }
  }

  Future<void> _openEditPage(Map<String, dynamic> item) async {
    final workingHourId = item['id'] as int;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkingHourFormPage(
          title: 'Redaguoti darbo laiką',
          initialData: item,
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
      await _loadItems();
    }
  }

  Future<void> _disableWorkingHour(int id) async {
    try {
      await _workingHoursRepository.disableWorkingHour(workingHourId: id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Darbo laikas išjungtas')));

      await _loadItems();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko išjungti darbo laiko')),
      );
    }
  }

  Widget _buildFilters() {
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
        child: DropdownButtonFormField<int?>(
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
          onChanged: _isLoadingItems
              ? null
              : (value) async {
                  setState(() {
                    _selectedSpecialistId = value;
                  });

                  await _loadItems();
                },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingItems) {
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
                  onPressed: _loadInitialData,
                  child: const Text('Bandyti dar kartą'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('Darbo laikų nerasta', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadItems,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final item = _items[index];

            final weekday = item['weekday'] as int? ?? 0;
            final start = _normalizeTime(item['start_time']?.toString() ?? '');
            final end = _normalizeTime(item['end_time']?.toString() ?? '');
            final isActive = item['is_active'] as bool? ?? false;
            final specialistId = item['specialist_id'] as int?;

            return Card(
              child: ListTile(
                leading: Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  color: isActive ? Colors.green : Colors.grey,
                ),
                title: Text(_weekdayLabel(weekday)),
                subtitle: Text(
                  '${_specialistNameById(specialistId)}\n$start - $end',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEditPage(item);
                    } else if (value == 'disable') {
                      _disableWorkingHour(item['id'] as int);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Redaguoti'),
                    ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verslo darbo laikai')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePage,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [_buildFilters(), _buildContent()]),
    );
  }
}
