import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:otp/otp.dart';

void main() {
  // Generate a random TOTP secret (32 characters, base32 encoded)
  final random = DateTime.now().millisecondsSinceEpoch.toString();
  final bytes = utf8.encode(random + 'admin_secret_salt');
  final hash = sha256.convert(bytes);
  final secret = base32Encode(hash.bytes).substring(0, 32).toUpperCase();

  print('═══════════════════════════════════════════════════════');
  print('АДМИН ПОЛЬЗОВАТЕЛЬ - УЧЕТНЫЕ ДАННЫЕ:');
  print('═══════════════════════════════════════════════════════');
  print('Логин: admin');
  print('Пароль: admin123');
  print('TOTP секрет: $secret');
  print('QR-код URI: otpauth://totp/CryptoApp:admin?algorithm=SHA1&digits=6&secret=$secret&issuer=CryptoApp&period=30');
  print('═══════════════════════════════════════════════════════');
  print('');
  print('Примечание: Этот секрет будет использован при создании');
  print('админ пользователя при запуске приложения.');
  print('Если админ уже существует, используйте существующий секрет.');
}

String base32Encode(List<int> bytes) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final buffer = StringBuffer();
  int bits = 0;
  int value = 0;

  for (final byte in bytes) {
    value = (value << 8) | byte;
    bits += 8;

    while (bits >= 5) {
      buffer.write(alphabet[(value >> (bits - 5)) & 31]);
      bits -= 5;
    }
  }

  if (bits > 0) {
    buffer.write(alphabet[(value << (5 - bits)) & 31]);
  }

  return buffer.toString();
}

