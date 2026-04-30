import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/api/businesses_api.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import '../data/businesses_repository.dart';

class SpecialistFormPage extends StatefulWidget {
  const SpecialistFormPage({
    super.key,
    required this.onSubmit,
    this.initialData,
    this.title = 'Vartotojas',
  });

  final Future<void> Function({
    required int businessId,
    required String username,
    String? password,
    required String fullName,
    required String role,
    required bool isActive,
  })
  onSubmit;

  final Map<String, dynamic>? initialData;
  final String title;

  @override
  State<SpecialistFormPage> createState() => _SpecialistFormPageState();
}

class _SpecialistFormPageState extends State<SpecialistFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  late final BusinessesRepository _businessesRepository;
  late final AuthRepository _authRepository;

  String _selectedRole = 'specialist';
  int? _selectedBusinessId;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isLoadingBusinesses = true;
  bool _hasAccess = false;
  String? _errorText;
  List<Map<String, dynamic>> _businesses = [];

  bool get _isEditMode => widget.initialData != null;

  static const List<String> _allowedRoles = ['specialist', 'owner', 'admin'];

  @override
  void initState() {
    super.initState();

    final initialData = widget.initialData;
    if (initialData != null) {
      _usernameController.text = initialData['username']?.toString() ?? '';
      _fullNameController.text = initialData['full_name']?.toString() ?? '';
      _selectedRole = initialData['role']?.toString() ?? 'specialist';
      _selectedBusinessId = initialData['business_id'] as int?;
      _isActive = initialData['is_active'] as bool? ?? true;
    }

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    setState(() {
      _isLoadingBusinesses = true;
      _errorText = null;
    });

    try {
      final user = await _authRepository.getCurrentUser();
      final role = user['role']?.toString().toLowerCase() ?? '';

      if (role != 'admin') {
        if (!mounted) return;

        setState(() {
          _hasAccess = false;
          _errorText = 'Neturite prieigos prie platformos vartotojų formos';
          _isLoadingBusinesses = false;
        });

        return;
      }

      if (!mounted) return;

      setState(() {
        _hasAccess = true;
      });

      await _loadBusinesses();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti vartotojo duomenų';
        _isLoadingBusinesses = false;
      });
    }
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

      int? selectedBusinessId = _selectedBusinessId;

      if (selectedBusinessId == null && data.isNotEmpty) {
        selectedBusinessId = data.first['id'] as int;
      }

      setState(() {
        _businesses = data;
        _selectedBusinessId = selectedBusinessId;
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
      final password = _passwordController.text.trim();

      await widget.onSubmit(
        businessId: _selectedBusinessId!,
        username: _usernameController.text.trim(),
        password: password.isEmpty ? null : password,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
        isActive: _isActive,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorText = e.toString();
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

    if (text.length > 50) {
      return 'Prisijungimo vardas per ilgas';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final text = value?.trim() ?? '';

    if (!_isEditMode && text.isEmpty) {
      return 'Įveskite slaptažodį';
    }

    if (text.isNotEmpty && text.length < 4) {
      return 'Slaptažodis per trumpas';
    }

    if (text.length > 100) {
      return 'Slaptažodis per ilgas';
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

    if (text.length > 100) {
      return 'Pilnas vardas per ilgas';
    }

    return null;
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'owner':
        return 'Verslo savininkas';
      default:
        return 'Specialistas';
    }
  }

  Widget _buildBody() {
    if (_isLoadingBusinesses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasAccess) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorText ?? 'Neturite prieigos prie platformos vartotojų formos.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    if (_errorText != null && _businesses.isEmpty) {
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
                onPressed: _initPage,
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
              decoration: InputDecoration(
                labelText: _isEditMode
                    ? 'Naujas slaptažodis (nebūtina)'
                    : 'Slaptažodis',
                border: const OutlineInputBorder(),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _allowedRoles.contains(_selectedRole)
                  ? _selectedRole
                  : _allowedRoles.first,
              decoration: const InputDecoration(
                labelText: 'Rolė',
                border: OutlineInputBorder(),
              ),
              items: _allowedRoles.map((role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(_roleLabel(role)),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedRole = value;
                      });
                    },
            ),
            if (_isEditMode) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isActive,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                title: const Text('Aktyvus vartotojas'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
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
                    : Text(_isEditMode ? 'Išsaugoti' : 'Sukurti vartotoją'),
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
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(child: _buildBody()),
    );
  }
}
