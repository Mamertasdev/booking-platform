import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/businesses_api.dart';
import '../../../core/api/specialists_api.dart';
import '../../../core/api/working_hours_api.dart';
import '../../../core/storage/token_storage.dart';
import '../../specialist/data/working_hours_repository.dart';
import '../../specialist/presentation/working_hours/working_hour_form_page.dart';
import '../data/businesses_repository.dart';
import '../data/specialists_repository.dart';

class AdminWorkingHoursPage extends StatefulWidget {
  const AdminWorkingHoursPage({super.key});

  @override
  State<AdminWorkingHoursPage> createState() => _AdminWorkingHoursPageState();
}

class _AdminWorkingHoursPageState extends State<AdminWorkingHoursPage> {
  late final WorkingHoursRepository _workingHoursRepository;
  late final BusinessesRepository _businessesRepository;
  late final SpecialistsRepository _specialistsRepository;

  bool _isLoadingFilters = true;
  bool _isLoadingItems = false;
  String? _errorText;

  List<Map<String, dynamic>> _businesses = [];
  List<Map<String, dynamic>> _specialists = [];
  List<Map<String, dynamic>> _items = [];

  int? _selectedBusinessId;
  int? _selectedSpecialistId;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient(
      baseUrl: 'http://100.80.21.21:8000',
      tokenStorage: TokenStorage(),
    );

    _workingHoursRepository = WorkingHoursRepository(
      workingHoursApi: WorkingHoursApi(apiClient),
    );
    _businessesRepository = BusinessesRepository(
      businessesApi: BusinessesApi(apiClient),
    );
    _specialistsRepository = SpecialistsRepository(
      specialistsApi: SpecialistsApi(apiClient),
    );

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingFilters = true;
      _errorText = null;
    });

    try {
      final businesses = await _businessesRepository.getBusinesses(
        includeInactive: false,
      );
      final specialists = await _specialistsRepository.getSpecialists(
        includeInactive: false,
      );

      if (!mounted) return;

      setState(() {
        _businesses = businesses;
        _specialists = specialists;
      });

      await _loadItems();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti filtrų duomenų';
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
        final businessId = item['business_id'] as int?;
        final specialistId = item['specialist_id'] as int?;

        if (_selectedBusinessId != null && businessId != _selectedBusinessId) {
          return false;
        }

        if (_selectedSpecialistId != null &&
            specialistId != _selectedSpecialistId) {
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

  List<Map<String, dynamic>> get _filteredSpecialists {
    if (_selectedBusinessId == null) {
      return _specialists;
    }

    return _specialists.where((specialist) {
      return specialist['business_id'] == _selectedBusinessId;
    }).toList();
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

  String _businessNameById(int? businessId) {
    if (businessId == null) return '-';

    for (final business in _businesses) {
      if (business['id'] == businessId) {
        return business['name']?.toString() ?? '-';
      }
    }

    return 'ID: $businessId';
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
    if (_selectedBusinessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pirmiausia pasirinkite verslą')),
      );
      return;
    }

    if (_selectedSpecialistId == null) {
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
                  businessId: _selectedBusinessId!,
                  specialistId: _selectedSpecialistId!,
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

  Future<void> _disable(int id) async {
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
        child: Column(
          children: [
            DropdownButtonFormField<int?>(
              initialValue: _selectedBusinessId,
              decoration: const InputDecoration(
                labelText: 'Verslas',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Visi verslai'),
                ),
                ..._businesses.map((business) {
                  return DropdownMenuItem<int?>(
                    value: business['id'] as int,
                    child: Text(business['name']?.toString() ?? '-'),
                  );
                }),
              ],
              onChanged: _isLoadingItems
                  ? null
                  : (value) async {
                      setState(() {
                        _selectedBusinessId = value;

                        final specialistStillValid = _filteredSpecialists.any(
                          (specialist) =>
                              specialist['id'] == _selectedSpecialistId,
                        );

                        if (!specialistStillValid) {
                          _selectedSpecialistId = null;
                        }
                      });

                      await _loadItems();
                    },
            ),
            const SizedBox(height: 12),
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
                ..._filteredSpecialists.map((specialist) {
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
          ],
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
            child: Text(
              _errorText!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('Nėra darbo laikų', style: TextStyle(fontSize: 16)),
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
          itemBuilder: (_, i) {
            final item = _items[i];

            final weekday = item['weekday'] as int? ?? 0;
            final start = _normalizeTime(item['start_time']?.toString() ?? '');
            final end = _normalizeTime(item['end_time']?.toString() ?? '');
            final isActive = item['is_active'] as bool? ?? false;
            final businessId = item['business_id'] as int?;
            final specialistId = item['specialist_id'] as int?;

            return Card(
              child: ListTile(
                leading: Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  color: isActive ? Colors.green : Colors.grey,
                ),
                title: Text(_weekdayLabel(weekday)),
                subtitle: Text(
                  '${_businessNameById(businessId)}\n'
                  '${_specialistNameById(specialistId)}\n'
                  '$start - $end',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') {
                      _openEditPage(item);
                    } else if (v == 'disable') {
                      _disable(item['id'] as int);
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
    final canCreate =
        _selectedBusinessId != null && _selectedSpecialistId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Darbo laikai')),
      floatingActionButton: FloatingActionButton(
        onPressed: canCreate ? _openCreatePage : null,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [_buildFilters(), _buildContent()]),
    );
  }
}
