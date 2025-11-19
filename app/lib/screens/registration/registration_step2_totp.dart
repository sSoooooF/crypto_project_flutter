import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/totp_service.dart';
import 'registration_step3_biometric.dart';

class RegistrationStep2TOTP extends StatefulWidget {
  final String username;
  final String password;

  const RegistrationStep2TOTP({
    super.key,
    required this.username,
    required this.password,
  });

  @override
  State<RegistrationStep2TOTP> createState() => _RegistrationStep2TOTPState();
}

class _RegistrationStep2TOTPState extends State<RegistrationStep2TOTP> {
  final _authService = AuthService();
  final _totpService = TotpService();
  final _codeController = TextEditingController();
  String? _totpSecret;
  String? _qrCodeUrl;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _generateTOTP();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _generateTOTP() {
    setState(() {
      _totpSecret = _authService.generateTotpSecret();
      _qrCodeUrl =
          'otpauth://totp/CryptoApp:${widget.username}?algorithm=SHA1&digits=6&secret=$_totpSecret&issuer=CryptoApp&period=30';
    });
  }

  void _copySecretToClipboard() async {
    if (_totpSecret != null) {
      await Clipboard.setData(ClipboardData(text: _totpSecret!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Секретный код скопирован в буфер обмена'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _verifyCode() {
    if (_totpSecret == null) return;

    final enteredCode = _codeController.text.trim();
    if (enteredCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите 6-значный код')),
      );
      return;
    }

    // Use the TOTP service verification which checks time windows
    final isValid = _totpService.verifyTotpCode(_totpSecret!, enteredCode);
    if (isValid) {
      setState(() {
        _isVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Код подтвержден!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Неверный код. Попробуйте еще раз.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _nextStep() {
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала подтвердите TOTP код')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationStep3Biometric(
          username: widget.username,
          password: widget.password,
          totpSecret: _totpSecret!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация - Шаг 2: TOTP'),
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
                    const Icon(Icons.phone_android, size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text(
                      'Второй фактор: TOTP',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Настройте двухфакторную аутентификацию',
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
            if (_qrCodeUrl != null) ...[
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
                      Card(
                        color: Colors.grey.shade100,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Секретный код TOTP:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      _totpSecret ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    tooltip: 'Копировать секретный код',
                                    onPressed: _copySecretToClipboard,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: _isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        _isVerified ? Icons.check_circle : Icons.info,
                        color: _isVerified ? Colors.green : Colors.orange,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isVerified
                            ? 'TOTP код подтвержден!'
                            : 'Подтвердите настройку TOTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isVerified ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Введите код из приложения аутентификации для подтверждения',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Код из приложения (6 цифр)',
                  prefixIcon: Icon(Icons.security),
                  border: OutlineInputBorder(),
                  hintText: '000000',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                enabled: !_isVerified,
              ),
              const SizedBox(height: 8),
              if (!_isVerified)
                ElevatedButton.icon(
                  onPressed: _verifyCode,
                  icon: const Icon(Icons.verified),
                  label: const Text('Подтвердить код'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isVerified ? _nextStep : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Далее: Биометрия'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

