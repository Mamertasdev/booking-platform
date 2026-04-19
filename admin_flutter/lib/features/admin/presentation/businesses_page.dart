import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/api/businesses_api.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/storage/token_storage.dart';
import '../data/businesses_repository.dart';
import 'business_form_page.dart';

class BusinessesPage extends StatefulWidget {
  const BusinessesPage({super.key});

  @override
  State<BusinessesPage> createState() => _BusinessesPageState();
}

class _BusinessesPageState extends State<BusinessesPage> {
  late final BusinessesRepository _businessesRepository;
  late final AuthRepository _authRepository;

  bool _isLoading = true;
  bool _hasAccess = false;
  String? _errorText;
  List<Map<String, dynamic>> _businesses = [];

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: 'http://100.80.21.21:8000',
      tokenStorage: tokenStorage,
    );
    final businessesApi = BusinessesApi(apiClient);
    final authApi = AuthApi(apiClient);

    _businessesRepository = BusinessesRepository(businessesApi: businessesApi);
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

      if (role != 'admin') {
        if (!mounted) return;
        setState(() {
          _hasAccess = false;
          _isLoading = false;
        });
        return;
      }

      _hasAccess = true;
      await _loadBusinesses();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko patikrinti vartotojo teisių';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBusinesses() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final data = await _businessesRepository.getBusinesses(
        includeInactive: true,
      );

      if (!mounted) return;

      setState(() {
        _businesses = data;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti verslų';
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
        builder: (_) => BusinessFormPage(
          title: 'Naujas verslas',
          onSubmit: ({required String name, required bool isActive}) {
            return _businessesRepository.createBusiness(name: name);
          },
        ),
      ),
    );

    if (result == true) {
      await _loadBusinesses();
    }
  }

  Future<void> _openEditPage(Map<String, dynamic> business) async {
    final businessId = business['id'] as int;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BusinessFormPage(
          title: 'Redaguoti verslą',
          initialData: business,
          onSubmit: ({required String name, required bool isActive}) {
            return _businessesRepository.updateBusiness(
              businessId: businessId,
              name: name,
              isActive: isActive,
            );
          },
        ),
      ),
    );

    if (result == true) {
      await _loadBusinesses();
    }
  }

  Future<void> _disableBusiness(Map<String, dynamic> business) async {
    final businessId = business['id'] as int;

    try {
      await _businessesRepository.disableBusiness(businessId: businessId);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verslas išjungtas')));

      await _loadBusinesses();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nepavyko išjungti verslo')));
    }
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
            'Neturite prieigos prie verslų valdymo.',
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

    if (_businesses.isEmpty) {
      return const Center(
        child: Text('Verslų nerasta', style: TextStyle(fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBusinesses,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _businesses.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final business = _businesses[index];

          final name = business['name']?.toString() ?? '-';
          final businessId = business['id']?.toString() ?? '-';
          final isActive = business['is_active'] as bool? ?? false;

          return Card(
            child: ListTile(
              leading: Icon(
                isActive ? Icons.check_circle : Icons.cancel,
                color: isActive ? Colors.green : Colors.grey,
              ),
              title: Text(name),
              subtitle: Text('ID: $businessId'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openEditPage(business);
                  } else if (value == 'disable') {
                    _disableBusiness(business);
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
      appBar: AppBar(title: const Text('Verslai')),
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
