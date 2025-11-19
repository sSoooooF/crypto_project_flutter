import 'dart:typed_data';
import 'dart:math';
import 'tables.dart';

/// Реализация хэш-функции Стрибог (GOST R 34.11-2012)
/// Использует 512-битный режим (Streebog-512)
class Streebog512 {
  static const int BLOCK_SIZE = 64; // 512 bits
  static const int HASH_SIZE = 64; // 512 bits

  // ----------------------------------------------------
  // --- КОНСТАНТЫ ИЗ tables.dart (S-BOX и C_i) ---
  // ----------------------------------------------------

  // S-BOX (Стандартный GOST R 34.11-2012)

  late Uint8List _hash;
  late Uint8List _buffer;
  int _length = 0;
  int _processedBytes = 0;

  static const int _rounds = 12;

  Streebog512() {
    _buffer = Uint8List(BLOCK_SIZE);
    reset();
  }

  void reset() {
    // Начальное значение H0 для 512 бит - 0x00...00
    _hash = Uint8List(HASH_SIZE);
    _length = 0;
    _processedBytes = 0;
  }

  // --- Вспомогательные функции криптографических слоев ---

  static Uint8List _xor(Uint8List a, Uint8List b) {
    var result = Uint8List(BLOCK_SIZE);
    for (int i = 0; i < BLOCK_SIZE; i++) {
      result[i] = a[i] ^ b[i];
    }
    return result;
  }

  /// Преобразование S (Substitution/Замена)
  Uint8List _s(Uint8List a) {
    var result = Uint8List(BLOCK_SIZE);
    for (int i = 0; i < BLOCK_SIZE; i++) {
      result[i] = S_BOX[a[i]]; // Использование S_BOX
    }
    return result;
  }

  /// Преобразование P (Permutation/Перестановка)
  Uint8List _p(Uint8List a) {
    var result = Uint8List(BLOCK_SIZE);
    // Использование таблицы T для перестановки
    for (int i = 0; i < BLOCK_SIZE; i++) {
      result[T[i]] = a[i];
    }
    return result;
  }

  // Функция умножения в конечном поле GF(2^8) по модулю P(x) = x^8 + x^7 + x^6 + x + 1 (0x1C3)
  // Функция умножения в конечном поле GF(2^8) по модулю P(x) = x^8 + x^7 + x^6 + x + 1 (0x1C3)
  int _gmul(int a, int b) {
    int p = 0x1C3;
    int product = 0;
    int polyA = a & 0xFF; // Убеждаемся, что a - 8-битное

    for (int i = 0; i < 8; i++) {
      // 1. Если бит b[i] установлен, прибавляем (XOR) polyA к результату
      if ((b & 1) != 0) {
        product ^= polyA;
      }

      // 2. Умножаем polyA на x (сдвиг влево)
      // 3. Если до сдвига старший бит был 1, выполняем редукцию (XOR с P(x))
      if ((polyA & 0x80) != 0) {
        polyA = (polyA << 1) ^ p;
      } else {
        polyA <<= 1;
      }

      // 4. Переходим к следующему биту b
      b >>= 1;
    }
    return product & 0xFF;
  }

  /// Преобразование L (Linear Transformation/Линейное преобразование)
  Uint8List _l(Uint8List a) {
    var result = Uint8List(BLOCK_SIZE);
    // Для каждого байта результата (result[i])
    for (int i = 0; i < BLOCK_SIZE; i++) {
      int row = MATRIX_A[i]; // Строка матрицы A (BigInt/64 бита)
      int newByte = 0;

      // Умножение row на вектор a (64 байта) в GF(2^8)
      for (int j = 0; j < BLOCK_SIZE; j++) {
        // Извлечение j-го коэффициента из строки MATRIX_A[i]
        // Коэффициенты хранятся в Little Endian порядке
        int coeff = (row >> (j * 8)) & 0xFF;

        // Умножение a[j] на коэффициент в GF(2^8) и XOR-суммирование
        newByte ^= _gmul(a[j], coeff);
      }
      result[i] = newByte;
    }
    return result;
  }

  Uint8List _e(Uint8List k, Uint8List m) {
    // E_K(m) = L(P(S(m \oplus k)))
    Uint8List state = _xor(m, k);
    state = _s(state);
    state = _p(state);
    state = _l(state);
    return state;
  }

  /// Функция сжатия G_N(H, M)
  Uint8List _g(Uint8List n, Uint8List h, Uint8List m) {
    Uint8List k = Uint8List.fromList(n); // Начальный ключ k_0 = N

    // Генерация раундовых ключей и выполнение E-функции
    for (int i = 0; i < _rounds; i++) {
      // Использование предопределенных констант C_i
      Uint8List c_i = Uint8List.fromList(C[i]);

      // Генерация раундового ключа: K_i = L(P(S(K_{i-1} \oplus C_i)))
      Uint8List next_k_i = _xor(k, c_i);
      next_k_i = _s(next_k_i);
      next_k_i = _p(next_k_i);
      k = _l(next_k_i);
    }

    // Финальная часть функции сжатия G:
    // G(N, H, m) = E_K(m) \oplus H \oplus m
    Uint8List e_result = _e(k, m);
    Uint8List temp = _xor(e_result, h);
    return _xor(temp, m);
  }

  /// Обновляет счетчик N (длину)
  Uint8List _updateN(Uint8List currentN, int blockLength) {
    // Добавление blockLength (64 байта) к текущему значению N
    // N хранится в Little-Endian
    int carry = blockLength;
    Uint8List newN = Uint8List.fromList(currentN);

    for (int i = 0; i < newN.length; i++) {
      carry += newN[i];
      newN[i] = carry & 0xFF;
      carry >>= 8;
      if (carry == 0 && i < 8) break; // Оптимизация
    }
    return newN;
  }

  /// Обрабатывает один блок данных
  void _processBlock(Uint8List block) {
    // N - счетчик длины, который накапливает длину обработанных блоков.
    // Для Streebog N - это 512-битное число, обновляемое на 512.
    // (В оригинальном коде N был заглушкой)

    Uint8List N = Uint8List(BLOCK_SIZE);

    // В Streebog N не обновляется в цикле, он передается в G как счетчик,
    // который равен длине сообщения до текущего блока.

    // Вместо этого, согласно стандарту, G вызывается с N, которое является
    // кумулятивной длиной.

    // В простом режиме N в G должен быть *кумулятивным* счетчиком.
    // Поскольку у нас нет кумулятивного N, мы используем заглушку N=0 для первого прохода
    // и полагаемся на финальную обработку длины.

    // Корректная реализация G(N, H, M): N должно быть обновленной суммой длин.

    // Для простоты, имитируем N, как кумулятивную длину, преобразованную в 512-битный массив (Little-Endian)
    Uint8List cumulativeN = Uint8List(BLOCK_SIZE);
    int cumulativeLengthBits = _processedBytes * 8;
    for (int i = 0; i < 8; i++) {
      cumulativeN[i] = (cumulativeLengthBits >> (i * 8)) & 0xFF;
    }

    _hash = _g(cumulativeN, _hash, block);
    _processedBytes += BLOCK_SIZE;
  }

  /// Добавляет данные для хэширования
  void update(Uint8List data) {
    int offset = 0;
    while (offset < data.length) {
      int bytesToCopy = min(BLOCK_SIZE - _length, data.length - offset);
      _buffer.setRange(_length, _length + bytesToCopy, data, offset);
      _length += bytesToCopy;
      offset += bytesToCopy;

      if (_length == BLOCK_SIZE) {
        _processBlock(_buffer);
        _length = 0;
      }
    }
  }

  /// Завершает хэширование и возвращает результат
  Uint8List digest() {
    // 1. Padding (Дополнение)
    Uint8List finalBlock = Uint8List(BLOCK_SIZE);
    finalBlock.setRange(0, _length, _buffer.sublist(0, _length));

    // Первый байт дополнения - 0x01, остальные - 0x00
    finalBlock[_length] = 0x01;
    for (int i = _length + 1; i < BLOCK_SIZE; i++) {
      finalBlock[i] = 0x00;
    }

    // Обработка последнего дополненного блока: G(0, H_temp, M_padded)
    Uint8List zeroN = Uint8List(BLOCK_SIZE);
    _hash = _g(zeroN, _hash, finalBlock);

    // Общая длина сообщения в битах (Little Endian, 512 бит)
    int totalBitLength = (_processedBytes + _length) * 8;
    Uint8List L = Uint8List(BLOCK_SIZE);
    for (int i = 0; i < 8; i++) {
      L[i] = (totalBitLength >> (i * 8)) & 0xFF;
    }

    // 2. Финальное сжатие длины: H = G(L, H, 0)
    Uint8List zeroBlock = Uint8List(BLOCK_SIZE);
    _hash = _g(L, _hash, zeroBlock);

    // Возвращаем H (512 бит)
    return _hash;
  }
}
