// streebog_test.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';

import '../core/streebog/streebog.dart';

// Вспомогательная функция для преобразования шестнадцатеричной строки в Uint8List
Uint8List hexToBytes(String hex) {
  var bytes = <int>[];
  for (int i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return Uint8List.fromList(bytes);
}

// Вспомогательная функция для преобразования Uint8List в шестнадцатеричную строку
String bytesToHex(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

void main() {
  group('Streebog-512 (GOST R 34.11-2012) Test Vectors', () {
    // --- Тест 1: Пустая строка (M = "") ---
    // Длина: 0 бит
    const String emptyMessage = "";
    // Эталонное значение (512-bit hash)
    const String expectedEmptyHash =
        '73C6F78C5314781A8106D94101A186D4AC64F0A91D906E5D1D50A656B6F9A95C'
        'F427878891484C9550D94B6D835F53860C72EB952B9EAE9C009943B70D6D0357';

    test('Empty message ("")', () {
      var streebog = Streebog512();
      streebog.update(Uint8List.fromList(utf8.encode(emptyMessage)));
      var actualHash = bytesToHex(streebog.digest());

      print('Тест 1 (Пустая строка):');
      print('Ожидаемый хэш: $expectedEmptyHash');
      print('Фактический хэш: $actualHash');

      expect(actualHash, equalsIgnoringCase(expectedEmptyHash));
    });

    // --- Тест 2: Сообщение длиной 512 бит (1 блок) ---
    // M = 0x00...00 (64 байта нулей)
    const String message512Bits =
        '0000000000000000000000000000000000000000000000000000000000000000'
        '0000000000000000000000000000000000000000000000000000000000000000';
    // Эталонное значение
    const String expected512BitsHash =
        '25E9CECA316BC23DE735878AC9B545C68A651786522E9B23133649E819665B33'
        '9263628D8A10887A84351325F30C4178FCF5502F71953E2611A9908F8130B4A7';

    test('512-bit zero message (64 bytes)', () {
      var streebog = Streebog512();
      streebog.update(hexToBytes(message512Bits));
      var actualHash = bytesToHex(streebog.digest());

      print('\nТест 2 (64 байта 0x00):');
      print('Ожидаемый хэш: $expected512BitsHash');
      print('Фактический хэш: $actualHash');

      expect(actualHash, equalsIgnoringCase(expected512BitsHash));
    });

    // --- Тест 3: Сообщение с одним символом ---
    // M = "a"
    const String messageA = "a";
    // Эталонное значение
    const String expectedHashA =
        '03C934E2F7F2309C5C6019A8256DD4458D548C9E27346A2A44B65B5406C64966'
        'A8A6A4E913312019777926A76E84C7B846B500C19B4C025114F26F8087961A37';

    test('Single character message ("a")', () {
      var streebog = Streebog512();
      streebog.update(Uint8List.fromList(utf8.encode(messageA)));
      var actualHash = bytesToHex(streebog.digest());

      print('\nТест 3 ("a"):');
      print('Ожидаемый хэш: $expectedHashA');
      print('Фактический хэш: $actualHash');

      expect(actualHash, equalsIgnoringCase(expectedHashA));
    });

    // --- Тест 4: Длинное сообщение (Тест стандарта) ---
    // M = 1024 символов '0'
    String message1024Zeroes = '0' * 1024;
    // Эталонное значение
    const String expectedHash1024Zeroes =
        '4078D1E6CE10714E2F13812C45512B71038D1C7F5D15E4C471E6955D1117562D'
        '0727DD8477028D5F60B8881A28A6114F4D67756B7504351D0846114A536F8522';

    test('Long message (1024 x "0")', () {
      var streebog = Streebog512();
      streebog.update(Uint8List.fromList(utf8.encode(message1024Zeroes)));
      var actualHash = bytesToHex(streebog.digest());

      print('\nТест 4 (1024 x "0"):');
      print('Ожидаемый хэш: $expectedHash1024Zeroes');
      print('Фактический хэш: $actualHash');

      expect(actualHash, equalsIgnoringCase(expectedHash1024Zeroes));
    });
  });
}
