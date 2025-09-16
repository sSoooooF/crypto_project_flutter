import 'dart:core';
import 'dart:math';
import 'dart:typed_data';

class RSAKeyPair {
  final BigInt n;
  final BigInt e;
  final BigInt d;

  RSAKeyPair(this.n, this.e, this.d);
}

BigInt modPow(BigInt base, BigInt exp, BigInt mod) => base.modPow(exp, mod);

BigInt gcd(BigInt a, BigInt b) => b == BigInt.zero ? a : gcd(b, a % b);

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

BigInt randomBigInt(int bitLength) {
  final rnd = Random.secure();
  final bytes = (bitLength / 8).ceil();
  final data = Uint8List(bytes);
  for (int i = 0; i < bytes; i++) {
    data[i] = rnd.nextInt(256);
  }

  var x = BigInt.parse(
    data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );

  x |= BigInt.one << (bitLength - 1);
  if (x.isEven) x += BigInt.one;
  return x;
}

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
      if (x == n - BigInt.one) { cont = true; break; }
    }
    if (cont) continue;
    return false;
  }
  return true;
}

BigInt generatePrime(int bitLength) {
  while (true) {
    final cand = randomBigInt(bitLength);
    if (isProbablePrime(cand)) return cand;
  }
}

// 
RSAKeyPair generateRSAKeyPair(int bitLength) {
  final e = BigInt.from(65537);
  BigInt p, q, phi, d, n;
  do {
    p = generatePrime(bitLength ~/ 2);
    q = generatePrime(bitLength ~/ 2);
    n = p * q;
    phi = (p - BigInt.one) * (q - BigInt.one);
  } while (gcd(e, phi) != BigInt.one);
  d = modInverse(e, phi);
  return RSAKeyPair(n, e, d);
}

BigInt encrypt(BigInt m, RSAKeyPair key) => modPow(m, key.e, key.n);
BigInt decrypt(BigInt c, RSAKeyPair key) => modPow(c, key.d, key.n);
