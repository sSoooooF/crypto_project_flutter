import 'dart:convert';
import 'dart:typed_data';
import 'rsa/rsa.dart';
import 'Kuznyechik/kuznechik.dart';
import 'streebog/streebog.dart';

/// Data class for RSA encryption in isolate
class RSAEncryptData {
  final String message;
  final String nHex;
  final String eHex;

  RSAEncryptData(this.message, this.nHex, this.eHex);
}

/// Data class for RSA decryption in isolate
class RSADecryptData {
  final String encryptedHex;
  final String nHex;
  final String dHex;

  RSADecryptData(this.encryptedHex, this.nHex, this.dHex);
}

/// Data class for Kuznechik encryption in isolate
class KuznechikEncryptData {
  final String message;
  final List<int> keyBytes;

  KuznechikEncryptData(this.message, this.keyBytes);
}

/// Data class for Kuznechik decryption in isolate
class KuznechikDecryptData {
  final String encryptedHex;
  final List<int> keyBytes;

  KuznechikDecryptData(this.encryptedHex, this.keyBytes);
}

/// Top-level function for RSA encryption in isolate
String encryptRSAIsolate(RSAEncryptData data) {
  try {
    final messageBytes = utf8.encode(data.message);
    final message = BigInt.parse(
      messageBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16,
    );
    
    final n = BigInt.parse(data.nHex, radix: 16);
    final e = BigInt.parse(data.eHex, radix: 16);
    final keyPair = RSAKeyPair(n, e, BigInt.zero); // d not needed for encryption
    
    final encrypted = encrypt(message, keyPair);
    return encrypted.toRadixString(16);
  } catch (e) {
    return 'Ошибка шифрования: $e';
  }
}

/// Top-level function for RSA decryption in isolate
String decryptRSAIsolate(RSADecryptData data) {
  try {
    final encrypted = BigInt.parse(data.encryptedHex, radix: 16);
    
    final n = BigInt.parse(data.nHex, radix: 16);
    final d = BigInt.parse(data.dHex, radix: 16);
    final keyPair = RSAKeyPair(n, BigInt.zero, d); // e not needed for decryption
    
    final decrypted = decrypt(encrypted, keyPair);
    
    // Convert back to string
    final hex = decrypted
        .toRadixString(16)
        .padLeft((decrypted.bitLength + 7) ~/ 8 * 2, '0');
    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return utf8.decode(bytes, allowMalformed: true);
  } catch (e) {
    return 'Ошибка дешифрования: $e';
  }
}

/// Helper function to add PKCS7 padding
Uint8List addPKCS7Padding(Uint8List data, int blockSize) {
  final paddingLength = blockSize - (data.length % blockSize);
  final padding = Uint8List(paddingLength)..fillRange(0, paddingLength, paddingLength);
  return Uint8List.fromList([...data, ...padding]);
}

/// Helper function to remove PKCS7 padding
Uint8List removePKCS7Padding(Uint8List data) {
  if (data.isEmpty) return data;
  final paddingLength = data.last;
  if (paddingLength > data.length || paddingLength == 0) return data;
  return data.sublist(0, data.length - paddingLength);
}

/// Helper function to convert bytes to hex
String bytesToHex(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

/// Top-level function for Kuznechik encryption in isolate
String encryptKuznechikIsolate(KuznechikEncryptData data) {
  try {
    final kuznechik = Kuznechik(Uint8List.fromList(data.keyBytes));
    final messageBytes = utf8.encode(data.message);
    final padded = addPKCS7Padding(messageBytes, 16);
    
    final blocks = <Uint8List>[];
    for (int i = 0; i < padded.length; i += 16) {
      blocks.add(padded.sublist(i, i + 16));
    }
    
    final encryptedBlocks = blocks.map((b) => kuznechik.encryptBlock(b)).toList();
    final result = Uint8List.fromList(encryptedBlocks.expand((b) => b).toList());
    
    return bytesToHex(result);
  } catch (e) {
    return 'Ошибка шифрования: $e';
  }
}

/// Top-level function for Kuznechik decryption in isolate
String decryptKuznechikIsolate(KuznechikDecryptData data) {
  try {
    final kuznechik = Kuznechik(Uint8List.fromList(data.keyBytes));
    
    // Convert hex to bytes
    final bytes = <int>[];
    for (int i = 0; i < data.encryptedHex.length; i += 2) {
      bytes.add(int.parse(data.encryptedHex.substring(i, i + 2), radix: 16));
    }
    final encryptedBytes = Uint8List.fromList(bytes);
    
    // Split into blocks
    final blocks = <Uint8List>[];
    for (int i = 0; i < encryptedBytes.length; i += 16) {
      blocks.add(encryptedBytes.sublist(i, i + 16));
    }
    
    // Decrypt blocks
    final decryptedBlocks = blocks.map((b) => kuznechik.decryptBlock(b)).toList();
    final padded = Uint8List.fromList(decryptedBlocks.expand((b) => b).toList());
    
    // Remove padding
    final result = removePKCS7Padding(padded);
    return utf8.decode(result);
  } catch (e) {
    return 'Ошибка дешифрования: $e';
  }
}

/// Top-level function for Streebog hashing in isolate
String hashStreebogIsolate(String message) {
  try {
    final data = utf8.encode(message);
    final streebog = Streebog();
    streebog.update(data);
    final hash = streebog.digest();
    return bytesToHex(hash);
  } catch (e) {
    return 'Ошибка хэширования: $e';
  }
}

