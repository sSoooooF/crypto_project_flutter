import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../models/user.dart';
import '../core/streebog/streebog.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<User> _users = [];
  List<dynamic> _encryptedTexts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final users = await _databaseService.getUsers();
    final texts = await _databaseService.getEncryptedTexts();
    setState(() {
      _users = users;
      _encryptedTexts = texts;
    });
  }

  Future<void> _deleteUser(String username) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить пользователя "$username"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final users = await _databaseService.getUsers();
        final updatedUsers = users
            .where((user) => user.username != username)
            .toList();
        await _databaseService.saveUsers(updatedUsers);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Пользователь "$username" удален'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e')),
          );
        }
      }
    }
  }

  Future<void> _createAdmin() async {
    final adminUsername = 'admin';
    final adminPassword = 'admin123';
    Streebog streebog = Streebog();
    streebog.update(utf8.encode(adminPassword));
    List<int> digest = streebog.digest();
    String passwordHash = digest
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    try {
      await _databaseService.registerUser(
        adminUsername,
        passwordHash,
        Role.admin,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Админ создан: admin/admin123')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Админ панель')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _createAdmin,
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Создать дефолтного админа'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Пользователи:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: _users.isEmpty
                  ? const Center(
                      child: Text(
                        'Нет зарегистрированных пользователей',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user.role == Role.admin
                                  ? Colors.red
                                  : user.role == Role.user
                                      ? Colors.blue
                                      : Colors.grey,
                              child: Text(
                                user.username[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              user.username,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Роль: ${user.role.toString().split('.').last}'),
                                if (user.totpSecret != null)
                                  const Text(
                                    'TOTP: ✓',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                if (user.hasBiometricEnabled)
                                  const Text(
                                    'Биометрия: ✓',
                                    style: TextStyle(color: Colors.green),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Удалить пользователя',
                              onPressed: () => _deleteUser(user.username),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Зашифрованные тексты:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: _encryptedTexts.length,
                itemBuilder: (context, index) {
                  final text = _encryptedTexts[index];
                  return Card(
                    child: ListTile(
                      title: Text('Алгоритм: ${text['algorithm']}'),
                      subtitle: Text('Пользователь: ${text['username']}'),
                      trailing: Text(
                        text['encryptedText'].substring(0, 20) + '...',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
