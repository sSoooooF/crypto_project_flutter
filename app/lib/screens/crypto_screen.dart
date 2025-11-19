import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/encrypted_text.dart';
import '../services/database_service.dart';
import '../core/Kuznyechik/kuznechik.dart';
import '../core/rsa/rsa.dart';
import '../core/streebog/streebog.dart';
import '../core/crypto_isolate.dart';

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
  bool _isProcessing = false;

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



  void _encrypt() async {
    if (_isProcessing) return;
    
    final text = plaintextController.text;
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      String result;
      
      if (selectedAlgorithm == Algorithm.rsa) {
        if (rsaKeyPair == null) {
          result = 'Ошибка шифрования: RSA ключи не инициализированы';
        } else {
          final data = RSAEncryptData(
            text,
            rsaKeyPair!.n.toRadixString(16),
            rsaKeyPair!.e.toRadixString(16),
          );
          result = await compute(encryptRSAIsolate, data);
        }
      } else if (selectedAlgorithm == Algorithm.kuznechik) {
        if (kuznechik == null) {
          result = 'Ошибка шифрования: Kuznechik не инициализирован';
        } else {
          final keyBytes = List.generate(32, (i) => i % 256);
          final data = KuznechikEncryptData(text, keyBytes);
          result = await compute(encryptKuznechikIsolate, data);
        }
      } else {
        // Streebog
        result = await compute(hashStreebogIsolate, text);
        if (mounted) {
          hashController.text = result;
        }
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      if (mounted) {
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
    } catch (e) {
      if (mounted) {
        ciphertextController.text = 'Ошибка: $e';
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _decrypt() async {
    if (_isProcessing) return;
    
    final text = ciphertextController.text;
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      String result;
      
      if (selectedAlgorithm == Algorithm.rsa) {
        if (rsaKeyPair == null) {
          result = 'Ошибка дешифрования: RSA ключи не инициализированы';
        } else {
          final data = RSADecryptData(
            text,
            rsaKeyPair!.n.toRadixString(16),
            rsaKeyPair!.d.toRadixString(16),
          );
          result = await compute(decryptRSAIsolate, data);
        }
      } else if (selectedAlgorithm == Algorithm.kuznechik) {
        if (kuznechik == null) {
          result = 'Ошибка дешифрования: Kuznechik не инициализирован';
        } else {
          final keyBytes = List.generate(32, (i) => i % 256);
          final data = KuznechikDecryptData(text, keyBytes);
          result = await compute(decryptKuznechikIsolate, data);
        }
      } else {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      if (mounted) {
        plaintextController.text = result;
      }
    } catch (e) {
      if (mounted) {
        plaintextController.text = 'Ошибка: $e';
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
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
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _encrypt,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Зашифровать'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _decrypt,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Дешифровать'),
                    ),
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
                onPressed: _isProcessing ? null : _encrypt,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Хэшировать'),
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
