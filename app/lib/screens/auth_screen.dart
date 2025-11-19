import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
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
  final BiometricService _biometricService = BiometricService();

  bool _isRegistering = false;
  bool _showQrCode = false;
  String? _qrCodeUrl;
  String? _totpSecret;
  String? _registrationMessage;
  String? _pendingUsername;
  String? _pendingPasswordHash;

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
      if (guest != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(user: guest)),
        );
        return;
      }
    }

    if (password.isEmpty) {
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
      if (!isBiometricAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Биометрическая аутентификация недоступна на этом устройстве'),
          ),
        );
        return;
      }

      final bool biometricSuccess = await _biometricService.authenticate(
        reason: 'Подтвердите свою личность для входа в аккаунт ${user.username}',
      );

      if (!biometricSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Биометрическая аутентификация не пройдена')),
        );
        return;
      }
    }

    // All authentication factors passed
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
    );
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
      final generatedSecret = _authService.generateTotpSecret();
      
      // Сохраняем пользователя сначала без биометрии
      await _authService.registerUserWithTotp(
        username,
        passwordHash,
        Role.user,
        generatedSecret,
        hasBiometricEnabled: false,
      );
      
      // Сохраняем данные для последующего обновления после биометрии
      setState(() {
        _pendingUsername = username;
        _pendingPasswordHash = passwordHash;
        _totpSecret = generatedSecret;
        _isRegistering = true;
        _showQrCode = true;
        _qrCodeUrl =
            'otpauth://totp/CryptoApp:$username?algorithm=SHA1&digits=6&secret=$_totpSecret&issuer=CryptoApp&period=30';
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

  Future<void> _enrollBiometric() async {
    if (_pendingUsername == null || _pendingPasswordHash == null || _totpSecret == null) {
      return;
    }

    // Check if biometric is available
    final bool isAvailable = await _biometricService.isAvailable();
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Биометрическая аутентификация недоступна на этом устройстве'),
        ),
      );
      return;
    }

    // Prompt for fingerprint enrollment
    final bool success = await _biometricService.authenticate(
      reason: 'Зарегистрируйте отпечаток пальца для аккаунта $_pendingUsername',
    );

    if (success) {
      try {
        // Update user's biometric status
        await _authService.updateUserBiometricStatus(_pendingUsername!, true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отпечаток пальца успешно зарегистрирован!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset registration state
        _resetRegistration();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Регистрация отпечатка отменена')),
      );
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
      _pendingUsername = null;
      _pendingPasswordHash = null;
    });
  }

  void _createTestUser() async {
    try {
      // Генерируем TOTP секрет
      final generatedSecret = _authService.generateTotpSecret();

      // Хэшируем пароль тестового пользователя
      const testPassword = 'testpassword123';
      Streebog streebog = Streebog();
      streebog.update(utf8.encode(testPassword));
      List<int> digest = streebog.digest();
      String passwordHash = digest
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();

      // Регистрируем тестового пользователя с тем же секретом
      User newUser = await _authService.registerUserWithTotp(
        'testuser',
        passwordHash,
        Role.user,
        generatedSecret,
      );

      setState(() {
        _totpSecret = generatedSecret;
        _isRegistering = true;
        _showQrCode = true;
        _qrCodeUrl =
            'otpauth://totp/CryptoApp:testuser?algorithm=SHA1&digits=6&secret=$_totpSecret&issuer=CryptoApp&period=30';
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
                labelText: 'Второй фактор: Код TOTP (6 цифр)',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
                hintText: 'Введите код из приложения аутентификации',
                helperText: 'После ввода пароля потребуется код TOTP',
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

                  // Biometric enrollment button
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.fingerprint,
                            size: 48,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Зарегистрируйте отпечаток пальца',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Это третий фактор аутентификации для дополнительной безопасности',
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _enrollBiometric,
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Зарегистрировать отпечаток'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                            ),
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
