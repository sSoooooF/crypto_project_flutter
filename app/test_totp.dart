import 'lib/services/totp_service.dart';
import 'lib/services/auth_service.dart';
import 'lib/models/user.dart';

void main() async {
  print('=== Тестирование TOTP и QR-кодов ===\n');

  final totpService = TotpService();
  final authService = AuthService();

  // 1. Тест генерации секрета
  print('1. Тест генерации TOTP секрета:');
  final secret = totpService.generateTotpSecret();
  print('   Сгенерирован секрет: $secret');
  print('   Длина секрета: ${secret.length} символов\n');

  // 2. Тест генерации кода
  print('2. Тест генерации TOTP кода:');
  final code = totpService.generateTotpCode(secret);
  print('   Сгенерирован код: $code');
  print('   Длина кода: ${code.length} символов\n');

  // 3. Тест проверки кода
  print('3. Тест проверки TOTP кода:');
  final isValid = totpService.verifyTotpCode(secret, code);
  print('   Проверка правильного кода: $isValid');

  // 4. Тест проверки неправильного кода
  final wrongCode = '123456';
  final isWrongValid = totpService.verifyTotpCode(secret, wrongCode);
  print('   Проверка неправильного кода ($wrongCode): $isWrongValid\n');

  // 5. Тест регистрации пользователя с TOTP
  print('4. Тест регистрации пользователя с TOTP:');
  try {
    final user = await authService.registerUser(
      'testuser',
      'testpassword',
      Role.user,
      generateTotp: true,
    );
    print('   Пользователь зарегистрирован: ${user.username}');
    print('   TOTP секрет: ${user.totpSecret}');
    print('   Роль: ${user.role}\n');

    // 6. Тест аутентификации с паролем и TOTP
    print('5. Тест аутентификации с паролем и TOTP:');
    final authUser = await authService.authenticate(
      'testuser',
      'testpassword',
      code,
    );
    print('   Аутентификация успешна: ${authUser != null}');
    print('   Пользователь: ${authUser?.username}');
  } catch (e) {
    print('   Ошибка: $e');
  }

  print('\n=== Тест завершен ===');
}
