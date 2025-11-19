import 'dart:math';
import 'package:otp/otp.dart';

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
    return OTP.generateTOTPCodeString(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
  }

  bool verifyTotpCode(String secret, String code, {String? username}) {
    // Используем одну временную метку для всех проверок
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    final currentCode = OTP.generateTOTPCodeString(
      secret,
      currentTime,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
    final isValidCurrent = OTP.constantTimeVerification(currentCode, code);

    final previousTime = currentTime - 30;
    final previousCode = OTP.generateTOTPCodeString(
      secret,
      previousTime,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
    final isValidPrevious = OTP.constantTimeVerification(previousCode, code);

    final nextTime = currentTime + 30;
    final nextCode = OTP.generateTOTPCodeString(
      secret,
      nextTime,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
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
