import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../core/streebog/streebog.dart';
import 'home_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/totp_service.dart';
import 'qr_login_screen.dart';
import 'instructions_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController onetimeController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _registerWithTotp = false;
  String? _qrCodeUrl;

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
      User newUser = await _authService.registerUser(
        username,
        password,
        Role.user,
        generateTotp: _registerWithTotp,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Регистрация успешна')));
      if (newUser.totpSecret != null) {
        _showTotpSecretDialog(newUser.username, newUser.totpSecret!);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _generateQrCode() {
    final totpService = TotpService();
    final secret = totpService.generateTotpSecret();
    final username = usernameController.text.isNotEmpty
        ? usernameController.text
        : 'guest_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _qrCodeUrl = 'otpauth://totp/$username?secret=$secret&issuer=CryptoApp';
    });

    // Открываем экран QR-входа
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QrLoginScreen(qrCodeUrl: _qrCodeUrl!, username: username),
      ),
    );
  }

  void _showTotpSecretDialog(String username, String secret) {
    String otpUri = 'otpauth://totp/$username?secret=$secret&issuer=CryptoApp';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TOTP Секрет'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ваш секрет TOTP: $secret'),
            const SizedBox(height: 10),
            QrImageView(data: otpUri, version: QrVersions.auto, size: 200.0),
            const SizedBox(height: 10),
            const Text(
              'Отсканируйте этот QR-код приложением-аутентификатором.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тройная аутентификация')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок с инструкциями
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Способы входа:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMethodTile(
                      '1. Пароль + TOTP',
                      'Введите логин, пароль и код из приложения',
                    ),
                    _buildMethodTile(
                      '2. Только TOTP',
                      'Введите логин и код из приложения',
                    ),
                    _buildMethodTile('3. Как гость', 'Доступ без регистрации'),
                    _buildMethodTile(
                      '4. QR-код',
                      'Сканируйте QR-код с телефона',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

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
                labelText: 'Пароль (опционально)',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: onetimeController,
              decoration: const InputDecoration(
                labelText: 'Одноразовый код из приложения',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
                hintText: '6-значный код из Google Authenticator',
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            // Кнопки входа
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
              onPressed: () async {
                User? guest = await _authService.authenticateGuest();
                if (guest != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(user: guest),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Гость не найден')),
                  );
                }
              },
              icon: const Icon(Icons.person_off),
              label: const Text('Войти как гость'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Кнопка генерации QR-кода
            ElevatedButton.icon(
              onPressed: _generateQrCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Сгенерировать QR-код для входа'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Отображение QR-кода
            if (_qrCodeUrl != null)
              Column(
                children: [
                  const Text(
                    'Отсканируйте этот QR-код в приложении аутентификации:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: _qrCodeUrl!,
                    version: QrVersions.auto,
                    size: 200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Имя пользователя: ${usernameController.text.isNotEmpty ? usernameController.text : "guest_${DateTime.now().millisecondsSinceEpoch}"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Кнопка инструкций
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InstructionsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.help_outline),
              label: const Text('Как использовать QR-код?'),
            ),

            const SizedBox(height: 16),

            // Разделитель
            const Divider(),

            const SizedBox(height: 16),

            // Регистрация с TOTP
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Регистрация:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _registerWithTotp,
                          onChanged: (bool? value) {
                            setState(() {
                              _registerWithTotp = value ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Создать аккаунт с двухфакторной аутентификацией (TOTP)',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _register,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Зарегистрироваться'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // QR-код входа (будет добавлено позже)
            if (_qrCodeUrl != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Вход через QR-код:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      QrImageView(
                        data: _qrCodeUrl!,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Отсканируйте этот QR-код приложением на вашем телефоне',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check, color: Colors.blue, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
