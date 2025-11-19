import 'package:flutter/material.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Инструкции по QR-входу'),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Вход через QR-код',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Безопасный вход с помощью мобильного телефона',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Процесс входа
            const Text(
              'Как войти через QR-код:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Шаги
            _buildStepCard(
              'Шаг 1: Генерация QR-кода',
              '1. Откройте экран входа\n2. Введите имя пользователя (опционально)\n3. Нажмите "Сгенерировать QR-код для входа"\n4. QR-код будет отображен на экране',
              Icons.qr_code,
              Colors.blue,
            ),

            const SizedBox(height: 16),

            _buildStepCard(
              'Шаг 2: Сканирование QR-кода',
              '1. Откройте приложение аутентификации на телефоне\n2. Добавьте новый аккаунт\n3. Выберите "Сканировать QR-код"\n4. Наведите камеру на QR-код с экрана CryptoApp',
              Icons.phone_android,
              Colors.green,
            ),

            const SizedBox(height: 16),

            _buildStepCard(
              'Шаг 3: Подтверждение входа',
              '1. Вернитесь в приложение CryptoApp\n2. Введите 6-значный код из приложения аутентификации\n3. Нажмите "Подтвердить вход"\n4. Готово! Вы вошли в приложение',
              Icons.check_circle,
              Colors.orange,
            ),

            const SizedBox(height: 24),

            // Поддерживаемые приложения
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Поддерживаемые приложения аутентификации:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAppItem(
                      'Google Authenticator',
                      'android',
                      'Самое популярное приложение для TOTP',
                    ),
                    _buildAppItem(
                      'Authy',
                      'cross-platform',
                      'Поддерживает резервные копии',
                    ),
                    _buildAppItem(
                      'Microsoft Authenticator',
                      'cross-platform',
                      'Интеграция с Microsoft аккаунтами',
                    ),
                    _buildAppItem(
                      'LastPass Authenticator',
                      'cross-platform',
                      'Интеграция с менеджером паролей',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Советы по безопасности
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Советы по безопасности:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSecurityTip(
                      'Используйте надежное приложение аутентификации',
                      'Выберите приложение с хорошей репутацией',
                    ),
                    _buildSecurityTip(
                      'Не делитесь QR-кодом',
                      'QR-код должен быть доступен только вам',
                    ),
                    _buildSecurityTip(
                      'Храните резервные копии',
                      'Создайте резервные коды на случай потери телефона',
                    ),
                    _buildSecurityTip(
                      'Обновляйте приложения',
                      'Регулярно обновляйте приложение CryptoApp и приложение аутентификации',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Кнопка действий
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Вернуться к входу'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppItem(String name, String platform, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.apps, color: Colors.grey, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '$platform • $description',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTip(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.security, color: Colors.red, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
