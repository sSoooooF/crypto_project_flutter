import 'dart:typed_data';

/// Умножение в поле Галуа GF(2^8)
/// Полином ГОСТ: x^8 + x^7 + x^6 + x + 1 (0xC3)
int gfMul(int a, int b) {
  int p = 0;
  for (int i = 0; i < 8; i++) {
    if ((b & 1) != 0) {
      p ^= a;
    }
    bool hiBitSet = (a & 0x80) != 0;
    a = (a << 1) & 0xFF; // Сдвигаем и держим в рамках байта
    if (hiBitSet) {
      a ^= 0xC3; // XOR с полиномом (младшие 8 бит от 0x11C3)
    }
    b >>= 1;
  }
  return p & 0xFF;
}

Uint8List xorBlocks(Uint8List a, Uint8List b) {
  assert(a.length == b.length);
  // Создаем новый список, чтобы не мутировать входные данные
  return Uint8List.fromList(List.generate(a.length, (i) => a[i] ^ b[i]));
}