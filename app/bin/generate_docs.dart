#!/usr/bin/env dart

/// Скрипт для локальной генерации API документации проекта Crypto App.
///
/// Запуск: dart bin/generate_docs.dart
///
/// Генерирует HTML документацию в папке docs/api/ используя dartdoc.

import 'dart:io';

void main() async {
  print('🔐 Crypto App - Генерация документации');
  print('======================================');

  // Проверяем наличие dartdoc
  print('🔍 Проверка наличия dartdoc...');
  final dartdocResult = await Process.run('dart', ['doc', '--version']);
  if (dartdocResult.exitCode != 0) {
    print('❌ dartdoc не найден. Устанавливаем...');
    final installResult =
        await Process.run('dart', ['pub', 'global', 'activate', 'dartdoc']);
    if (installResult.exitCode != 0) {
      print('❌ Ошибка установки dartdoc: ${installResult.stderr}');
      exit(1);
    }
    print('✅ dartdoc установлен');
  } else {
    print('✅ dartdoc найден');
  }

  // Создаем директорию для документации
  final docsDir = Directory('docs/api');
  if (await docsDir.exists()) {
    print('🗑️ Очистка существующей документации...');
    await docsDir.delete(recursive: true);
  }

  print('📚 Генерация API документации...');
  final docResult = await Process.run(
      'dart',
      [
        'doc',
        '--no-include-source',
        '--output=docs/api',
        '--include-sdk',
      ],
      workingDirectory: '.');

  if (docResult.exitCode == 0) {
    print('✅ Документация успешно сгенерирована!');
    print('📂 Документация сохранена в: docs/api/');

    // Создаем индексный файл
    await createIndexFile();

    print('');
    print(
        '🌐 Откройте docs/api/index.html в браузере для просмотра документации');
  } else {
    print('❌ Ошибка генерации документации:');
    print(docResult.stderr);
    exit(1);
  }
}

Future<void> createIndexFile() async {
  final indexContent = '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Crypto App - API Documentation</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .nav { margin: 20px 0; }
        .nav a { margin-right: 20px; text-decoration: none; color: #007bff; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔐 Crypto App - API Документация</h1>
        <p>Документация генерируется автоматически при каждом коммите</p>
    </div>
    
    <div class="nav">
        <h3>Основные разделы:</h3>
        <a href="index.html">API Reference</a>
        <a href="../README.md">README</a>
        <a href="../docs/DEVELOPMENT.md">Development Guide</a>
    </div>
    
    <h3>Криптографические алгоритмы:</h3>
    <ul>
        <li><a href="crypto_project_flutter/CryptoProjectFlutter-class.html">Crypto Project Flutter</a></li>
        <li><a href="crypto_project_flutter/Kuznechik-class.html">Kuznechik (ГОСТ Р 34.12-2015)</a></li>
        <li><a href="crypto_project_flutter/Streebog-class.html">Streebog (ГОСТ Р 34.11-2012)</a></li>
    </ul>
    
    <hr>
    <p><small>Сгенерировано: ${DateTime.now()}</small></p>
</body>
</html>
''';

  final indexFile = File('docs/api/index_local.html');
  await indexFile.writeAsString(indexContent);
  print('📋 Создан локальный индекс: docs/api/index_local.html');
}
