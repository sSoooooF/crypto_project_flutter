import '../../core/rsa/rsa.dart';
import 'package:test/test.dart';
import 'dart:convert';

void main() {
  group('RSA 32768-bit Tests', () {
    test('Generate 32768-bit RSA key pair from files', () async {
      print('Загрузка 32768-битных простых чисел из файлов...');
      final keyPair = await generateRSAKeyPairFromFiles(
        'core/rsa/prime1.txt',
        'core/rsa/prime2.txt',
      );

      print('Генерация ключей завершена.');
      print('n bit length: ${keyPair.n.bitLength}');
      print('e: ${keyPair.e}');
      print('d bit length: ${keyPair.d.bitLength}');

      final messageStr = 'Test message for 32768-bit RSA';
      print('Original string: $messageStr');

      // Конвертация строки в BigInt
      final messageBytes = utf8.encode(messageStr);
      final messageInt = BigInt.parse(
        messageBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16,
      );

      // Шифруем
      final cipher = encrypt(messageInt, keyPair);
      print('Encrypted: ${cipher.toString().substring(0, 60)}...');

      // Дешифруем
      final decryptedInt = decrypt(cipher, keyPair);

      // Конвертация обратно в строку
      String decryptedStr = utf8.decode(
        List.generate(
          (decryptedInt.bitLength + 7) ~/ 8,
          (i) => ((decryptedInt >> (8 * ((decryptedInt.bitLength + 7) ~/ 8 - i - 1))) & BigInt.from(0xFF)).toInt(),
        ),
      );

      print('Decrypted string: $decryptedStr');
      expect(decryptedStr, equals(messageStr));
    });
  });
}