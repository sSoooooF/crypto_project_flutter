import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'crypto_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  final DatabaseService _databaseService = DatabaseService();

  HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Добро пожаловать, ${user.username} (${user.role.toString().split('.').last.toUpperCase()})',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Роль: ${user.role.toString().split('.').last.toUpperCase()}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CryptoScreen(user: user),
                  ),
                );
              },
              icon: const Icon(Icons.security),
              label: const Text('Шифрование/Дешифрование'),
            ),
            if (user.isAdmin) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Админ панель'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
