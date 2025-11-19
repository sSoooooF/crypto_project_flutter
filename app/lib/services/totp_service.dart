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
    );
  }

  bool verifyTotpCode(String secret, String code) {
    // Проверяем текущий код
    if (OTP.constantTimeVerification(
      OTP.generateTOTPCodeString(secret, DateTime.now().millisecondsSinceEpoch),
      code,
    )) {
      return true;
    }

    // Проверяем коды из предыдущего и следующего временных интервалов (30 секунд)
    for (int offset = -30000; offset <= 30000; offset += 30000) {
      if (offset != 0 &&
          OTP.constantTimeVerification(
            OTP.generateTOTPCodeString(
              secret,
              DateTime.now().millisecondsSinceEpoch + offset,
            ),
            code,
          )) {
        return true;
      }
    }

    return false;
  }
}
