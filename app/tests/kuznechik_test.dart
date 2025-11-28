import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:app/core/Kuznyechik/kuznechik.dart';

void main() {
  test('Kuznechik encrypt/decrypt with GOST test vector', () {
    final key = Uint8List.fromList([
      0x88,
      0x99,
      0xAA,
      0xBB,
      0xCC,
      0xDD,
      0xEE,
      0xFF,
      0x00,
      0x11,
      0x22,
      0x33,
      0x44,
      0x55,
      0x66,
      0x77,
      0xFE,
      0xDC,
      0xBA,
      0x98,
      0x76,
      0x54,
      0x32,
      0x10,
      0x01,
      0x23,
      0x45,
      0x67,
      0x89,
      0xAB,
      0xCD,
      0xEF,
    ]);

    final plaintext = Uint8List.fromList([
      0x11,
      0x22,
      0x33,
      0x44,
      0x55,
      0x66,
      0x77,
      0x00,
      0xFF,
      0xEE,
      0xDD,
      0xCC,
      0xBB,
      0xAA,
      0x99,
      0x88,
    ]);

    final expectedCipher = Uint8List.fromList([
      0x7F,
      0x67,
      0x9D,
      0x90,
      0xBE,
      0xBC,
      0x24,
      0x30,
      0x5A,
      0x46,
      0x8D,
      0x42,
      0xB9,
      0xD4,
      0xED,
      0xCD,
    ]);

    final cipher = Kuznechik(key);

    final encrypted = cipher.encryptBlock(plaintext);
    final decrypted = cipher.decryptBlock(encrypted);

    expect(encrypted, equals(expectedCipher));
    expect(decrypted, equals(plaintext));
  });
}
