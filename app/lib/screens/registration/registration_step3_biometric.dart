import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../models/user.dart';
import '../../core/streebog/streebog.dart';
import 'dart:convert';
import '../home_screen.dart';

class RegistrationStep3Biometric extends StatefulWidget {
  final String username;
  final String password;
  final String totpSecret;

  const RegistrationStep3Biometric({
    super.key,
    required this.username,
    required this.password,
    required this.totpSecret,
  });

  @override
  State<RegistrationStep3Biometric> createState() => _RegistrationStep3BiometricState();
}

class _RegistrationStep3BiometricState extends State<RegistrationStep3Biometric> {
  final _authService = AuthService();
  final _biometricService = BiometricService();
  bool _biometricEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isAvailable();
    if (!isAvailable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Биометрическая аутентификация недоступна на этом устройстве'),
        ),
      );
    }
  }

  Future<void> _enrollBiometric() async {
    setState(() {
      _isLoading = true;
    });

    final isAvailable = await _biometricService.isAvailable();
    if (!isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Биометрическая аутентификация недоступна'),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final success = await _biometricService.authenticate(
      reason: 'Зарегистрируйте отпечаток пальца для аккаунта ${widget.username}',
    );

    setState(() {
      _isLoading = false;
      _biometricEnabled = success;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Отпечаток пальца успешно зарегистрирован!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Регистрация отпечатка отменена')),
      );
    }
  }

  Future<void> _completeRegistration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Хэшируем пароль
      Streebog streebog = Streebog();
      streebog.update(utf8.encode(widget.password));
      List<int> digest = streebog.digest();
      String passwordHash = digest
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();

      // Регистрируем пользователя
      final user = await _authService.registerUserWithTotp(
        widget.username,
        passwordHash,
        Role.user,
        widget.totpSecret,
        hasBiometricEnabled: _biometricEnabled,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Регистрация успешно завершена!'),
            backgroundColor: Colors.green,
          ),
        );

        // Переходим на главный экран
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка регистрации: $e')),
        );
      }
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
      appBar: AppBar(
        title: const Text('Регистрация - Шаг 3: Биометрия'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.fingerprint, size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text(
                      'Третий фактор: Биометрия',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Дополнительная защита с помощью отпечатка пальца',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: _biometricEnabled ? Colors.green.shade50 : Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _biometricEnabled ? Icons.check_circle : Icons.fingerprint,
                      size: 64,
                      color: _biometricEnabled ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _biometricEnabled
                          ? 'Биометрия настроена!'
                          : 'Настройте биометрию (опционально)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _biometricEnabled ? Colors.green : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _biometricEnabled
                          ? 'Отпечаток пальца будет использоваться при входе'
                          : 'Вы можете пропустить этот шаг и настроить биометрию позже',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_biometricEnabled)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _enrollBiometric,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Зарегистрировать отпечаток пальца'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _completeRegistration,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isLoading ? 'Завершение регистрации...' : 'Завершить регистрацию'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isLoading ? null : _completeRegistration,
              child: const Text('Пропустить биометрию'),
            ),
          ],
        ),
      ),
    );
  }
}

