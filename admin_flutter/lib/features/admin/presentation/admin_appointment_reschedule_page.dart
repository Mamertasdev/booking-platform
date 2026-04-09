import 'package:flutter/material.dart';

class AdminAppointmentReschedulePage extends StatefulWidget {
  const AdminAppointmentReschedulePage({
    super.key,
    required this.initialAppointmentStart,
    required this.onSubmit,
  });

  final String initialAppointmentStart;
  final Future<void> Function({required String appointmentStartIso}) onSubmit;

  @override
  State<AdminAppointmentReschedulePage> createState() =>
      _AdminAppointmentReschedulePageState();
}

class _AdminAppointmentReschedulePageState
    extends State<AdminAppointmentReschedulePage> {
  DateTime? _selectedDateTime;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final parsed = DateTime.tryParse(widget.initialAppointmentStart);
    _selectedDateTime = parsed?.toLocal();
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

  Future<void> _pickDateTime() async {
    final base = _selectedDateTime ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_selectedDateTime == null) {
      setState(() {
        _errorText = 'Pasirinkite naują datą ir laiką';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await widget.onSubmit(
        appointmentStartIso: _selectedDateTime!.toIso8601String(),
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
      appBar: AppBar(title: const Text('Perkelti vizitą')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: ListTile(
                  title: const Text('Naujas laikas'),
                  subtitle: Text(_formatDateTime(_selectedDateTime)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: _isLoading ? null : _pickDateTime,
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
                      : const Text('Išsaugoti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
