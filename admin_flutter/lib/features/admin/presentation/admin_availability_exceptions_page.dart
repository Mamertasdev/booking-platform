import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/availability_exceptions_api.dart';
import '../../../core/api/businesses_api.dart';
import '../../../core/api/specialists_api.dart';
import '../../../core/storage/token_storage.dart';
import '../../specialist/data/availability_exceptions_repository.dart';
import '../../specialist/presentation/exceptions/availability_exception_form_page.dart';
import '../data/businesses_repository.dart';
import '../data/specialists_repository.dart';

class AdminAvailabilityExceptionsPage extends StatefulWidget {
  const AdminAvailabilityExceptionsPage({super.key});

  @override
  State<AdminAvailabilityExceptionsPage> createState() =>
      _AdminAvailabilityExceptionsPageState();
}

class _AdminAvailabilityExceptionsPageState
    extends State<AdminAvailabilityExceptionsPage> {
  late final AvailabilityExceptionsRepository _availabilityExceptionsRepository;
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

    _availabilityExceptionsRepository = AvailabilityExceptionsRepository(
      availabilityExceptionsApi: AvailabilityExceptionsApi(apiClient),
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
      final items = await _availabilityExceptionsRepository
          .getAvailabilityExceptions(
            businessId: _selectedBusinessId,
            specialistId: _selectedSpecialistId,
            includeInactive: true,
          );

      if (!mounted) return;

      setState(() {
        _items = items;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti išimčių';
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
        builder: (_) => AvailabilityExceptionFormPage(
          title: 'Nauja išimtis',
          onSubmit:
              ({
                required String startDateTimeIso,
                required String endDateTimeIso,
                String? reason,
                required bool isActive,
              }) {
                return _availabilityExceptionsRepository
                    .createAvailabilityException(
                      businessId: _selectedBusinessId!,
                      specialistId: _selectedSpecialistId!,
                      startDateTimeIso: startDateTimeIso,
                      endDateTimeIso: endDateTimeIso,
                      reason: reason,
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
    final exceptionId = item['id'] as int;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AvailabilityExceptionFormPage(
          title: 'Redaguoti išimtį',
          initialData: item,
          onSubmit:
              ({
                required String startDateTimeIso,
                required String endDateTimeIso,
                String? reason,
                required bool isActive,
              }) {
                return _availabilityExceptionsRepository
                    .updateAvailabilityException(
                      exceptionId: exceptionId,
                      startDateTimeIso: startDateTimeIso,
                      endDateTimeIso: endDateTimeIso,
                      reason: reason,
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
      await _availabilityExceptionsRepository.disableAvailabilityException(
        exceptionId: id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Išimtis išjungta')));

      await _loadItems();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko išjungti išimties')),
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
          child: Text('Nėra išimčių', style: TextStyle(fontSize: 16)),
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

            final start = _formatDateTime(
              item['start_datetime']?.toString() ?? '',
            );
            final end = _formatDateTime(item['end_datetime']?.toString() ?? '');
            final reason = item['reason']?.toString() ?? '-';
            final isActive = item['is_active'] as bool? ?? false;
            final businessId = item['business_id'] as int?;
            final specialistId = item['specialist_id'] as int?;

            return Card(
              child: ListTile(
                leading: Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  color: isActive ? Colors.green : Colors.grey,
                ),
                title: Text(reason),
                subtitle: Text(
                  '${_businessNameById(businessId)}\n'
                  '${_specialistNameById(specialistId)}\n'
                  '$start\n$end',
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
      appBar: AppBar(title: const Text('Išimtys')),
      floatingActionButton: FloatingActionButton(
        onPressed: canCreate ? _openCreatePage : null,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [_buildFilters(), _buildContent()]),
    );
  }
}
