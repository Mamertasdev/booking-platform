import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/api/specialists_api.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../admin/data/specialists_repository.dart';
import 'owner_specialist_form_page.dart';

class OwnerSpecialistsPage extends StatefulWidget {
  const OwnerSpecialistsPage({super.key});

  @override
  State<OwnerSpecialistsPage> createState() => _OwnerSpecialistsPageState();
}

class _OwnerSpecialistsPageState extends State<OwnerSpecialistsPage> {
  late final SpecialistsRepository _specialistsRepository;
  late final AuthRepository _authRepository;

  bool _isLoading = true;
  String? _errorText;

  int? _ownerBusinessId;
  List<Map<String, dynamic>> _specialists = [];

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

    _authRepository = AuthRepository(
      authApi: AuthApi(apiClient),
      tokenStorage: tokenStorage,
    );

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final user = await _authRepository.getCurrentUser();
      final role = user['role']?.toString().toLowerCase() ?? '';
      final businessId = user['business_id'] as int?;

      if (role != 'owner' || businessId == null) {
        throw Exception('Neturite prieigos prie verslo specialistų');
      }

      if (!mounted) return;

      setState(() {
        _ownerBusinessId = businessId;
      });

      await _loadSpecialists();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti verslo specialistų';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSpecialists() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final data = await _specialistsRepository.getSpecialists(
        includeInactive: true,
      );

      if (!mounted) return;

      setState(() {
        _specialists = data.where((specialist) {
          final role = specialist['role']?.toString().toLowerCase() ?? '';
          return role == 'specialist';
        }).toList();
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti specialistų';
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
    final businessId = _ownerBusinessId;

    if (businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko nustatyti verslo')),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OwnerSpecialistFormPage(
          title: 'Naujas specialistas',
          onSubmit:
              ({
                required String username,
                String? password,
                required String fullName,
                required bool isActive,
              }) {
                return _specialistsRepository.createSpecialist(
                  businessId: businessId,
                  username: username,
                  password: password ?? '',
                  fullName: fullName,
                  role: 'specialist',
                );
              },
        ),
      ),
    );

    if (result == true) {
      await _loadSpecialists();
    }
  }

  Future<void> _openEditPage(Map<String, dynamic> specialist) async {
    final businessId = _ownerBusinessId;
    final specialistId = specialist['id'] as int;

    if (businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko nustatyti verslo')),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OwnerSpecialistFormPage(
          title: 'Redaguoti specialistą',
          initialData: specialist,
          onSubmit:
              ({
                required String username,
                String? password,
                required String fullName,
                required bool isActive,
              }) {
                return _specialistsRepository.updateSpecialist(
                  specialistId: specialistId,
                  businessId: businessId,
                  username: username,
                  password: password,
                  fullName: fullName,
                  role: 'specialist',
                  isActive: isActive,
                );
              },
        ),
      ),
    );

    if (result == true) {
      await _loadSpecialists();
    }
  }

  Future<void> _disableSpecialist(Map<String, dynamic> specialist) async {
    final specialistId = specialist['id'] as int;

    try {
      await _specialistsRepository.disableSpecialist(
        specialistId: specialistId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Specialistas išjungtas')));

      await _loadSpecialists();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _activeLabel(bool isActive) {
    return isActive ? 'Aktyvus' : 'Išjungtas';
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
                onPressed: _loadInitialData,
                child: const Text('Bandyti dar kartą'),
              ),
            ],
          ),
        ),
      );
    }

    if (_specialists.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadSpecialists,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'Specialistų nerasta',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSpecialists,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _specialists.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Card(
              child: ListTile(
                title: Text('Verslo specialistai'),
                subtitle: Text(
                  'Čia rodomi tik jūsų verslo specialistai. Verslo savininko ir admin vartotojai šiame sąraše nerodomi.',
                ),
              ),
            );
          }

          final specialist = _specialists[index - 1];

          final fullName = specialist['full_name']?.toString() ?? '-';
          final username = specialist['username']?.toString() ?? '-';
          final isActive = specialist['is_active'] as bool? ?? false;

          return Card(
            child: ListTile(
              leading: Icon(
                isActive ? Icons.check_circle : Icons.cancel,
                color: isActive ? Colors.green : Colors.grey,
              ),
              title: Text(fullName),
              subtitle: Text(
                'Username: $username\nStatusas: ${_activeLabel(isActive)}',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openEditPage(specialist);
                  } else if (value == 'disable') {
                    _disableSpecialist(specialist);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Verslo specialistai')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePage,
        child: const Icon(Icons.add),
      ),
      body: _buildContent(),
    );
  }
}
