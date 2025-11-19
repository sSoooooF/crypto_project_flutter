import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/encrypted_text.dart';

class DatabaseService {
  static const String usersBoxName = 'users';
  static const String textsBoxName = 'encrypted_texts';
  
  Box? _usersBox;
  Box? _textsBox;

  Future<Box> get _usersBoxInstance async {
    _usersBox ??= await Hive.openBox(usersBoxName);
    return _usersBox!;
  }

  Future<Box> get _textsBoxInstance async {
    _textsBox ??= await Hive.openBox(textsBoxName);
    return _textsBox!;
  }

  Future<List<User>> getUsers() async {
    try {
      final box = await _usersBoxInstance;
      final usersJson = box.get('users', defaultValue: <String>[]);
      
      if (usersJson is List && usersJson.isEmpty) {
        // Создаем дефолтного гостя при первом запуске
        final guest = User(
          id: 'guest',
          username: 'guest',
          passwordHash: '',
          role: Role.guest,
          createdAt: DateTime.now(),
        );
        await saveUsers([guest]);
        return [guest];
      }
      
      if (usersJson is List) {
        return usersJson
            .map((jsonString) => User.fromJson(jsonDecode(jsonString as String)))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  Future<void> saveUsers(List<User> users) async {
    try {
      final box = await _usersBoxInstance;
      final jsonData = users
          .map((user) => jsonEncode(user.toJson()))
          .toList();
      await box.put('users', jsonData);
    } catch (e) {
      print('Error saving users: $e');
      rethrow;
    }
  }

  Future<List<EncryptedText>> getEncryptedTexts() async {
    try {
      final box = await _textsBoxInstance;
      final textsJson = box.get('texts', defaultValue: <String>[]);
      
      if (textsJson is List) {
        return textsJson
            .map((jsonString) => EncryptedText.fromJson(jsonDecode(jsonString as String)))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting encrypted texts: $e');
      return [];
    }
  }

  Future<void> saveEncryptedTexts(List<EncryptedText> texts) async {
    try {
      final box = await _textsBoxInstance;
      final jsonData = texts
          .map((text) => jsonEncode(text.toJson()))
          .toList();
      await box.put('texts', jsonData);
    } catch (e) {
      print('Error saving encrypted texts: $e');
      rethrow;
    }
  }

  Future<User?> authenticate(String username, String passwordHash) async {
    final users = await getUsers();
    try {
      return users.firstWhere(
        (user) =>
            user.username == username && user.passwordHash == passwordHash,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> registerUser(
    String username,
    String passwordHash,
    Role role, {
    String? totpSecret,
    bool hasBiometricEnabled = false,
  }) async {
    final users = await getUsers();
    if (users.any((user) => user.username == username)) {
      throw Exception('Пользователь уже существует');
    }
    users.add(
      User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        passwordHash: passwordHash,
        role: role,
        createdAt: DateTime.now(),
        totpSecret: totpSecret,
        hasBiometricEnabled: hasBiometricEnabled,
      ),
    );
    await saveUsers(users);
  }

  Future<void> saveEncryptedText(EncryptedText text) async {
    final texts = await getEncryptedTexts();
    texts.add(text);
    await saveEncryptedTexts(texts);
  }

  Future<List<EncryptedText>> getUserTexts(String username) async {
    final texts = await getEncryptedTexts();
    return texts.where((text) => text.username == username).toList();
  }

  Future<void> updateUserBiometricStatus(String username, bool hasBiometricEnabled) async {
    final users = await getUsers();
    final userIndex = users.indexWhere((user) => user.username == username);
    if (userIndex == -1) {
      throw Exception('Пользователь не найден');
    }
    
    // Create updated user with new biometric status
    final user = users[userIndex];
    users[userIndex] = User(
      id: user.id,
      username: user.username,
      passwordHash: user.passwordHash,
      role: user.role,
      createdAt: user.createdAt,
      totpSecret: user.totpSecret,
      hasBiometricEnabled: hasBiometricEnabled,
    );
    
    await saveUsers(users);
  }
}
