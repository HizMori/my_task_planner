import 'package:flutter/material.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: const Center(child: Text('Экран магазина')),
    );
  }
}
