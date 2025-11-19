import 'dart:convert';
import 'dart:math';
import 'package:otp/otp.dart';
import '../models/user.dart';
import '../core/streebog/streebog.dart';
import 'database_service.dart';

class AuthService {
  final DatabaseService _databaseService = DatabaseService();

  String generateTotpSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    return List.generate(
      32,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String generateTotpCode(String secret) {
    return OTP.generateTOTPCodeString(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      isGoogle: true,
    );
  }

  bool verifyTotpCode(String secret, String code, {String? username}) {
    // Используем тот же подход, что и в TotpService
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    final currentCode = OTP.generateTOTPCodeString(
      secret,
      currentTime,
      isGoogle: true,
      algorithm: Algorithm.SHA1,
    );
    final isValidCurrent = OTP.constantTimeVerification(currentCode, code);

    final previousTime = currentTime - 30000;
    final previousCode = OTP.generateTOTPCodeString(
      secret,
      previousTime,
      isGoogle: true,
      algorithm: Algorithm.SHA1,
    );
    final isValidPrevious = OTP.constantTimeVerification(previousCode, code);

    final nextTime = currentTime + 30000;
    final nextCode = OTP.generateTOTPCodeString(
      secret,
      nextTime,
      isGoogle: true,
      algorithm: Algorithm.SHA1,
    );
    final isValidNext = OTP.constantTimeVerification(nextCode, code);

    // Для отладки
    final userInfo = username != null ? ' для пользователя: $username' : '';
    print('AuthService TOTP Debug$userInfo:');
    print('  Секрет: $secret');
    print('  Введенный код: $code');
    print('  Текущий код ($currentTime): $currentCode');
    print('  Предыдущий код ($previousTime): $previousCode');
    print('  Следующий код ($nextTime): $nextCode');
    print('  Текущий код верен: $isValidCurrent');
    print('  Предыдущий код верен: $isValidPrevious');
    print('  Следующий код верен: $isValidNext');

    return isValidCurrent || isValidPrevious || isValidNext;
  }

  Future<User?> authenticate(
    String username,
    String password,
    String? totpCode,
  ) async {
    // Если введен пароль, проверяем пароль и TOTP
    if (password.isNotEmpty) {
      // Хэшируем пароль
      Streebog streebog = Streebog();
      streebog.update(utf8.encode(password));
      List<int> digest = streebog.digest();
      String passwordHash = digest
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();

      // Проверяем пароль
      User? user = await _databaseService.authenticate(username, passwordHash);
      if (user == null) return null;

      // Если у пользователя есть TOTP секрет, проверяем код
      if (user.totpSecret != null && totpCode != null) {
        if (!verifyTotpCode(user.totpSecret!, totpCode, username: username)) {
          return null;
        }
      }

      return user;
    }
    // Если пароль не введен, но введен TOTP код, проверяем только TOTP
    else if (totpCode != null && totpCode.isNotEmpty) {
      // Ищем пользователя по имени
      final users = await _databaseService.getUsers();
      User? user;
      try {
        user = users.firstWhere((u) => u.username == username);
      } catch (e) {
        return null;
      }

      // Если у пользователя есть TOTP секрет, проверяем код
      if (user.totpSecret != null) {
        if (!verifyTotpCode(user.totpSecret!, totpCode)) {
          return null;
        }
        return user;
      }

      return null;
    }

    return null;
  }

  Future<User> registerUser(
    String username,
    String password,
    Role role, {
    bool generateTotp = false,
  }) async {
    // Хэшируем пароль
    Streebog streebog = Streebog();
    streebog.update(utf8.encode(password));
    List<int> digest = streebog.digest();
    String passwordHash = digest
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    String? totpSecret = generateTotp ? generateTotpSecret() : null;

    await _databaseService.registerUser(
      username,
      passwordHash,
      role,
      totpSecret: totpSecret,
    );

    // Возвращаем пользователя
    User user = User(
      username: username,
      passwordHash: passwordHash,
      role: role,
      createdAt: DateTime.now(),
      totpSecret: totpSecret,
    );
    return user;
  }

  Future<User> registerUserWithTotp(
    String username,
    String passwordHash,
    Role role,
    String totpSecret,
  ) async {
    await _databaseService.registerUser(
      username,
      passwordHash,
      role,
      totpSecret: totpSecret,
    );

    // Возвращаем пользователя
    User user = User(
      username: username,
      passwordHash: passwordHash,
      role: role,
      createdAt: DateTime.now(),
      totpSecret: totpSecret,
    );
    return user;
  }

  Future<User?> authenticateGuest() async {
    final users = await _databaseService.getUsers();
    try {
      return users.firstWhere((u) => u.username == 'guest');
    } catch (e) {
      return null;
    }
  }

  Future<void> createTestUser() async {
    try {
      // Проверяем, существует ли уже тестовый пользователь
      final users = await _databaseService.getUsers();
      if (users.any((u) => u.username == 'testuser')) {
        return;
      }

      // Создаем тестового пользователя с TOTP
      final testSecret = generateTotpSecret();
      await registerUserWithTotp(
        'testuser',
        'testpassword123',
        Role.user,
        testSecret,
      );

      print('Тестовый пользователь создан:');
      print('Логин: testuser');
      print('Пароль: testpassword123');
      print('TOTP секрет: $testSecret');
      print(
        'Сгенерируйте QR-код и отсканируйте его в приложении аутентификации',
      );
    } catch (e) {
      print('Ошибка создания тестового пользователя: $e');
    }
  }
}
