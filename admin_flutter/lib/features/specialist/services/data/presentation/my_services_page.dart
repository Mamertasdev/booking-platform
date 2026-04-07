import 'package:flutter/material.dart';

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/services_api.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../data/services_repository.dart';
import 'service_form_page.dart';

class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});

  @override
  State<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends State<MyServicesPage> {
  late final ServicesRepository _servicesRepository;

  bool _isLoading = true;
  String? _errorText;
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: 'http://100.80.21.21:8000',
      tokenStorage: tokenStorage,
    );
    final servicesApi = ServicesApi(apiClient);

    _servicesRepository = ServicesRepository(servicesApi: servicesApi);

    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final data = await _servicesRepository.getServices(includeInactive: true);

      if (!mounted) return;

      setState(() {
        _services = data;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti paslaugų';
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
        builder: (_) => ServiceFormPage(
          title: 'Nauja paslauga',
          onSubmit:
              ({
                required String name,
                required int durationMinutes,
                required int price,
                required bool isActive,
              }) {
                return _servicesRepository.createService(
                  name: name,
                  durationMinutes: durationMinutes,
                  price: price,
                );
              },
        ),
      ),
    );

    if (result == true) {
      await _loadServices();
    }
  }

  Future<void> _openEditPage(Map<String, dynamic> service) async {
    final serviceId = service['id'] as int;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ServiceFormPage(
          title: 'Redaguoti paslaugą',
          initialData: service,
          onSubmit:
              ({
                required String name,
                required int durationMinutes,
                required int price,
                required bool isActive,
              }) {
                return _servicesRepository.updateService(
                  serviceId: serviceId,
                  name: name,
                  durationMinutes: durationMinutes,
                  price: price,
                  isActive: isActive,
                );
              },
        ),
      ),
    );

    if (result == true) {
      await _loadServices();
    }
  }

  Future<void> _disableService(Map<String, dynamic> service) async {
    final serviceId = service['id'] as int;

    try {
      await _servicesRepository.disableService(serviceId: serviceId);

      if (!mounted) return;
      await _loadServices();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko išjungti paslaugos')),
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
                onPressed: _loadServices,
                child: const Text('Bandyti dar kartą'),
              ),
            ],
          ),
        ),
      );
    }

    if (_services.isEmpty) {
      return const Center(
        child: Text('Paslaugų nerasta', style: TextStyle(fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadServices,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final service = _services[index];

          final name = service['name']?.toString() ?? '-';
          final duration = service['duration_minutes']?.toString() ?? '-';
          final price = service['price']?.toString() ?? '-';
          final isActive = service['is_active'] as bool? ?? false;

          return Card(
            child: ListTile(
              title: Text(name),
              subtitle: Text('$duration min • €$price'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openEditPage(service);
                  } else if (value == 'disable') {
                    _disableService(service);
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
              leading: Icon(
                isActive ? Icons.check_circle : Icons.cancel,
                color: isActive ? Colors.green : Colors.grey,
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
      appBar: AppBar(title: const Text('Mano paslaugos')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePage,
        child: const Icon(Icons.add),
      ),
      body: _buildContent(),
    );
  }
}
