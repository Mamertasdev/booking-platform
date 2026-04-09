import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/businesses_api.dart';
import '../../../core/storage/token_storage.dart';
import '../data/businesses_repository.dart';

class SpecialistFormPage extends StatefulWidget {
  const SpecialistFormPage({super.key, required this.onSubmit});

  final Future<void> Function({
    required int businessId,
    required String username,
    required String password,
    required String fullName,
    required String role,
  })
  onSubmit;

  @override
  State<SpecialistFormPage> createState() => _SpecialistFormPageState();
}

class _SpecialistFormPageState extends State<SpecialistFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  late final BusinessesRepository _businessesRepository;

  String _selectedRole = 'specialist';
  int? _selectedBusinessId;
  bool _isLoading = false;
  bool _isLoadingBusinesses = true;
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinesses() async {
    setState(() {
      _isLoadingBusinesses = true;
      _errorText = null;
    });

    try {
      final data = await _businessesRepository.getBusinesses(
        includeInactive: false,
      );

      if (!mounted) return;

      setState(() {
        _businesses = data;
        if (_businesses.isNotEmpty) {
          _selectedBusinessId = _businesses.first['id'] as int;
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti verslų';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBusinesses = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (_selectedBusinessId == null) {
      setState(() {
        _errorText = 'Pasirinkite verslą';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await widget.onSubmit(
        businessId: _selectedBusinessId!,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko sukurti vartotojo';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateUsername(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Įveskite prisijungimo vardą';
    }

    if (text.length < 3) {
      return 'Prisijungimo vardas per trumpas';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Įveskite slaptažodį';
    }

    if (text.length < 4) {
      return 'Slaptažodis per trumpas';
    }

    return null;
  }

  String? _validateFullName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Įveskite pilną vardą';
    }

    if (text.length < 2) {
      return 'Pilnas vardas per trumpas';
    }

    return null;
  }

  Widget _buildBody() {
    if (_isLoadingBusinesses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_businesses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nėra aktyvių verslų. Pirmiausia sukurkite bent vieną verslą.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              initialValue: _selectedBusinessId,
              decoration: const InputDecoration(
                labelText: 'Verslas',
                border: OutlineInputBorder(),
              ),
              items: _businesses.map((business) {
                final businessId = business['id'] as int;
                final name = business['name']?.toString() ?? '-';

                return DropdownMenuItem<int>(
                  value: businessId,
                  child: Text(name),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _selectedBusinessId = value;
                      });
                    },
              validator: (value) {
                if (value == null) {
                  return 'Pasirinkite verslą';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Pilnas vardas',
                border: OutlineInputBorder(),
              ),
              validator: _validateFullName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Prisijungimo vardas',
                border: OutlineInputBorder(),
              ),
              validator: _validateUsername,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Slaptažodis',
                border: OutlineInputBorder(),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rolė',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'specialist',
                  child: Text('Specialistas'),
                ),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedRole = value;
                      });
                    },
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sukurti vartotoją'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Naujas vartotojas')),
      body: SafeArea(child: _buildBody()),
    );
  }
}
