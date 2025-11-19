import 'dart:core';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';

/// Класс для хранения пары ключей RSA.
/// n — модуль (произведение двух простых чисел),
/// e — открытая экспонента,
/// d — закрытая экспонента.
class RSAKeyPair {
  final BigInt n; // Модуль (n = p * q)
  final BigInt e; // Открытая экспонента
  final BigInt d; // Закрытая экспонента

  /// Конструктор для инициализации всех параметров ключа.
  RSAKeyPair(this.n, this.e, this.d);
}

/// Быстрое возведение в степень по модулю.
BigInt modPow(BigInt base, BigInt exp, BigInt mod) => base.modPow(exp, mod);

/// Наибольший общий делитель (алгоритм Евклида).
BigInt gcd(BigInt a, BigInt b) => b == BigInt.zero ? a : gcd(b, a % b);

/// Модульная мультипликативная инверсия (расширенный алгоритм Евклида).
BigInt modInverse(BigInt a, BigInt m) {
  BigInt m0 = m, t, q;
  BigInt x0 = BigInt.zero, x1 = BigInt.one;
  if (m == BigInt.one) return BigInt.zero;
  while (a > BigInt.one) {
    q = a ~/ m;
    t = m;
    m = a % m;
    a = t;
    t = x0;
    x0 = x1 - q * x0;
    x1 = t;
  }
  if (x1 < BigInt.zero) x1 += m0;
  return x1;
}

/// Генерация случайного BigInt заданной битовой длины.
BigInt randomBigInt(int bitLength) {
  final rnd = Random.secure();
  final bytes = (bitLength / 8).ceil();
  final data = Uint8List(bytes);
  for (int i = 0; i < bytes; i++) {
    data[i] = rnd.nextInt(256);
  }

  // Преобразуем байты в BigInt
  var x = BigInt.parse(
    data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );

  // Гарантируем нужную битовую длину и нечётность
  x |= BigInt.one << (bitLength - 1);
  if (x.isEven) x += BigInt.one;
  return x;
}

/// Проверка числа на простоту (тест Миллера-Рабина).
bool isProbablePrime(BigInt n, {int k = 40}) {
  if (n < BigInt.from(2)) return false;
  if (n == BigInt.two || n == BigInt.from(3)) return true;
  if (n.isEven) return false;
  BigInt d = n - BigInt.one;
  int r = 0;
  while (d.isEven) {
    d ~/= BigInt.two;
    r++;
  }
  final rnd = Random.secure();
  for (int i = 0; i < k; i++) {
    BigInt a = BigInt.from(2 + rnd.nextInt(1 << 32)) % (n - BigInt.two);
    BigInt x = modPow(a, d, n);
    if (x == BigInt.one || x == n - BigInt.one) continue;
    bool cont = false;
    for (int j = 1; j < r; j++) {
      x = modPow(x, BigInt.two, n);
      if (x == n - BigInt.one) {
        cont = true;
        break;
      }
    }
    if (cont) continue;
    return false;
  }
  return true;
}

/// [не актуален] Генерация большого простого числа заданной битовой длины. 
BigInt generatePrime(int bitLength) {
  while (true) {
    final cand = randomBigInt(bitLength);
    if (isProbablePrime(cand)) return cand;
  }
}

/// [не актуален] Генерация пары ключей RSA заданной битовой длины.
RSAKeyPair generateRSAKeyPair(int bitLength) {
  final e = BigInt.from(65537); // Стандартная открытая экспонента
  BigInt p, q, phi, d, n;
  do {
    p = generatePrime(bitLength ~/ 2);
    q = generatePrime(bitLength ~/ 2);
    n = p * q;
    phi = (p - BigInt.one) * (q - BigInt.one);
  } while (gcd(e, phi) != BigInt.one);
  d = modInverse(e, phi);
  print(p);
  print(q);
  return RSAKeyPair(n, e, d);
}

/// Шифрование сообщения m с помощью открытого ключа.
BigInt encrypt(BigInt m, RSAKeyPair key) => modPow(m, key.e, key.n);

/// Расшифровка сообщения c с помощью закрытого ключа.
BigInt decrypt(BigInt c, RSAKeyPair key) => modPow(c, key.d, key.n);

/// Генерация пары ключей RSA из заранее сгенерированных простых чисел, хранящихся в файлах.
Future<RSAKeyPair> generateRSAKeyPairFromFiles(
  String pPath,
  String qPath,
) async {
  final e = BigInt.from(65537);
  final p = await readPrime(pPath);
  final q = await readPrime(qPath);
  final n = p * q;
  final phi = (p - BigInt.one) * (q - BigInt.one);
  final d = modInverse(e, phi);
  return RSAKeyPair(n, e, d);
}

/// Чтение большого простого числа из файла.
/// Фильтрует только видимые ASCII-цифры, чтобы избежать ошибок декодирования.
Future<BigInt> readPrime(String path) async {
  final bytes = await File(path).readAsBytes();
  // Преобразуем только видимые ASCII-цифры
  final str = String.fromCharCodes(bytes.where((b) => b >= 0x30 && b <= 0x39));
  return BigInt.parse(str);
}
