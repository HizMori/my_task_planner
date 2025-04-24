import 'package:flutter/material.dart';
import '../main.dart'; // Импорт основного файла приложения

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mainScreenState = MainScreen.of(context);
    final bool showBackButton =
        mainScreenState != null && mainScreenState.screenStackLength > 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать'),
        backgroundColor: Theme.of(context).primaryColor,
        leading:
            showBackButton
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    mainScreenState.popScreen();
                  },
                )
                : IconButton(
                  icon: const Icon(Icons.menu), // Кнопка для открытия Drawer
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
      ),
      body: const Center(
        child: Text(
          'Экран быстрого создания (задача, заметка, обратный отсчёт)',
        ),
      ),
    );
  }
}
