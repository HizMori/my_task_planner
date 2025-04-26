import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аккаунт'),
        backgroundColor: const Color(0xFF2A9D8F),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu), // Кнопка для открытия Drawer
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      body: const Center(child: Text('Экран управления аккаунтом')),
    );
  }
}
