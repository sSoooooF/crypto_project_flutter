import 'package:flutter/material.dart';
import 'dart:async';
import '../services/totp_service.dart';
import '../models/user.dart';
import 'home_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrLoginScreen extends StatefulWidget {
  final String qrCodeUrl;
  final String username;

  const QrLoginScreen({
    super.key,
    required this.qrCodeUrl,
    required this.username,
  });

  @override
  State<QrLoginScreen> createState() => _QrLoginScreenState();
}

class _QrLoginScreenState extends State<QrLoginScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TotpService _totpService = TotpService();
  bool _isLoading = false;
  bool _isValid = false;
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _refreshQrCode();
      }
    });
  }

  void _refreshQrCode() {
    Navigator.pop(context);
  }

  void _verifyCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final code = _codeController.text.trim();
      if (code.isEmpty) {
        throw 'Введите код из приложения';
      }

      // Проверяем, что код состоит из 6 цифр
      if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
        throw 'Неверный формат кода';
      }

      // Извлекаем секрет из QR-кода URL
      final secret = _extractSecretFromQrCode(widget.qrCodeUrl);

      // Проверяем код через TOTP
      final isValid = _totpService.verifyTotpCode(secret, code);

      if (!isValid) {
        throw 'Неверный код. Попробуйте еще раз.';
      }

      setState(() {
        _isValid = true;
        _isLoading = false;
      });

      // Создаем пользователя для входа
      final user = User(
        username: widget.username,
        passwordHash: '',
        role: Role.user,
        createdAt: DateTime.now(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  String _extractSecretFromQrCode(String qrCodeUrl) {
    // Извлекаем секрет из URL otpauth://totp/username?secret=SECRET&issuer=CryptoApp
    final uri = Uri.parse(qrCodeUrl);
    final secret = uri.queryParameters['secret'];
    if (secret == null) {
      throw 'Не удалось извлечь секрет из QR-кода';
    }
    return secret;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход через QR-код'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      data: widget.qrCodeUrl,
                      version: QrVersions.auto,
                      size: 200,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Имя пользователя: ${widget.username}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Код обновится через $_countdown секунд',
                      style: TextStyle(
                        fontSize: 12,
                        color: _countdown < 10 ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Инструкция
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Как войти:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      '1. Откройте приложение аутентификации',
                      'Google Authenticator, Authy или другое',
                    ),
                    _buildInstructionStep(
                      '2. Найдите аккаунт CryptoApp',
                      'Если его нет, добавьте новый аккаунт',
                    ),
                    _buildInstructionStep(
                      '3. Введите 6-значный код ниже',
                      'Код обновляется каждые 30 секунд',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Поле ввода кода
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: '6-значный код из приложения',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (value) {
                if (value.length == 6) {
                  _verifyCode();
                }
              },
            ),

            const SizedBox(height: 16),

            // Кнопки
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_isValid)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Вход успешный!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _codeController.text.length == 6
                        ? _verifyCode
                        : null,
                    child: const Text('Подтвердить вход'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _refreshQrCode,
                    child: const Text('Обновить QR-код'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
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
