import 'package:flutter/material.dart';
import 'screens/task_list_screen.dart'; // Импортируем экран списка задач
import 'screens/calendar_screen.dart'; // Импортируем экран календаря
import 'screens/contacts_screen.dart'; // Импортируем экран контактов
import 'screens/settings_screen.dart'; // Импортируем экран настроек

void main() {
  runApp(const MyApp()); // Запускаем приложение
}

// Главный класс приложения
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Planner', // Название приложения
      theme: ThemeData(
        primarySwatch: Colors.blue, // Основной цвет темы
        useMaterial3:
            true, // Используем Material Design 3 для современного стиля
      ),
      home: const MainScreen(), // Устанавливаем главный экран
    );
  }
}

// Главный экран с нижней навигацией
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Переменная для хранения индекса выбранной вкладки

  // Список экранов, которые будут отображаться при переключении вкладок
  static const List<Widget> _screens = <Widget>[
    TaskListScreen(), // Экран списка задач
    CalendarScreen(), // Экран календаря
    ContactsScreen(), // Экран контактов
    SettingsScreen(), // Экран настроек
  ];

  // Функция для переключения между вкладками
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Обновляем индекс выбранной вкладки
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens.elementAt(
        _selectedIndex,
      ), // Отображаем экран, соответствующий текущему индексу
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list), // Иконка для вкладки "Задачи"
            label: 'Задачи', // Название вкладки
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), // Иконка для вкладки "Календарь"
            label: 'Календарь', // Название вкладки
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts), // Иконка для вкладки "Контакты"
            label: 'Контакты', // Название вкладки
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), // Иконка для вкладки "Настройки"
            label: 'Настройки', // Название вкладки
          ),
        ],
        currentIndex: _selectedIndex, // Текущая активная вкладка
        selectedItemColor: Colors.blue, // Цвет активной вкладки
        unselectedItemColor: Colors.grey, // Цвет неактивных вкладок
        type:
            BottomNavigationBarType
                .fixed, // Фиксированный стиль навигационной панели
        onTap:
            _onItemTapped, // Вызываем функцию переключения вкладок при нажатии
      ),
    );
  }
}
