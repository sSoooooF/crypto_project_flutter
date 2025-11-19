import 'dart:io';
import 'lib/services/totp_service.dart';
import 'lib/services/auth_service.dart';
import 'lib/models/user.dart';
import 'package:otp/otp.dart';

void main() async {
  print('=== Отладка TOTP аутентификации ===\n');

  final totpService = TotpService();
  final authService = AuthService();

  // 1. Генерируем секрет
  print('1. Генерация TOTP секрета:');
  final secret = totpService.generateTotpSecret();
  print('   Секрет: $secret\n');

  // 2. Генерируем коды для разных временных меток
  print('2. Генерация кодов для разных временных меток:');
  final now = DateTime.now().millisecondsSinceEpoch;

  for (int offset in [-30000, 0, 30000]) {
    final timestamp = now + offset;
    final code = OTP.generateTOTPCodeString(secret, timestamp);
    final timeStr = DateTime.fromMillisecondsSinceEpoch(
      timestamp,
    ).toIso8601String();
    print('   Время: $timeStr, Код: $code');
  }
  print('');

  // 3. Проверяем коды
  print('3. Проверка кодов:');
  final currentCode = OTP.generateTOTPCodeString(secret, now);
  print('   Текущий код: $currentCode');

  // Проверяем текущий код
  final isValid = totpService.verifyTotpCode(secret, currentCode);
  print('   Проверка текущего кода: $isValid');

  // Проверяем неправильный код
  final wrongCode = '123456';
  final isWrongValid = totpService.verifyTotpCode(secret, wrongCode);
  print('   Проверка неправильного кода ($wrongCode): $isWrongValid\n');

  // 4. Тест регистрации пользователя
  print('4. Тест регистрации пользователя с TOTP:');
  try {
    final user = await authService.registerUser(
      'debuguser',
      'debugpassword',
      Role.user,
      generateTotp: true,
    );
    print('   Пользователь зарегистрирован: ${user.username}');
    print('   TOTP секрет: ${user.totpSecret}');

    // 5. Тест аутентификации
    print('\n5. Тест аутентификации:');
    final authCode = totpService.generateTotpCode(user.totpSecret!);
    print('   Сгенерированный код: $authCode');

    final authUser = await authService.authenticate(
      'debuguser',
      'debugpassword',
      authCode,
    );
    print('   Аутентификация успешна: ${authUser != null}');
    if (authUser != null) {
      print('   Пользователь: ${authUser.username}');
      print('   Роль: ${authUser.role}');
    }
  } catch (e) {
    print('   Ошибка: $e');
  }

  print('\n=== Отладка завершена ===');
}
