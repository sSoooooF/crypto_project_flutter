import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Создаем тестового пользователя при запуске
  final authService = AuthService();
  await authService.createTestUser();

  // Создаем админа только если он еще не существует
  final databaseService = DatabaseService();
  final users = await databaseService.getUsers();
  final adminExists = users.any((u) => u.username == 'admin' && u.totpSecret != null);
  
  if (!adminExists) {
    await authService.createAdminUser();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Крипто приложение',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}
