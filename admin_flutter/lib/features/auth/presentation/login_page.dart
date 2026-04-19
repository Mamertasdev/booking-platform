import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/storage/token_storage.dart';
import '../../admin/presentation/admin_home_page.dart';
import '../../specialist/presentation/specialist_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      baseUrl: 'http://100.80.21.21:8000',
      tokenStorage: tokenStorage,
    );
    final authApi = AuthApi(apiClient);

    _authRepository = AuthRepository(
      authApi: authApi,
      tokenStorage: tokenStorage,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'Įveskite prisijungimo vardą ir slaptažodį';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await _authRepository.login(username: username, password: password);

      final user = await _authRepository.getCurrentUser();

      if (!mounted) return;

      final role = (user['role'] as String? ?? '').toLowerCase();

      if (role == 'admin' || role == 'owner') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AdminHomePage(user: user)),
        );
        return;
      }

      if (role == 'specialist') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SpecialistHomePage(user: user)),
        );
        return;
      }

      setState(() {
        _errorText = 'Nežinoma vartotojo rolė';
      });
    } catch (_) {
      setState(() {
        _errorText = 'Prisijungti nepavyko';
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Prisijungimas',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Prisijunkite prie administravimo sistemos',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Prisijungimo vardas',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Slaptažodis',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Prisijungti'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
