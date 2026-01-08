import 'package:flutter/material.dart';
import '../models/user.dart';

class SearchUsersScreen extends StatelessWidget {
  const SearchUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить участника')),
      body: const Center(child: Text('Поиск контактов (реализуется позже)')),
    );
  }
}