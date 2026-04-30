import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/api/availability_exceptions_api.dart';
import '../../../core/api/specialists_api.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../admin/data/specialists_repository.dart';
import '../../specialist/data/availability_exceptions_repository.dart';
import '../../specialist/presentation/exceptions/availability_exception_form_page.dart';

class OwnerAvailabilityExceptionsPage extends StatefulWidget {
  const OwnerAvailabilityExceptionsPage({super.key});

  @override
  State<OwnerAvailabilityExceptionsPage> createState() =>
      _OwnerAvailabilityExceptionsPageState();
}

class _OwnerAvailabilityExceptionsPageState
    extends State<OwnerAvailabilityExceptionsPage> {
  late final AvailabilityExceptionsRepository _availabilityExceptionsRepository;
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

    _availabilityExceptionsRepository = AvailabilityExceptionsRepository(
      availabilityExceptionsApi: AvailabilityExceptionsApi(apiClient),
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
        throw Exception('Neturite prieigos prie verslo išimčių');
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
        _errorText = 'Nepavyko užkrauti išimčių duomenų';
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
      final items = await _availabilityExceptionsRepository
          .getAvailabilityExceptions(
            businessId: businessId,
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
                      businessId: businessId,
                      specialistId: specialistId,
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

  Future<void> _disableAvailabilityException(int id) async {
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
          child: Text('Išimčių nerasta', style: TextStyle(fontSize: 16)),
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

            final start = _formatDateTime(
              item['start_datetime']?.toString() ?? '',
            );
            final end = _formatDateTime(item['end_datetime']?.toString() ?? '');
            final reason = item['reason']?.toString() ?? '-';
            final isActive = item['is_active'] as bool? ?? false;
            final specialistId = item['specialist_id'] as int?;

            return Card(
              child: ListTile(
                leading: Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  color: isActive ? Colors.green : Colors.grey,
                ),
                title: Text(reason),
                subtitle: Text(
                  '${_specialistNameById(specialistId)}\n$start\n$end',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEditPage(item);
                    } else if (value == 'disable') {
                      _disableAvailabilityException(item['id'] as int);
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
      appBar: AppBar(title: const Text('Verslo išimtys')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePage,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [_buildFilters(), _buildContent()]),
    );
  }
}
