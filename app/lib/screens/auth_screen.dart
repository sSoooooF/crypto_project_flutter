import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../models/user.dart';
import 'home_screen.dart';
import 'registration/registration_step1_password.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController onetimeController = TextEditingController();
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();


  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    onetimeController.dispose();
    super.dispose();
  }

  void _login() async {
    String username = usernameController.text;
    String password = passwordController.text;
    String onetimeCode = onetimeController.text;

    // Guest login (if nothing entered)
    if (username.isEmpty && password.isEmpty && onetimeCode.isEmpty) {
      User? guest = await _authService.authenticateGuest();
      if (!mounted) return;
      if (guest != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(user: guest)),
        );
        return;
      }
    }

    if (password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите пароль')),
      );
      return;
    }

    // Step 1: Verify username and password
    User? user = await _authService.authenticate(
      username,
      password,
      onetimeCode.isNotEmpty ? onetimeCode : null,
    );

    if (!mounted) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный логин, пароль или код TOTP')),
      );
      return;
    }

    // Step 2: TOTP verification is already done in authenticate()
    // If user has TOTP but code is missing/invalid, authenticate() returns null

    // Step 3: Verify fingerprint/biometric (if enabled)
    if (user.hasBiometricEnabled) {
      final bool isBiometricAvailable = await _biometricService.isAvailable();
      if (!mounted) return;
      if (!isBiometricAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Биометрическая аутентификация недоступна на этом устройстве'),
          ),
        );
        return;
      }

      final reason = Platform.isIOS
          ? 'Используйте Face ID для входа в аккаунт ${user.username}'
          : 'Используйте отпечаток пальца для входа в аккаунт ${user.username}';

      final bool biometricSuccess = await _biometricService.authenticate(reason: reason);

      if (!mounted) return;

      if (!biometricSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Биометрическая аутентификация не пройдена')),
        );
        return;
      }
    }

    // All authentication factors passed
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
    );
  }

  void _register() async {
    // Navigate to multi-step registration
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegistrationStep1Password(),
      ),
    );
  }


  void _loginAsGuest() async {
    User? guest = await _authService.authenticateGuest();
    if (!mounted) return;
    if (guest != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(user: guest)),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Гость не найден')));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход / Регистрация'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Войдите в существующий аккаунт или зарегистрируйте новый',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Поля ввода
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Логин',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: onetimeController,
              decoration: const InputDecoration(
                labelText: 'Второй фактор: Код TOTP (6 цифр)',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
                hintText: 'Введите код из приложения аутентификации',
                helperText: 'После ввода пароля потребуется код TOTP',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),

            const SizedBox(height: 24),

            // Кнопки
            ElevatedButton.icon(
              onPressed: _login,
              icon: const Icon(Icons.login),
              label: const Text('Войти'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _register,
              icon: const Icon(Icons.person_add),
              label: const Text('Зарегистрироваться'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loginAsGuest,
              icon: const Icon(Icons.person_off),
              label: const Text('Войти как гость'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
