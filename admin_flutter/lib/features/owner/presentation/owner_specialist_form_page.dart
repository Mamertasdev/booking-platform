import 'package:flutter/material.dart';

class OwnerSpecialistFormPage extends StatefulWidget {
  const OwnerSpecialistFormPage({
    super.key,
    required this.title,
    required this.onSubmit,
    this.initialData,
  });

  final String title;
  final Map<String, dynamic>? initialData;

  final Future<void> Function({
    required String username,
    String? password,
    required String fullName,
    required bool isActive,
  })
  onSubmit;

  @override
  State<OwnerSpecialistFormPage> createState() =>
      _OwnerSpecialistFormPageState();
}

class _OwnerSpecialistFormPageState extends State<OwnerSpecialistFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;
  String? _errorText;

  bool get _isEditMode => widget.initialData != null;

  @override
  void initState() {
    super.initState();

    final initialData = widget.initialData;

    if (initialData != null) {
      _usernameController.text = initialData['username']?.toString() ?? '';
      _fullNameController.text = initialData['full_name']?.toString() ?? '';
      _isActive = initialData['is_active'] as bool? ?? true;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final password = _passwordController.text.trim();

      await widget.onSubmit(
        username: _usernameController.text.trim(),
        password: password.isEmpty ? null : password,
        fullName: _fullNameController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Verslo savininkas gali kurti ir redaguoti tik savo verslo specialistus.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 16),
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
                    title: const Text('Aktyvus specialistas'),
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
                        : Text(
                            _isEditMode ? 'Išsaugoti' : 'Sukurti specialistą',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
