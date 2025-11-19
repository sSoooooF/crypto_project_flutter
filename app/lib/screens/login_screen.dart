import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../core/streebog/streebog.dart';
import 'home_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController onetimeController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  void _login() async {
    String username = usernameController.text;
    String password = passwordController.text;
    String onetimeCode = onetimeController.text;

    User? user = null;

    // 1. Парольная аутентификация
    if (password.isNotEmpty) {
      Streebog streebog = Streebog();
      streebog.update(utf8.encode(password));
      List<int> digest = streebog.digest();
      String passwordHash = digest
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      user = await _databaseService.authenticate(username, passwordHash);
    }

    // 2. Одноразовый код (если пароль не подошел)
    if (user == null && onetimeCode.isNotEmpty) {
      user = await _checkOnetimeCode(username, onetimeCode);
    }

    // 3. Гость (если ничего не введено)
    if (user == null) {
      try {
        final users = await _databaseService.getUsers();
        user = users.firstWhere((u) => u.username == 'guest');
      } catch (e) {
        // Гость не найден
      }
    }

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(user: user!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверные данные аутентификации')),
      );
    }
  }

  Future<User?> _checkOnetimeCode(String username, String code) async {
    try {
      final users = await _databaseService.getUsers();
      final user = users.firstWhere((u) => u.username == username);
      if (code == '123456') {
        return user;
      }
    } catch (e) {
      // Пользователь не найден
    }
    return null;
  }

  void _register() async {
    String username = usernameController.text;
    String password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заполните все поля')));
      return;
    }

    // Хэшируем пароль
    Streebog streebog = Streebog();
    streebog.update(utf8.encode(password));
    List<int> digest = streebog.digest();
    String passwordHash = digest
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    try {
      await _databaseService.registerUser(username, passwordHash, Role.user);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Регистрация успешна')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тройная аутентификация')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Логин'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Пароль (опционально)',
              ),
              obscureText: true,
            ),
            TextField(
              controller: onetimeController,
              decoration: const InputDecoration(
                labelText: 'Одноразовый код (123456)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _login,
              icon: const Icon(Icons.login),
              label: const Text('Войти'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final users = await _databaseService.getUsers();
                  final guest = users.firstWhere((u) => u.username == 'guest');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(user: guest),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Гость не найден')),
                  );
                }
              },
              icon: const Icon(Icons.person_off),
              label: const Text('Войти как гость'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _register,
              icon: const Icon(Icons.person_add),
              label: const Text('Регистрация'),
            ),
          ],
        ),
      ),
    );
  }
}
