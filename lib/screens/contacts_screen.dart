import 'package:flutter/material.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Контакты'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(child: Text('Экран контактов')),
    );
  }
}
