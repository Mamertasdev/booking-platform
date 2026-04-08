import 'package:flutter/material.dart';

class AvailabilityAppointmentFormPage extends StatefulWidget {
  const AvailabilityAppointmentFormPage({
    super.key,
    required this.slotLabel,
    required this.onSubmit,
  });

  final String slotLabel;
  final Future<void> Function({
    required String clientFullName,
    required String clientEmail,
    String? clientPhone,
    String? notes,
  })
  onSubmit;

  @override
  State<AvailabilityAppointmentFormPage> createState() =>
      _AvailabilityAppointmentFormPageState();
}

class _AvailabilityAppointmentFormPageState
    extends State<AvailabilityAppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _clientFullNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _clientFullNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Įveskite kliento vardą';
    }

    if (text.length < 2) {
      return 'Kliento vardas per trumpas';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Įveskite el. paštą';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) {
      return 'Neteisingas el. pašto formatas';
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
      final phone = _clientPhoneController.text.trim();
      final notes = _notesController.text.trim();

      await widget.onSubmit(
        clientFullName: _clientFullNameController.text.trim(),
        clientEmail: _clientEmailController.text.trim(),
        clientPhone: phone.isEmpty ? null : phone,
        notes: notes.isEmpty ? null : notes,
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
      appBar: AppBar(title: const Text('Nauja rezervacija')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Pasirinktas laikas'),
                    subtitle: Text(widget.slotLabel),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _clientFullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Kliento vardas ir pavardė',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateFullName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _clientEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'El. paštas',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _clientPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefonas',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Pastabos',
                    border: OutlineInputBorder(),
                  ),
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
                        : const Text('Sukurti rezervaciją'),
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
