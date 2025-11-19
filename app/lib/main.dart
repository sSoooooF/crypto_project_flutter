import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto_project_core/rsa/rsa.dart';
import 'package:crypto_project_core/Kuznyechik/kuznechik.dart';
import 'package:crypto_project_core/streebog/streebog.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

enum Algorithm { rsa, kuznechik, streebog }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Крипто приложение',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Крипто приложение'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Algorithm selectedAlgorithm = Algorithm.rsa;
  final TextEditingController plaintextController = TextEditingController();
  final TextEditingController ciphertextController = TextEditingController();
  final TextEditingController hashController = TextEditingController();

  late RSAKeyPair rsaKeyPair;
  late Kuznechik kuznechik;

  @override
  void initState() {
    super.initState();
    _initializeAlgorithms();
  }

  Future<void> _initializeAlgorithms() async {
    // Initialize RSA
    rsaKeyPair = await generateRSAKeyPairFromFiles(
      'assets/prime1.txt',
      'assets/prime2.txt',
    );

    // Initialize Kuznechik with a hardcoded key (32 bytes)
    final Uint8List key = Uint8List.fromList(List.generate(32, (i) => i % 256));
    kuznechik = Kuznechik(key);
  }

  Uint8List _addPKCS7Padding(Uint8List data, int blockSize) {
    int paddingLength = blockSize - (data.length % blockSize);
    Uint8List padding = Uint8List(paddingLength)
      ..fillRange(0, paddingLength, paddingLength);
    return Uint8List.fromList(data + padding);
  }

  Uint8List _removePKCS7Padding(Uint8List data) {
    if (data.isEmpty) return data;
    int paddingLength = data.last;
    if (paddingLength > data.length || paddingLength == 0) return data;
    return data.sublist(0, data.length - paddingLength);
  }

  String _encryptRSA(String text) {
    try {
      List<int> bytes = utf8.encode(text);
      BigInt message = BigInt.parse(
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16,
      );
      BigInt encrypted = encrypt(message, rsaKeyPair);
      return encrypted.toRadixString(16);
    } catch (e) {
      return 'Ошибка шифрования: $e';
    }
  }

  String _decryptRSA(String hexText) {
    try {
      BigInt encrypted = BigInt.parse(hexText, radix: 16);
      BigInt decrypted = decrypt(encrypted, rsaKeyPair);
      List<int> bytes = [];
      String hex = decrypted
          .toRadixString(16)
          .padLeft((decrypted.bitLength + 7) ~/ 8 * 2, '0');
      for (int i = 0; i < hex.length; i += 2) {
        bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
      }
      return utf8.decode(bytes);
    } catch (e) {
      return 'Ошибка дешифрования: $e';
    }
  }

  String _encryptKuznechik(String text) {
    try {
      Uint8List data = utf8.encode(text);
      Uint8List padded = _addPKCS7Padding(data, 16);
      List<Uint8List> blocks = [];
      for (int i = 0; i < padded.length; i += 16) {
        blocks.add(padded.sublist(i, i + 16));
      }
      List<Uint8List> encryptedBlocks = blocks
          .map((b) => kuznechik.encryptBlock(b))
          .toList();
      Uint8List result = encryptedBlocks.expand((b) => b).toList();
      return result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    } catch (e) {
      return 'Ошибка шифрования: $e';
    }
  }

  String _decryptKuznechik(String hexText) {
    try {
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
          .map((b) => kuznechik.decryptBlock(b))
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
      Uint8List hash = Streebog.hash(data);
      return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    } catch (e) {
      return 'Ошибка хэширования: $e';
    }
  }

  void _encrypt() {
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
  }

  void _decrypt() {
    String text = ciphertextController.text;
    String result;
    if (selectedAlgorithm == Algorithm.rsa) {
      result = _decryptRSA(text);
    } else if (selectedAlgorithm == Algorithm.kuznechik) {
      result = _decryptKuznechik(text);
    } else {
      // No decrypt for streebog
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            DropdownButton<Algorithm>(
              value: selectedAlgorithm,
              onChanged: (Algorithm? newValue) {
                setState(() {
                  selectedAlgorithm = newValue!;
                  plaintextController.clear();
                  ciphertextController.clear();
                  hashController.clear();
                });
              },
              items: Algorithm.values.map((Algorithm algorithm) {
                return DropdownMenuItem<Algorithm>(
                  value: algorithm,
                  child: Text(
                    algorithm == Algorithm.rsa
                        ? 'RSA'
                        : algorithm == Algorithm.kuznechik
                        ? 'Кузнечик'
                        : 'Стрибог',
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (selectedAlgorithm != Algorithm.streebog) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: plaintextController,
                      decoration: const InputDecoration(
                        labelText: 'Исходный текст',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyToClipboard(plaintextController.text),
                  ),
                ],
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
                      readOnly: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () =>
                        _copyToClipboard(ciphertextController.text),
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: plaintextController,
                      decoration: const InputDecoration(
                        labelText: 'Текст для хэширования',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyToClipboard(plaintextController.text),
                  ),
                ],
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
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyToClipboard(hashController.text),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _encrypt, // reuse for hash
                child: const Text('Хэшировать'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
