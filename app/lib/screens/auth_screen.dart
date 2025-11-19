import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../core/streebog/streebog.dart';
import 'home_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/totp_service.dart';

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

  bool _isRegistering = false;
  bool _showQrCode = false;
  String? _qrCodeUrl;
  String? _totpSecret;
  String? _registrationMessage;

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

    User? user = null;

    // 1. Парольная аутентификация и TOTP
    if (password.isNotEmpty) {
      user = await _authService.authenticate(
        username,
        password,
        onetimeCode.isNotEmpty ? onetimeCode : null,
      );
    }

    // 2. Гость (если ничего не введено и не удалось аутентифицироваться)
    if (user == null &&
        username.isEmpty &&
        password.isEmpty &&
        onetimeCode.isEmpty) {
      user = await _authService.authenticateGuest();
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

  void _register() async {
    String username = usernameController.text;
    String password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заполните логин и пароль')));
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
      // Генерируем TOTP секрет
      _totpSecret = _authService.generateTotpSecret();

      // Регистрируем пользователя
      User newUser = await _authService.registerUser(
        username,
        password,
        Role.user,
        generateTotp: true,
      );

      setState(() {
        _isRegistering = true;
        _showQrCode = true;
        _qrCodeUrl =
            'otpauth://totp/$username?secret=$_totpSecret&issuer=CryptoApp&algorithm=SHA1&digits=6&period=30';
        _registrationMessage =
            'Регистрация успешна! Добавьте аккаунт в приложение аутентификации:';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Регистрация успешна!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка регистрации: $e')));
    }
  }

  void _loginAsGuest() async {
    User? guest = await _authService.authenticateGuest();
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

  void _resetRegistration() {
    setState(() {
      _isRegistering = false;
      _showQrCode = false;
      _qrCodeUrl = null;
      _totpSecret = null;
      _registrationMessage = null;
    });
  }

  void _createTestUser() async {
    try {
      // Генерируем TOTP секрет
      _totpSecret = _authService.generateTotpSecret();

      // Регистрируем тестового пользователя
      User newUser = await _authService.registerUser(
        'testuser',
        'testpassword123',
        Role.user,
        generateTotp: true,
      );

      setState(() {
        _isRegistering = true;
        _showQrCode = true;
        _qrCodeUrl =
            'otpauth://totp/testuser?secret=$_totpSecret&issuer=CryptoApp';
        _registrationMessage =
            'Тестовый пользователь создан! Логин: testuser, Пароль: testpassword123\nДобавьте аккаунт в приложение аутентификации:';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тестовый пользователь создан!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
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
            if (_showQrCode)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _registrationMessage ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
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
              enabled: !_showQrCode,
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
              enabled: !_showQrCode,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: onetimeController,
              decoration: const InputDecoration(
                labelText: 'Код из приложения (6 цифр)',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
                hintText: 'Введите код при входе',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              enabled: !_showQrCode,
            ),

            const SizedBox(height: 24),

            // Кнопки
            if (!_showQrCode)
              Column(
                children: [
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
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _createTestUser,
                    icon: const Icon(Icons.build),
                    label: const Text('Создать тестового пользователя'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  // QR-код
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Отсканируйте QR-код:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: _qrCodeUrl!,
                            version: QrVersions.auto,
                            size: 200,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '1. Откройте приложение аутентификации (Google Authenticator, Authy и т.д.)',
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '2. Нажмите "+" и выберите "Сканировать QR-код"',
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '3. Наведите камеру на QR-код выше',
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _resetRegistration,
                    child: const Text('Зарегистрировать другой аккаунт'),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: _login,
                    icon: const Icon(Icons.login),
                    label: const Text('Войти в аккаунт'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
