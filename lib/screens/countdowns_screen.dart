import 'package:flutter/material.dart';

class CountdownsScreen extends StatelessWidget {
  const CountdownsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Обратные отсчёты')),
      body: const Center(child: Text('Экран управления обратными отсчётами')),
    );
  }
}
