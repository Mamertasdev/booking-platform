import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/availability_exceptions_api.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/availability_exceptions_repository.dart';
import 'availability_exception_form_page.dart';

class MyAvailabilityExceptionsPage extends StatefulWidget {
  const MyAvailabilityExceptionsPage({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<MyAvailabilityExceptionsPage> createState() =>
      _MyAvailabilityExceptionsPageState();
}

class _MyAvailabilityExceptionsPageState
    extends State<MyAvailabilityExceptionsPage> {
  late final AvailabilityExceptionsRepository _repository;

  bool _isLoading = true;
  String? _errorText;
  List<Map<String, dynamic>> _exceptions = [];

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: 'http://100.80.21.21:8000',
      tokenStorage: tokenStorage,
    );
    final api = AvailabilityExceptionsApi(apiClient);

    _repository = AvailabilityExceptionsRepository(
      availabilityExceptionsApi: api,
    );

    _loadExceptions();
  }

  String _formatDateTime(String value) {
    try {
      final dateTime = DateTime.parse(value).toLocal();

      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year.toString();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return '$day.$month.$year $hour:$minute';
    } catch (_) {
      return value;
    }
  }

  Future<void> _loadExceptions() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final data = await _repository.getAvailabilityExceptions(
        includeInactive: true,
      );

      if (!mounted) return;

      setState(() {
        _exceptions = data;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Nepavyko užkrauti išimčių';
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
    final businessId = widget.user['business_id'] as int?;
    final specialistId = widget.user['id'] as int?;

    if (businessId == null || specialistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko nustatyti vartotojo duomenų')),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AvailabilityExceptionFormPage(
          title: 'Nauja išimtis',
          onSubmit:
              ({
                required String startDateTimeIso,
                required String endDateTimeIso,
                String? reason,
                required bool isActive,
              }) {
                return _repository.createAvailabilityException(
                  businessId: businessId,
                  specialistId: specialistId,
                  startDateTimeIso: startDateTimeIso,
                  endDateTimeIso: endDateTimeIso,
                  reason: reason,
                );
              },
        ),
      ),
    );

    if (result == true) {
      await _loadExceptions();
    }
  }

  Future<void> _openEditPage(Map<String, dynamic> exception) async {
    final exceptionId = exception['id'] as int;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AvailabilityExceptionFormPage(
          title: 'Redaguoti išimtį',
          initialData: exception,
          onSubmit:
              ({
                required String startDateTimeIso,
                required String endDateTimeIso,
                String? reason,
                required bool isActive,
              }) {
                return _repository.updateAvailabilityException(
                  exceptionId: exceptionId,
                  startDateTimeIso: startDateTimeIso,
                  endDateTimeIso: endDateTimeIso,
                  reason: reason,
                  isActive: isActive,
                );
              },
        ),
      ),
    );

    if (result == true) {
      await _loadExceptions();
    }
  }

  Future<void> _disableException(Map<String, dynamic> exception) async {
    final exceptionId = exception['id'] as int;

    try {
      await _repository.disableAvailabilityException(exceptionId: exceptionId);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Išimtis išjungta')));

      await _loadExceptions();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko išjungti išimties')),
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
                onPressed: _loadExceptions,
                child: const Text('Bandyti dar kartą'),
              ),
            ],
          ),
        ),
      );
    }

    if (_exceptions.isEmpty) {
      return const Center(
        child: Text('Išimčių nerasta', style: TextStyle(fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExceptions,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _exceptions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final exception = _exceptions[index];

          final start = _formatDateTime(
            exception['start_datetime']?.toString() ?? '',
          );
          final end = _formatDateTime(
            exception['end_datetime']?.toString() ?? '',
          );
          final reason = exception['reason']?.toString() ?? '-';
          final isActive = exception['is_active'] as bool? ?? false;

          return Card(
            child: ListTile(
              leading: Icon(
                isActive ? Icons.check_circle : Icons.cancel,
                color: isActive ? Colors.green : Colors.grey,
              ),
              title: Text('$start - $end'),
              subtitle: Text('Priežastis: $reason'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openEditPage(exception);
                  } else if (value == 'disable') {
                    _disableException(exception);
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
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.user['full_name']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Mano išimtys')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePage,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              child: ListTile(
                title: const Text('Specialistas'),
                subtitle: Text(fullName),
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
