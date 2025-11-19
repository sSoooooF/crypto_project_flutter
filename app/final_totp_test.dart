import 'dart:math';
import 'package:otp/otp.dart';

void main() {
  print('=== Финальный тест TOTP ===\n');

  // Тест 1: Проверка базовой генерации кодов
  print('1. Базовая генерация кодов:');

  final testSecret = 'JBSWY3DPEHPK3PXP';
  final currentTime = DateTime.now().millisecondsSinceEpoch;

  print('Тестовый секрет: $testSecret');
  print('Текущее время: $currentTime');

  // Генерируем код
  final code = OTP.generateTOTPCodeString(testSecret, currentTime);
  print('Сгенерированный код: $code');

  // Проверяем, что код проходит проверку
  final isValid = OTP.constantTimeVerification(
    OTP.generateTOTPCodeString(testSecret, currentTime),
    code,
  );
  print('Проверка кода: $isValid');

  // Тест 2: Используем секрет из вашего примера
  print('\n2. Тест с реальным секретом:');

  final realSecret = 'RMXP4NYUPEDFDZIF4FMIYIAZ7IJAPRM2';
  final realCurrentTime = DateTime.now().millisecondsSinceEpoch;

  print('Реальный секрет: $realSecret');
  print('Текущее время: $realCurrentTime');
  print(
    'Текущее время (читабельное): ${DateTime.fromMillisecondsSinceEpoch(realCurrentTime)}',
  );

  // Генерируем код для реального секрета
  final realCode = OTP.generateTOTPCodeString(realSecret, realCurrentTime);
  print('Сгенерированный код: $realCode');

  // Проверяем, что код проходит проверку
  final isRealValid = OTP.constantTimeVerification(
    OTP.generateTOTPCodeString(realSecret, realCurrentTime),
    realCode,
  );
  print('Проверка кода: $isRealValid');

  // Тест 3: Проверка кодов для разных временных интервалов
  print('\n3. Проверка кодов для разных временных интервалов:');

  final intervals = [
    realCurrentTime - 60000, // 1 минута назад
    realCurrentTime - 30000, // 30 секунд назад
    realCurrentTime, // сейчас
    realCurrentTime + 30000, // 30 секунд вперед
    realCurrentTime + 60000, // 1 минута вперед
  ];

  for (int i = 0; i < intervals.length; i++) {
    final time = intervals[i];
    final intervalCode = OTP.generateTOTPCodeString(realSecret, time);
    final timeStr = DateTime.fromMillisecondsSinceEpoch(time).toIso8601String();
    print('  Интервал $i ($timeStr): $intervalCode');
  }

  // Тест 4: Проверка, что коды для разных секретов разные
  print('\n4. Проверка кодов для разных секретов:');

  final secret1 = 'RMXP4NYUPEDFDZIF4FMIYIAZ7IJAPRM2';
  final secret2 = 'AAY3OFHJ2Q7LARTIMDQCDAGKGH3IQ735';

  final code1 = OTP.generateTOTPCodeString(secret1, realCurrentTime);
  final code2 = OTP.generateTOTPCodeString(secret2, realCurrentTime);

  print('Секрет 1: $secret1');
  print('Секрет 2: $secret2');
  print('Код 1: $code1');
  print('Код 2: $code2');
  print('Коды разные: $code1 != $code2');

  // Тест 5: Проверка, что коды для одного и того же секрета одинаковы
  print('\n5. Проверка, что коды для одного и того же секрета одинаковы:');

  final sameCode1 = OTP.generateTOTPCodeString(secret1, realCurrentTime);
  final sameCode2 = OTP.generateTOTPCodeString(secret1, realCurrentTime);

  print('Код 1: $sameCode1');
  print('Код 2: $sameCode2');
  print('Коды одинаковы: $sameCode1 == $sameCode2');

  // Тест 6: Проверка временного окна
  print('\n6. Проверка временного окна:');

  final windowCurrentCode = OTP.generateTOTPCodeString(
    secret1,
    realCurrentTime,
  );
  final windowPreviousCode = OTP.generateTOTPCodeString(
    secret1,
    realCurrentTime - 30000,
  );
  final windowNextCode = OTP.generateTOTPCodeString(
    secret1,
    realCurrentTime + 30000,
  );

  print('Текущий код: $windowCurrentCode');
  print('Предыдущий код: $windowPreviousCode');
  print('Следующий код: $windowNextCode');

  final windowCurrentValid = OTP.constantTimeVerification(
    windowCurrentCode,
    windowCurrentCode,
  );
  final windowPreviousValid = OTP.constantTimeVerification(
    windowPreviousCode,
    windowCurrentCode,
  );
  final windowNextValid = OTP.constantTimeVerification(
    windowNextCode,
    windowCurrentCode,
  );

  print('Текущий код верен: $windowCurrentValid');
  print('Предыдущий код верен: $windowPreviousValid');
  print('Следующий код верен: $windowNextValid');

  print('\n=== Тест завершен ===');
}
