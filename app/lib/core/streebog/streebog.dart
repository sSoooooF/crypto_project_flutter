import 'dart:typed_data';
import 'tables.dart';

class Streebog {
  final int digestSize;
  late Uint8List _h, _n, _sigma;
  final Uint8List _buffer = Uint8List(64);
  int _bufferLen = 0;
  int _totalBytes = 0;

  Streebog({this.digestSize = 512}) {
    _h = Uint8List(64);
    _n = Uint8List(64);
    _sigma = Uint8List(64);

    if (digestSize == 512) {
      _h.fillRange(0, 64, 0x00);
    } else {
      _h.fillRange(0, 64, 0x01);
    }
  }

  void update(Uint8List data) {
    _totalBytes += data.length;
    int offset = 0;

    while (offset < data.length) {
      int copyLen = (64 - _bufferLen).clamp(0, data.length - offset);
      _buffer.setRange(_bufferLen, _bufferLen + copyLen, data, offset);
      _bufferLen += copyLen;
      offset += copyLen;

      if (_bufferLen == 64) {
        _processBlock(_buffer);
        _bufferLen = 0;
      }
    }
  }

  Uint8List digest() {
    // padding
    Uint8List block = Uint8List(64);
    block.setRange(0, _bufferLen, _buffer);
    block[_bufferLen] = 0x01;
    for (int i = _bufferLen + 1; i < 64; i++) block[i] = 0x00;
    _processBlock(block);

    // длина сообщения
    Uint8List lenBlock = Uint8List(64);
    int bitLen = _totalBytes * 8;
    for (int i = 0; i < 8; i++) {
      lenBlock[63 - i] = (bitLen >> (8 * i)) & 0xFF;
    }
    _processBlock(lenBlock);

    // контрольная сумма
    _processBlock(_sigma);

    return digestSize == 512 ? Uint8List.fromList(_h) : Uint8List.fromList(_h.sublist(0, 32));
  }

  void _processBlock(Uint8List m) {
    _h = _g(_n, _h, m);
    _n = _addMod512(_n, m);
    _sigma = _addMod512(_sigma, m);
  }

  Uint8List _addMod512(Uint8List a, Uint8List b) {
    Uint8List res = Uint8List(64);
    int carry = 0;
    for (int i = 63; i >= 0; i--) {
      int sum = a[i] + b[i] + carry;
      res[i] = sum & 0xFF;
      carry = sum >> 8;
    }
    return res;
  }

  Uint8List _g(Uint8List n, Uint8List h, Uint8List m) {
    Uint8List k = _xor(h, n);
    k = _lps(k);

    Uint8List t = _xor(k, m);
    t = _lps(t);

    return _xor(t, h);
  }

  Uint8List _xor(Uint8List a, Uint8List b) {
    Uint8List res = Uint8List(a.length);
    for (int i = 0; i < a.length; i++) res[i] = a[i] ^ b[i];
    return res;
  }

  Uint8List _lps(Uint8List input) {
    Uint8List s = Uint8List(64);
    for (int i = 0; i < 64; i++) s[i] = P[input[i]];

    Uint8List p = Uint8List(64);
    for (int i = 0; i < 64; i++) p[i] = s[T[i]];

    return _lTransform(p);
  }

  Uint8List _lTransform(Uint8List data) {
    Uint8List res = Uint8List(64);

    for (int i = 0; i < 8; i++) {
      int val = 0;
      for (int k = 0; k < 8; k++) {
        int byte = data[i * 8 + k];
        for (int bit = 0; bit < 8; bit++) {
          if ((byte & (1 << (7 - bit))) != 0) {
            val ^= MATRIX_A[k * 8 + bit];
          }
        }
      }
      for (int j = 0; j < 8; j++) {
        res[i * 8 + j] = (val >> ((7 - j) * 8)) & 0xFF;
      }
    }

    return res;
  }
}
