import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/encrypted_text.dart';
import '../services/database_service.dart';
import '../core/Kuznyechik/kuznechik.dart';
import '../core/rsa/rsa.dart';
import '../core/streebog/streebog.dart';

enum Algorithm { rsa, kuznechik, streebog }

class CryptoScreen extends StatefulWidget {
  final User user;

  const CryptoScreen({super.key, required this.user});

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Algorithm selectedAlgorithm = Algorithm.rsa;
  final TextEditingController plaintextController = TextEditingController();
  final TextEditingController ciphertextController = TextEditingController();
  final TextEditingController hashController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  RSAKeyPair? rsaKeyPair;
  Kuznechik? kuznechik;
  bool _isInitializing = true;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializeAlgorithms();
  }

  Future<void> _initializeAlgorithms() async {
    try {
      setState(() {
        _isInitializing = true;
        _initializationError = null;
      });

      rsaKeyPair = await generateRSAKeyPairFromFiles(
        'assets/prime1.txt',
        'assets/prime2.txt',
      );
      final Uint8List key = Uint8List.fromList(List.generate(32, (i) => i % 256));
      kuznechik = Kuznechik(key);

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _initializationError = 'Ошибка инициализации: $e';
      });
    }
  }

  Uint8List _addPKCS7Padding(Uint8List data, int blockSize) {
    int paddingLength = blockSize - (data.length % blockSize);
    Uint8List padding = Uint8List(paddingLength)
      ..fillRange(0, paddingLength, paddingLength);
    return Uint8List.fromList([...data, ...padding]);
  }

  Uint8List _removePKCS7Padding(Uint8List data) {
    if (data.isEmpty) return data;
    int paddingLength = data.last;
    if (paddingLength > data.length || paddingLength == 0) return data;
    return data.sublist(0, data.length - paddingLength);
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  String _encryptRSA(String text) {
    try {
      if (rsaKeyPair == null) {
        return 'Ошибка шифрования: RSA ключи не инициализированы';
      }
      List<int> bytes = utf8.encode(text);
      BigInt message = BigInt.parse(
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16,
      );
      BigInt encrypted = encrypt(message, rsaKeyPair!);
      return encrypted.toRadixString(16);
    } catch (e) {
      return 'Ошибка шифрования: $e';
    }
  }

  String _decryptRSA(String hexText) {
    try {
      if (rsaKeyPair == null) {
        return 'Ошибка дешифрования: RSA ключи не инициализированы';
      }
      BigInt encrypted = BigInt.parse(hexText, radix: 16);
      BigInt decrypted = decrypt(encrypted, rsaKeyPair!);
      List<int> bytes = [];
      String hex = decrypted
          .toRadixString(16)
          .padLeft((decrypted.bitLength + 7) ~/ 8 * 2, '0');
      for (int i = 0; i < hex.length; i += 2) {
        bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
      }
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      return 'Ошибка дешифрования: $e';
    }
  }

  String _encryptKuznechik(String text) {
    try {
      if (kuznechik == null) {
        return 'Ошибка шифрования: Kuznechik не инициализирован';
      }
      Uint8List data = utf8.encode(text);
      Uint8List padded = _addPKCS7Padding(data, 16);
      List<Uint8List> blocks = [];
      for (int i = 0; i < padded.length; i += 16) {
        blocks.add(padded.sublist(i, i + 16));
      }
      List<Uint8List> encryptedBlocks = blocks
          .map((b) => kuznechik!.encryptBlock(b))
          .toList();
      Uint8List result = Uint8List.fromList(
        encryptedBlocks.expand((b) => b).toList(),
      );
      return _bytesToHex(result);
    } catch (e) {
      return 'Ошибка шифрования: $e';
    }
  }

  String _decryptKuznechik(String hexText) {
    try {
      if (kuznechik == null) {
        return 'Ошибка дешифрования: Kuznechik не инициализирован';
      }
      List<int> bytes = [];
      for (int i = 0; i < hexText.length; i += 2) {
        bytes.add(int.parse(hexText.substring(i, i + 2), radix: 16));
      }
      Uint8List data = Uint8List.fromList(bytes);
      List<Uint8List> blocks = [];
      for (int i = 0; i < data.length; i += 16) {
        blocks.add(data.sublist(i, i + 16));
      }
      List<Uint8List> decryptedBlocks = blocks
          .map((b) => kuznechik!.decryptBlock(b))
          .toList();
      Uint8List padded = Uint8List.fromList(
        decryptedBlocks.expand((b) => b).toList(),
      );
      Uint8List result = _removePKCS7Padding(padded);
      return utf8.decode(result);
    } catch (e) {
      return 'Ошибка дешифрования: $e';
    }
  }

  String _hashStreebog(String text) {
    try {
      Uint8List data = utf8.encode(text);
      Streebog streebog = Streebog();
      streebog.update(data);
      Uint8List hash = streebog.digest();
      return _bytesToHex(hash);
    } catch (e) {
      return 'Ошибка хэширования: $e';
    }
  }

  void _encrypt() async {
    String text = plaintextController.text;
    String result;
    if (selectedAlgorithm == Algorithm.rsa) {
      result = _encryptRSA(text);
    } else if (selectedAlgorithm == Algorithm.kuznechik) {
      result = _encryptKuznechik(text);
    } else {
      result = _hashStreebog(text);
      hashController.text = result;
      return;
    }
    ciphertextController.text = result;

    // Сохраняем зашифрованный текст
    final encryptedText = EncryptedText(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: widget.user.username,
      originalText: text,
      encryptedText: result,
      algorithm: selectedAlgorithm.toString().split('.').last,
      createdAt: DateTime.now(),
    );
    await _databaseService.saveEncryptedText(encryptedText);
  }

  void _decrypt() {
    String text = ciphertextController.text;
    String result;
    if (selectedAlgorithm == Algorithm.rsa) {
      result = _decryptRSA(text);
    } else if (selectedAlgorithm == Algorithm.kuznechik) {
      result = _decryptKuznechik(text);
    } else {
      return;
    }
    plaintextController.text = result;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Скопировано в буфер обмена')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Шифрование/Дешифрование'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.only(top: 56.0),
          children: Algorithm.values.map((Algorithm algorithm) {
            String label = algorithm == Algorithm.rsa
                ? 'RSA'
                : algorithm == Algorithm.kuznechik
                ? 'Кузнечик'
                : 'Стрибог';
            return ListTile(
              title: Text(label),
              selected: selectedAlgorithm == algorithm,
              onTap: () {
                setState(() {
                  selectedAlgorithm = algorithm;
                  plaintextController.clear();
                  ciphertextController.clear();
                  hashController.clear();
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Инициализация алгоритмов шифрования...'),
                ],
              ),
            )
          : _initializationError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _initializationError!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeAlgorithms,
                        child: const Text('Повторить инициализацию'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
            if (selectedAlgorithm != Algorithm.streebog) ...[
              TextField(
                controller: plaintextController,
                decoration: const InputDecoration(
                  labelText: 'Исходный текст',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ciphertextController,
                      decoration: const InputDecoration(
                        labelText: 'Зашифрованный текст',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Копировать зашифрованный текст',
                    onPressed: () {
                      if (ciphertextController.text.isNotEmpty) {
                        _copyToClipboard(ciphertextController.text);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _encrypt,
                    child: const Text('Зашифровать'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _decrypt,
                    child: const Text('Дешифровать'),
                  ),
                ],
              ),
            ] else ...[
              TextField(
                controller: plaintextController,
                decoration: const InputDecoration(
                  labelText: 'Текст для хэширования',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hashController,
                      decoration: const InputDecoration(
                        labelText: 'Хэш',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Копировать хэш',
                    onPressed: () {
                      if (hashController.text.isNotEmpty) {
                        _copyToClipboard(hashController.text);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _encrypt,
                child: const Text('Хэшировать'),
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(
                child: Text(
                  'Алгоритм: ${selectedAlgorithm == Algorithm.rsa
                      ? "RSA"
                      : selectedAlgorithm == Algorithm.kuznechik
                      ? "Кузнечик"
                      : "Стрибог"}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
