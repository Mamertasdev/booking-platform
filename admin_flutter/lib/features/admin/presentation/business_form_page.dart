import 'package:flutter/material.dart';

class BusinessFormPage extends StatefulWidget {
  const BusinessFormPage({
    super.key,
    required this.onSubmit,
    this.initialData,
    this.title = 'Verslas',
  });

  final Future<void> Function({required String name, required bool isActive})
  onSubmit;

  final Map<String, dynamic>? initialData;
  final String title;

  @override
  State<BusinessFormPage> createState() => _BusinessFormPageState();
}

class _BusinessFormPageState extends State<BusinessFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  bool _isActive = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    final initialData = widget.initialData;
    _nameController = TextEditingController(
      text: initialData?['name']?.toString() ?? '',
    );
    _isActive = initialData?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Įveskite verslo pavadinimą';
    }

    if (text.length < 2) {
      return 'Verslo pavadinimas per trumpas';
    }

    if (text.length > 100) {
      return 'Verslo pavadinimas per ilgas';
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
      await widget.onSubmit(
        name: _nameController.text.trim(),
        isActive: _isActive,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko išsaugoti verslo';
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
    final isEditMode = widget.initialData != null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Verslo pavadinimas',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                ),
                if (isEditMode) ...[
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
                    title: const Text('Aktyvus verslas'),
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
                        : Text(isEditMode ? 'Išsaugoti' : 'Sukurti'),
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
