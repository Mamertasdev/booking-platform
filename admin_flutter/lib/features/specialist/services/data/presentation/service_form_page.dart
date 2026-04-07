import 'package:flutter/material.dart';

class ServiceFormPage extends StatefulWidget {
  const ServiceFormPage({
    super.key,
    this.initialData,
    required this.onSubmit,
    this.title = 'Paslauga',
  });

  final Map<String, dynamic>? initialData;
  final Future<void> Function({
    required String name,
    required int durationMinutes,
    required int price,
    required bool isActive,
  })
  onSubmit;
  final String title;

  @override
  State<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;

  bool _isActive = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialData;

    _nameController = TextEditingController(
      text: initial?['name']?.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: initial?['duration_minutes']?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: initial?['price']?.toString() ?? '',
    );
    _isActive = initial?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final duration = int.tryParse(_durationController.text.trim());
    final price = int.tryParse(_priceController.text.trim());

    if (name.isEmpty || duration == null || price == null) {
      setState(() {
        _errorText = 'Užpildykite visus laukus teisingai';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await widget.onSubmit(
        name: name,
        durationMinutes: duration,
        price: price,
        isActive: _isActive,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      setState(() {
        _errorText = 'Nepavyko išsaugoti paslaugos';
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
    final isEditing = widget.initialData != null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Pavadinimas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Trukmė (min.)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kaina',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isActive,
                onChanged: isEditing
                    ? (value) {
                        setState(() {
                          _isActive = value;
                        });
                      }
                    : null,
                title: const Text('Aktyvi paslauga'),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
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
                      : Text(isEditing ? 'Išsaugoti' : 'Sukurti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
