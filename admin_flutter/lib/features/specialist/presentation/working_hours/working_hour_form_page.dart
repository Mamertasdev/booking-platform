import 'package:flutter/material.dart';

class WorkingHourFormPage extends StatefulWidget {
  const WorkingHourFormPage({
    super.key,
    required this.title,
    required this.onSubmit,
    this.initialData,
  });

  final String title;
  final Map<String, dynamic>? initialData;
  final Future<void> Function({
    required int weekday,
    required String startTime,
    required String endTime,
    required bool isActive,
  })
  onSubmit;

  @override
  State<WorkingHourFormPage> createState() => _WorkingHourFormPageState();
}

class _WorkingHourFormPageState extends State<WorkingHourFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  int _selectedWeekday = 0;
  bool _isActive = true;
  bool _isLoading = false;
  String? _errorText;

  static const _weekdayItems = <DropdownMenuItem<int>>[
    DropdownMenuItem(value: 0, child: Text('Pirmadienis')),
    DropdownMenuItem(value: 1, child: Text('Antradienis')),
    DropdownMenuItem(value: 2, child: Text('Trečiadienis')),
    DropdownMenuItem(value: 3, child: Text('Ketvirtadienis')),
    DropdownMenuItem(value: 4, child: Text('Penktadienis')),
    DropdownMenuItem(value: 5, child: Text('Šeštadienis')),
    DropdownMenuItem(value: 6, child: Text('Sekmadienis')),
  ];

  @override
  void initState() {
    super.initState();

    final initialData = widget.initialData;
    if (initialData != null) {
      _selectedWeekday = initialData['weekday'] as int? ?? 0;
      _startTimeController.text = _normalizeTime(
        initialData['start_time']?.toString() ?? '',
      );
      _endTimeController.text = _normalizeTime(
        initialData['end_time']?.toString() ?? '',
      );
      _isActive = initialData['is_active'] as bool? ?? true;
    }
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  String _normalizeTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;

    final hour = parts[0].padLeft(2, '0');
    final minute = parts[1].padLeft(2, '0');
    return '$hour:$minute';
  }

  String? _validateTime(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Įveskite laiką';
    }

    final regex = RegExp(r'^\d{2}:\d{2}$');
    if (!regex.hasMatch(text)) {
      return 'Laiko formatas turi būti HH:MM';
    }

    final parts = text.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return 'Neteisingas laiko formatas';
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return 'Neteisingas laikas';
    }

    return null;
  }

  int _minutesFromTime(String value) {
    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour * 60 + minute;
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final currentText = controller.text.trim();
    TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0);

    final validationError = _validateTime(currentText);
    if (currentText.isNotEmpty && validationError == null) {
      final parts = currentText.split(':');
      initialTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) return;

    final hour = picked.hour.toString().padLeft(2, '0');
    final minute = picked.minute.toString().padLeft(2, '0');

    controller.text = '$hour:$minute';
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();

    if (_minutesFromTime(endTime) <= _minutesFromTime(startTime)) {
      setState(() {
        _errorText = 'Pabaigos laikas turi būti vėlesnis už pradžios laiką';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await widget.onSubmit(
        weekday: _selectedWeekday,
        startTime: startTime,
        endTime: endTime,
        isActive: _isActive,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko išsaugoti darbo laiko';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: _isLoading ? null : () => _pickTime(controller),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.access_time),
      ),
      validator: _validateTime,
    );
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
                DropdownButtonFormField<int>(
                  value: _selectedWeekday,
                  decoration: const InputDecoration(
                    labelText: 'Savaitės diena',
                    border: OutlineInputBorder(),
                  ),
                  items: _weekdayItems,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedWeekday = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                _buildTimeField(
                  controller: _startTimeController,
                  label: 'Pradžios laikas',
                ),
                const SizedBox(height: 12),
                _buildTimeField(
                  controller: _endTimeController,
                  label: 'Pabaigos laikas',
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
                    title: const Text('Aktyvus'),
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
