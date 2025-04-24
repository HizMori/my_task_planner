import 'package:flutter/material.dart';

class NotebooksScreen extends StatelessWidget {
  const NotebooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Блокноты'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: const Center(child: Text('Экран управления блокнотами')),
    );
  }
}
