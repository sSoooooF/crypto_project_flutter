import 'dart:math';
import 'package:otp/otp.dart';
import 'package:timezone/data/latest.dart' as timezone;
import 'package:timezone/timezone.dart' as timezone;

class TotpService {
  String generateTotpSecret() {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    return List.generate(
      32,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String generateTotpCode(String secret) {
    final currentTime = DateTime.now();
    timezone.initializeTimeZones();
    final pacificTimeZone = timezone.getLocation('Russia/Moscow');
    final date = timezone.TZDateTime.from(currentTime, pacificTimeZone);
    return OTP.generateTOTPCodeString(
      secret,
      date.millisecondsSinceEpoch,
      algorithm: Algorithm.SHA1,
    );
  }

  bool verifyTotpCode(String secret, String code, {String? username}) {
    // Используем одну временную метку для всех проверок
    final currentTime = DateTime.now();
    timezone.initializeTimeZones();
    final pacificTimeZone = timezone.getLocation('Russia/Moscow');
    final date = timezone.TZDateTime.from(currentTime, pacificTimeZone);

    final currentCode = OTP.generateTOTPCodeString(
      secret,
      date.millisecondsSinceEpoch,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
    final isValidCurrent = OTP.constantTimeVerification(currentCode, code);

    final previousTime = date.millisecondsSinceEpoch - 30000;
    final previousCode = OTP.generateTOTPCodeString(
      secret,
      previousTime,
      algorithm: Algorithm.SHA1,
    );
    final isValidPrevious = OTP.constantTimeVerification(previousCode, code);

    final nextTime = date.millisecondsSinceEpoch + 30000;
    final nextCode = OTP.generateTOTPCodeString(
      secret,
      nextTime,
      algorithm: Algorithm.SHA1,
    );
    final isValidNext = OTP.constantTimeVerification(nextCode, code);

    // Для отладки - выводим информацию с указанием пользователя
    final userInfo = username != null ? ' для пользователя: $username' : '';
    print('TOTP Debug$userInfo:');
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
}
