import 'dart:typed_data';
import 'sbox.dart';
import 'ltransform.dart';
import 'utils.dart';

// Генерация констант C
Uint8List generateC(int iteration) {
  Uint8List c = Uint8List(16);
  // В векторе (a15...a0) число итерации ставится в a0 (последний байт массива)
  c[15] = iteration; 
  return lTransform(c);
}

// Раунд сети Фейстеля для генерации ключей
Uint8List f(Uint8List a, Uint8List b, int iteration) {
  Uint8List c = generateC(iteration);
  Uint8List temp = xorBlocks(a, c);
  temp = subBytes(temp);
  temp = lTransform(temp);
  return xorBlocks(temp, b);
}

class Kuznechik {
  static const int blockSize = 16;
  final Uint8List masterKey; 
  late List<Uint8List> roundKeys;

  Kuznechik(this.masterKey) {
    assert(masterKey.length == 32);
    _generateRoundKeys();
  }

  void _generateRoundKeys() {
    Uint8List k1 = Uint8List.fromList(masterKey.sublist(0, 16));
    Uint8List k2 = Uint8List.fromList(masterKey.sublist(16, 32));

    List<Uint8List> keys = [];
    // Добавляем первую пару ключей (K1, K2)
    keys.add(k1);
    keys.add(k2);

    // 32 раунда сети Фейстеля для генерации остальных 8 ключей
    // Генерируются парами (всего 4 пары по 8 итераций)
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 8; j++) {
        // Номер итерации: 1..32
        int iterNum = i * 8 + j + 1;
        Uint8List temp = f(k1, k2, iterNum);
        
        // Сдвиг пары (k1, k2) -> (k2, temp)
        k2 = k1; // Старый k1 уходит в k2 (но по логике Фейстеля: k1=temp, k2=old_k1)
                 // В ГОСТе: (A, B) -> (L(S(A+C))+B, A). 
                 // То есть правая часть (B) становится левой (A), а новая вычисляется.
        k1 = temp;
      }
      keys.add(k1);
      keys.add(k2);
    }

    roundKeys = keys;
  }

  Uint8List encryptBlock(Uint8List block) {
    assert(block.length == blockSize);
    Uint8List b = Uint8List.fromList(block);

    // 9 Раундов (X -> S -> L)
    for (int i = 0; i < 9; i++) {
      b = xorBlocks(b, roundKeys[i]);
      b = subBytes(b);
      b = lTransform(b);
    }

    // Последний 10-й раунд (только X)
    b = xorBlocks(b, roundKeys[9]);

    return b;
  }

  Uint8List decryptBlock(Uint8List block) {
    assert(block.length == blockSize);
    Uint8List b = Uint8List.fromList(block);

    // Обратный порядок: сначала снимаем последний ключ
    b = xorBlocks(b, roundKeys[9]);

    // 9 Обратных раундов (invL -> invS -> X)
    for (int i = 8; i >= 0; i--) {
      b = invLTransform(b);
      b = invSubBytes(b);
      b = xorBlocks(b, roundKeys[i]);
    }

    return b;
  }
}