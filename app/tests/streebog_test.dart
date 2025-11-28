import 'dart:typed_data';

import 'package:test/test.dart';
import '../../core/streebog/streebog.dart';

void main() {
  group('Streebog 512-bit', () {
    test('Empty string', () {
      final st = Streebog(digestSize: 512);
      st.update(Uint8List(0));
      final hash = st.digest();
      expect(hash, equals([
        142, 149, 156, 175, 95, 70, 28, 42,
        127, 183, 144, 87, 155, 69, 83, 139,
        11, 32, 47, 205, 86, 108, 83, 139,
        158, 64, 101, 227, 103, 120, 111, 11,
        177, 49, 124, 218, 92, 91, 13, 160,
        52, 150, 94, 204, 103, 211, 90, 178,
        49, 194, 13, 17, 144, 145, 69, 85,
        118, 178, 46, 29, 245, 165, 113, 99
      ]));
    });

    test('"abc"', () {
      final st = Streebog(digestSize: 512);
      st.update(Uint8List.fromList('abc'.codeUnits));
      final hash = st.digest();
      expect(hash, equals([
        94, 60, 31, 30, 14, 84, 104, 48,
        77, 60, 127, 105, 91, 25, 124, 61,
        79, 30, 56, 164, 157, 134, 227, 7,
        85, 163, 118, 77, 166, 21, 197, 48,
        180, 212, 192, 136, 83, 121, 38, 102,
        121, 72, 145, 6, 45, 200, 254, 212,
        248, 41, 47, 205, 212, 191, 182, 36,
        194, 183, 2, 36, 138, 106, 122, 57
      ]));
    });
  });

  group('Streebog 256-bit', () {
    test('Empty string', () {
      final st = Streebog(digestSize: 256);
      st.update(Uint8List(0));
      final hash = st.digest();
      expect(hash, equals([
        0x3f, 0x45, 0x6f, 0x7e, 0xe0, 0x54, 0xf3, 0x07,
        0x29, 0x87, 0x61, 0x3c, 0x6d, 0x9a, 0x3f, 0xb1,
        0x7f, 0x6b, 0xb0, 0x1d, 0x92, 0x7a, 0x6d, 0x1e,
        0xf4, 0x2b, 0x2a, 0x19, 0x7d, 0x55, 0x63, 0x63
      ]));
    });

    test('"abc"', () {
      final st = Streebog(digestSize: 256);
      st.update(Uint8List.fromList('abc'.codeUnits));
      final hash = st.digest();
      expect(hash, equals([
        0xBA, 0xA5, 0x2C, 0x8E, 0x3C, 0x81, 0x54, 0x27,
        0x1B, 0xAA, 0xB0, 0xF0, 0x2C, 0x6E, 0xC0, 0x8F,
        0xDE, 0x65, 0x48, 0x39, 0x9E, 0xFC, 0x17, 0x9A,
        0x37, 0x62, 0x25, 0x82, 0x95, 0x8A, 0x3B, 0x9E
      ]));
    });
  });
}
