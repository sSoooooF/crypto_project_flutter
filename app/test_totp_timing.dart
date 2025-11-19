import 'dart:math';
import 'package:otp/otp.dart';

void main() {
  print('=== Тестирование TOTP с правильными временными метками ===\n');

  // Тест 1: Проверка генерации кодов для одного и того же времени
  print('1. Тест генерации кодов для одного и того же времени:');

  final secret = 'JBSWY3DPEHPK3PXP'; // Тестовый секрет
  final currentTime = DateTime.now().millisecondsSinceEpoch;

  // Генерируем коды несколько раз для одного и того же времени
  for (int i = 0; i < 3; i++) {
    final code = OTP.generateTOTPCodeString(secret, currentTime);
    print('   Код $i: $code');
  }

  print('\n2. Тест временных интервалов:');

  // Тест 2: Проверка кодов для разных временных интервалов
  final intervals = [
    currentTime - 60000, // 1 минута назад
    currentTime - 30000, // 30 секунд назад
    currentTime, // сейчас
    currentTime + 30000, // 30 секунд вперед
    currentTime + 60000, // 1 минута вперед
  ];

  for (int i = 0; i < intervals.length; i++) {
    final time = intervals[i];
    final code = OTP.generateTOTPCodeString(secret, time);
    final timeStr = DateTime.fromMillisecondsSinceEpoch(time).toIso8601String();
    print('   Время $i ($timeStr): $code');
  }

  print('\n3. Тест проверки кодов:');

  // Тест 3: Проверка кодов
  final testCode = OTP.generateTOTPCodeString(secret, currentTime);
  print('   Тестовый код: $testCode');

  // Проверяем код для текущего времени
  final isValidCurrent = OTP.constantTimeVerification(
    OTP.generateTOTPCodeString(secret, currentTime),
    testCode,
  );
  print('   Проверка текущего времени: $isValidCurrent');

  // Проверяем код для предыдущего времени
  final isValidPrevious = OTP.constantTimeVerification(
    OTP.generateTOTPCodeString(secret, currentTime - 30000),
    testCode,
  );
  print('   Проверка предыдущего времени: $isValidPrevious');

  // Проверяем код для следующего времени
  final isValidNext = OTP.constantTimeVerification(
    OTP.generateTOTPCodeString(secret, currentTime + 30000),
    testCode,
  );
  print('   Проверка следующего времени: $isValidNext');

  print('\n4. Тест с реальным секретом:');

  // Тест 4: Используем реальный секрет из вашего примера
  final realSecret = 'RMXP4NYUPEDFDZIF4FMIYIAZ7IJAPRM2';
  final realCurrentTime = DateTime.now().millisecondsSinceEpoch;

  // Генерируем код для реального секрета
  final realCode = OTP.generateTOTPCodeString(realSecret, realCurrentTime);
  print('   Реальный секрет: $realSecret');
  print('   Текущее время: $realCurrentTime');
  print('   Сгенерированный код: $realCode');

  // Проверяем, что код проходит проверку
  final isRealValid = OTP.constantTimeVerification(
    OTP.generateTOTPCodeString(realSecret, realCurrentTime),
    realCode,
  );
  print('   Проверка сгенерированного кода: $isRealValid');

  // Проверяем коды для соседних интервалов
  final realPreviousCode = OTP.generateTOTPCodeString(
    realSecret,
    realCurrentTime - 30000,
  );
  final realNextCode = OTP.generateTOTPCodeString(
    realSecret,
    realCurrentTime + 30000,
  );

  print('   Предыдущий код: $realPreviousCode');
  print('   Следующий код: $realNextCode');

  final isRealPreviousValid = OTP.constantTimeVerification(
    realPreviousCode,
    realCode,
  );
  final isRealNextValid = OTP.constantTimeVerification(realNextCode, realCode);

  print('   Проверка предыдущего кода: $isRealPreviousValid');
  print('   Проверка следующего кода: $isRealNextValid');

  print('\n5. Тест с разными секретами:');

  // Тест 5: Сравнение кодов для разных секретов
  final secret1 = 'RMXP4NYUPEDFDZIF4FMIYIAZ7IJAPRM2';
  final secret2 = 'AAY3OFHJ2Q7LARTIMDQCDAGKGH3IQ735';

  final code1 = OTP.generateTOTPCodeString(secret1, currentTime);
  final code2 = OTP.generateTOTPCodeString(secret2, currentTime);

  print('   Секрет 1: $secret1');
  print('   Секрет 2: $secret2');
  print('   Код 1: $code1');
  print('   Код 2: $code2');
  print('   Коды разные: $code1 != $code2');

  print('\n=== Тест завершен ===');
}
