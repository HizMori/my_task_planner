import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск задач/заметок'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: const Center(child: Text('Экран поиска задач и заметок')),
    );
  }
}
