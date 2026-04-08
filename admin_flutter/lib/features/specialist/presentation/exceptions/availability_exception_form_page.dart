import 'package:flutter/material.dart';

class AvailabilityExceptionFormPage extends StatefulWidget {
  const AvailabilityExceptionFormPage({
    super.key,
    required this.title,
    required this.onSubmit,
    this.initialData,
  });

  final String title;
  final Map<String, dynamic>? initialData;
  final Future<void> Function({
    required String startDateTimeIso,
    required String endDateTimeIso,
    String? reason,
    required bool isActive,
  })
  onSubmit;

  @override
  State<AvailabilityExceptionFormPage> createState() =>
      _AvailabilityExceptionFormPageState();
}

class _AvailabilityExceptionFormPageState
    extends State<AvailabilityExceptionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  DateTime? _startDateTime;
  DateTime? _endDateTime;
  bool _isActive = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    final initialData = widget.initialData;
    if (initialData != null) {
      final start = initialData['start_datetime']?.toString();
      final end = initialData['end_datetime']?.toString();

      if (start != null && start.isNotEmpty) {
        _startDateTime = DateTime.tryParse(start)?.toLocal();
      }

      if (end != null && end.isNotEmpty) {
        _endDateTime = DateTime.tryParse(end)?.toLocal();
      }

      _reasonController.text = initialData['reason']?.toString() ?? '';
      _isActive = initialData['is_active'] as bool? ?? true;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  Future<void> _pickStartDateTime() async {
    final base = _startDateTime ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _startDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickEndDateTime() async {
    final base = _endDateTime ?? _startDateTime ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _endDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (_startDateTime == null || _endDateTime == null) {
      setState(() {
        _errorText = 'Pasirinkite pradžios ir pabaigos datą su laiku';
      });
      return;
    }

    if (!_endDateTime!.isAfter(_startDateTime!)) {
      setState(() {
        _errorText = 'Pabaiga turi būti vėlesnė už pradžią';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final reason = _reasonController.text.trim();

      await widget.onSubmit(
        startDateTimeIso: _startDateTime!.toIso8601String(),
        endDateTimeIso: _endDateTime!.toIso8601String(),
        reason: reason.isEmpty ? null : reason,
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
                Card(
                  child: ListTile(
                    title: const Text('Pradžia'),
                    subtitle: Text(_formatDateTime(_startDateTime)),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: _isLoading ? null : _pickStartDateTime,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: const Text('Pabaiga'),
                    subtitle: Text(_formatDateTime(_endDateTime)),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: _isLoading ? null : _pickEndDateTime,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Priežastis',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length > 200) {
                      return 'Priežastis per ilga';
                    }
                    return null;
                  },
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
                    title: const Text('Aktyvi išimtis'),
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
                        : const Text('Išsaugoti'),
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
