import 'package:flutter/material.dart';

class CountdownsScreen extends StatelessWidget {
  const CountdownsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Обратные отсчёты'),
        backgroundColor: const Color(0xFF2A9D8F),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu), // Кнопка для открытия Drawer
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      body: const Center(child: Text('Экран управления обратными отсчётами')),
    );
  }
}
