import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/businesses_api.dart';
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

  bool _isLoading = true;
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

    _businessesRepository = BusinessesRepository(businessesApi: businessesApi);

    _loadBusinesses();
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
          onSubmit: ({required String name}) {
            return _businessesRepository.createBusiness(name: name);
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
                onPressed: _loadBusinesses,
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
                  if (value == 'disable') {
                    _disableBusiness(business);
                  }
                },
                itemBuilder: (_) => [
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePage,
        child: const Icon(Icons.add),
      ),
      body: _buildContent(),
    );
  }
}
