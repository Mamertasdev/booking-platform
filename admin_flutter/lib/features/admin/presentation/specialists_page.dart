import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/api/specialists_api.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/storage/token_storage.dart';
import '../data/specialists_repository.dart';
import 'specialist_form_page.dart';

class SpecialistsPage extends StatefulWidget {
  const SpecialistsPage({super.key});

  @override
  State<SpecialistsPage> createState() => _SpecialistsPageState();
}

class _SpecialistsPageState extends State<SpecialistsPage> {
  late final SpecialistsRepository _specialistsRepository;
  late final AuthRepository _authRepository;

  bool _isLoading = true;
  bool _hasAccess = false;
  String? _errorText;
  String _currentRole = '';
  List<Map<String, dynamic>> _specialists = [];

  bool get _isAdmin => _currentRole == 'admin';
  bool get _isOwner => _currentRole == 'owner';

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: 'http://100.80.21.21:8000',
      tokenStorage: tokenStorage,
    );
    final specialistsApi = SpecialistsApi(apiClient);
    final authApi = AuthApi(apiClient);

    _specialistsRepository = SpecialistsRepository(
      specialistsApi: specialistsApi,
    );
    _authRepository = AuthRepository(
      authApi: authApi,
      tokenStorage: tokenStorage,
    );

    _initPage();
  }

  Future<void> _initPage() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final user = await _authRepository.getCurrentUser();
      final role = (user['role']?.toString().toLowerCase() ?? '');

      if (role != 'admin' && role != 'owner') {
        if (!mounted) return;
        setState(() {
          _currentRole = role;
          _hasAccess = false;
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;

      setState(() {
        _currentRole = role;
        _hasAccess = true;
      });

      await _loadSpecialists();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko patikrinti vartotojo teisių';
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
        _specialists = data;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti vartotojų';
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
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SpecialistFormPage(
          title: _isOwner ? 'Naujas specialistas' : 'Naujas vartotojas',
          onSubmit:
              ({
                required int businessId,
                required String username,
                String? password,
                required String fullName,
                required String role,
                required bool isActive,
              }) {
                return _specialistsRepository.createSpecialist(
                  businessId: businessId,
                  username: username,
                  password: password ?? '',
                  fullName: fullName,
                  role: role,
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
    final specialistId = specialist['id'] as int;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SpecialistFormPage(
          title: 'Redaguoti vartotoją',
          initialData: specialist,
          onSubmit:
              ({
                required int businessId,
                required String username,
                String? password,
                required String fullName,
                required String role,
                required bool isActive,
              }) {
                return _specialistsRepository.updateSpecialist(
                  specialistId: specialistId,
                  businessId: businessId,
                  username: username,
                  password: password,
                  fullName: fullName,
                  role: role,
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
      ).showSnackBar(const SnackBar(content: Text('Vartotojas išjungtas')));

      await _loadSpecialists();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _pageTitle() {
    if (_isOwner) {
      return 'Mano verslo vartotojai';
    }
    return 'Vartotojai';
  }

  String _pageDescription() {
    if (_isOwner) {
      return 'Matote tik savo verslo savininką ir specialistus';
    }
    return 'Matote visus sistemos vartotojus';
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasAccess) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Neturite prieigos prie vartotojų valdymo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
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
                onPressed: _initPage,
                child: const Text('Bandyti dar kartą'),
              ),
            ],
          ),
        ),
      );
    }

    if (_specialists.isEmpty) {
      return const Center(
        child: Text('Vartotojų nerasta', style: TextStyle(fontSize: 16)),
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
            return Card(
              child: ListTile(
                title: Text(_pageTitle()),
                subtitle: Text(_pageDescription()),
              ),
            );
          }

          final specialist = _specialists[index - 1];

          final fullName = specialist['full_name']?.toString() ?? '-';
          final username = specialist['username']?.toString() ?? '-';
          final role = specialist['role']?.toString() ?? '-';
          final businessId = specialist['business_id']?.toString() ?? '-';
          final isActive = specialist['is_active'] as bool? ?? false;

          return Card(
            child: ListTile(
              leading: Icon(
                isActive ? Icons.check_circle : Icons.cancel,
                color: isActive ? Colors.green : Colors.grey,
              ),
              title: Text(fullName),
              subtitle: Text(
                _isOwner
                    ? 'Username: $username\nRolė: $role'
                    : 'Username: $username\nRolė: $role\nBusiness ID: $businessId',
              ),
              isThreeLine: !_isOwner,
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
      appBar: AppBar(title: Text(_pageTitle())),
      floatingActionButton: _hasAccess
          ? FloatingActionButton(
              onPressed: _openCreatePage,
              child: const Icon(Icons.add),
            )
          : null,
      body: _buildContent(),
    );
  }
}
