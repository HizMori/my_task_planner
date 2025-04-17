import 'package:flutter/material.dart';
import 'screens/task_list_screen.dart'; // Импортируем экран списка задач
import 'screens/calendar_screen.dart'; // Импортируем экран календаря
import 'screens/contacts_screen.dart'; // Импортируем экран контактов
import 'screens/settings_screen.dart'; // Импортируем экран настроек
import 'screens/eisenhower_screen.dart'; // Экран Матрицы Эйзенхауэра

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
        // Светлая тема
        brightness: Brightness.light,
        primaryColor: const Color(0xFF3498DB), // Синий акцент (светлая тема)
        scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Светлый фон
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF000000), fontSize: 16),
          headlineSmall: TextStyle(
            color: Color(0xFF000000),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3498DB), // Синий для кнопок
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        useMaterial3:
            true, // Оставляем Material Design 3 для современного стиля
      ),
      darkTheme: ThemeData(
        // Тёмная тема
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF007AFF), // Синий акцент (тёмная тема)
        scaffoldBackgroundColor: const Color(0xFF1C2526), // Тёмный фон
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16),
          headlineSmall: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF), // Синий для кнопок
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        useMaterial3:
            true, // Используем Material Design 3 для современного стиля
      ),
      themeMode:
          ThemeMode.system, // Автоматическое переключение темы (светлая/тёмная)
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
    EisenhowerScreen(), // Экран Матрицы Эйзенхауэра
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
      body: AnimatedSwitcher(
        duration: const Duration(
          milliseconds: 300,
        ), // Анимация переключения (300ms)
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens.elementAt(_selectedIndex), // Отображаем текущий экран
      ), // Отображаем экран, соответствующий текущему индексу
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list), // Иконка для вкладки "Задачи"
            label: 'Задачи', // Название вкладки
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_on), // Иконка для вкладки "Матрица"
            label: 'Матрица',
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
        selectedItemColor:
            Theme.of(
              context,
            ).primaryColor, // Цвет активной вкладки (берётся из темы)
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
