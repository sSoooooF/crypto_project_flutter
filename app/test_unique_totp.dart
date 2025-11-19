import 'lib/services/totp_service.dart';
import 'lib/services/auth_service.dart';
import 'lib/models/user.dart';

void main() async {
  print('=== Тест уникальности TOTP секретов ===\n');

  final authService = AuthService();
  final totpService = TotpService();

  // Тест 1: Проверка, что разные пользователи получают разные секреты
  print('1. Тест регистрации разных пользователей:');

  try {
    // Регистрируем первого пользователя
    final user1 = await authService.registerUser(
      'user1',
      'password1',
      Role.user,
      generateTotp: true,
    );
    print('   Пользователь 1: ${user1.username}');
    print('   Секрет 1: ${user1.totpSecret}');

    // Регистрируем второго пользователя
    final user2 = await authService.registerUser(
      'user2',
      'password2',
      Role.user,
      generateTotp: true,
    );
    print('   Пользователь 2: ${user2.username}');
    print('   Секрет 2: ${user2.totpSecret}');

    // Проверяем, что секреты разные
    final areSecretsDifferent = user1.totpSecret != user2.totpSecret;
    print('   Секреты разные: $areSecretsDifferent');

    if (!areSecretsDifferent) {
      print('   ОШИБКА: Секреты пользователей одинаковы!');
    }

    // Тест 2: Проверка генерации кодов для разных пользователей
    print('\n2. Тест генерации кодов:');

    final code1 = totpService.generateTotpCode(user1.totpSecret!);
    final code2 = totpService.generateTotpCode(user2.totpSecret!);

    print('   Код для user1: $code1');
    print('   Код для user2: $code2');
    print('   Коды разные: $code1 != $code2');

    // Тест 3: Проверка аутентификации с правильными кодами
    print('\n3. Тест аутентификации:');

    final authUser1 = await authService.authenticate(
      'user1',
      'password1',
      code1,
    );
    print('   Аутентификация user1: ${authUser1 != null}');

    final authUser2 = await authService.authenticate(
      'user2',
      'password2',
      code2,
    );
    print('   Аутентификация user2: ${authUser2 != null}');

    // Тест 4: Проверка, что код от одного пользователя не работает для другого
    print('\n4. Тест безопасности:');

    final wrongAuth1 = await authService.authenticate(
      'user1',
      'password1',
      code2, // Код от user2
    );
    print('   Попытка войти как user1 с кодом user2: ${wrongAuth1 != null}');

    final wrongAuth2 = await authService.authenticate(
      'user2',
      'password2',
      code1, // Код от user1
    );
    print('   Попытка войти как user2 с кодом user1: ${wrongAuth2 != null}');
  } catch (e) {
    print('   Ошибка при тестировании: $e');
  }

  print('\n=== Тест завершен ===');
}
