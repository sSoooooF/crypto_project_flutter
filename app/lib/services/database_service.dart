import 'dart:convert';
import 'dart:io';
import '../models/user.dart';
import '../models/encrypted_text.dart';

class DatabaseService {
  static const String usersFile = 'users.json';
  static const String textsFile = 'encrypted_texts.json';

  Future<String> get _localPath async {
    return '.';
  }

  Future<File> _getUsersFile() async {
    final path = await _localPath;
    return File('$path/$usersFile');
  }

  Future<File> _getTextsFile() async {
    final path = await _localPath;
    return File('$path/$textsFile');
  }

  Future<List<User>> getUsers() async {
    try {
      final file = await _getUsersFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonData = jsonDecode(contents);
        return jsonData.map((json) => User.fromJson(json)).toList();
      }
      // Создаем дефолтного гостя
      final guest = User(
        id: 'guest',
        username: 'guest',
        passwordHash: '',
        role: Role.guest,
        createdAt: DateTime.now(),
      );
      await saveUsers([guest]);
      return [guest];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveUsers(List<User> users) async {
    final file = await _getUsersFile();
    final jsonData = users.map((user) => user.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonData));
  }

  // Заглушки для EncryptedText (создадим позже)
  Future<List<EncryptedText>> getEncryptedTexts() async {
    try {
      final file = await _getTextsFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonData = jsonDecode(contents);
        return jsonData.map((json) => EncryptedText.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveEncryptedTexts(List<EncryptedText> texts) async {
    final file = await _getTextsFile();
    final jsonData = texts.map((text) => text.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonData));
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
    Role role,
  ) async {
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
}
