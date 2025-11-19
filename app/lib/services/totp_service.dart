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
    final currentTime = DateTime.now().toUtc();
    return OTP.generateTOTPCodeString(
      secret,
      currentTime.millisecondsSinceEpoch,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
  }

  bool verifyTotpCode(String secret, String code, {String? username}) {
    // TOTP must use UTC time - Google Authenticator uses UTC
    final currentTime = DateTime.now().toUtc();
    final currentTimeMs = currentTime.millisecondsSinceEpoch;

    final currentCode = OTP.generateTOTPCodeString(
      secret,
      currentTimeMs,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
    final isValidCurrent = OTP.constantTimeVerification(currentCode, code);

    // Check previous time window (30 seconds ago)
    final previousTime = currentTimeMs - 30000;
    final previousCode = OTP.generateTOTPCodeString(
      secret,
      previousTime,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
    final isValidPrevious = OTP.constantTimeVerification(previousCode, code);

    // Check next time window (30 seconds ahead)
    final nextTime = currentTimeMs + 30000;
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
    print('  Текущий код (UTC $currentTime): $currentCode');
    print('  Предыдущий код ($previousTime): $previousCode');
    print('  Следующий код ($nextTime): $nextCode');
    print('  Текущий код верен: $isValidCurrent');
    print('  Предыдущий код верен: $isValidPrevious');
    print('  Следующий код верен: $isValidNext');

    return isValidCurrent || isValidPrevious || isValidNext;
  }
}
