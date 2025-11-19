import 'dart:math';
import 'package:otp/otp.dart';

void main() {
  print('=== Простой тест TOTP ===\n');

  // Используем секрет из вашего примера
  final secret = 'RMXP4NYUPEDFDZIF4FMIYIAZ7IJAPRM2';
  final currentTime = DateTime.now().millisecondsSinceEpoch;

  print('Секрет: $secret');
  print('Текущее время: $currentTime');
  print(
    'Текущее время (читабельное): ${DateTime.fromMillisecondsSinceEpoch(currentTime)}',
  );

  // Генерируем код для текущего времени
  final generatedCode = OTP.generateTOTPCodeString(secret, currentTime);
  print('Сгенерированный код: $generatedCode');

  // Проверяем, что код проходит проверку
  final isValid = OTP.constantTimeVerification(
    OTP.generateTOTPCodeString(secret, currentTime),
    generatedCode,
  );
  print('Проверка сгенерированного кода: $isValid');

  // Проверяем коды для соседних интервалов
  final previousTime = currentTime - 30000;
  final nextTime = currentTime + 30000;

  final previousCode = OTP.generateTOTPCodeString(secret, previousTime);
  final nextCode = OTP.generateTOTPCodeString(secret, nextTime);

  print('\nПредыдущий интервал:');
  print('  Время: $previousTime');
  print(
    '  Время (читабельное): ${DateTime.fromMillisecondsSinceEpoch(previousTime)}',
  );
  print('  Код: $previousCode');
  print(
    '  Проверка: ${OTP.constantTimeVerification(previousCode, generatedCode)}',
  );

  print('\nСледующий интервал:');
  print('  Время: $nextTime');
  print(
    '  Время (читабельное): ${DateTime.fromMillisecondsSinceEpoch(nextTime)}',
  );
  print('  Код: $nextCode');
  print('  Проверка: ${OTP.constantTimeVerification(nextCode, generatedCode)}');

  // Проверяем, что коды для разных интервалов действительно разные
  print('\nСравнение кодов:');
  print('  Текущий код: $generatedCode');
  print('  Предыдущий код: $previousCode');
  print('  Следующий код: $nextCode');
  print(
    '  Все коды разные: $generatedCode != $previousCode && $generatedCode != $nextCode',
  );

  // Тест с неправильным кодом
  print('\nТест с неправильным кодом:');
  final wrongCode = '123456';
  final isWrongValid = OTP.constantTimeVerification(
    OTP.generateTOTPCodeString(secret, currentTime),
    wrongCode,
  );
  print('Неправильный код: $wrongCode');
  print('Проверка: $isWrongValid');

  print('\n=== Тест завершен ===');
}
