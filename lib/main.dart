import 'package:flutter/material.dart';
import 'screens/task_list_screen.dart'; // Экран списка задач ("Быстрый доступ")
import 'screens/calendar_screen.dart'; // Экран календаря
import 'screens/eisenhower_screen.dart'; // Экран Матрицы Эйзенхауэра
import 'screens/contacts_screen.dart'; // Экран контактов
import 'screens/settings_screen.dart'; // Экран настроек
import 'screens/search_screen.dart'; // Экран поиска
import 'screens/notebooks_screen.dart'; // Экран блокнотов
import 'screens/notes_screen.dart'; // Экран заметок
import 'screens/countdowns_screen.dart'; // Экран обратных отсчётов
import 'screens/account_screen.dart'; // Экран аккаунта
import 'screens/store_screen.dart'; // Экран магазина
import 'screens/create_screen.dart'; // Экран "Создать"
import 'screens/tags_screen.dart'; // Экран управления метками

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
        useMaterial3: true, // Оставляем Material Design 3
      ),
      themeMode: ThemeMode.system, // Автоматическое переключение темы
      home:
          const CreateScreen(), // Устанавливаем CreateScreen как начальный экран
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

  // Список основных экранов для навигационной панели
  static const List<Widget> _mainScreens = <Widget>[
    TaskListScreen(), // Экран списка задач ("Быстрый доступ")
    CalendarScreen(), // Экран календаря
    EisenhowerScreen(), // Экран Матрицы Эйзенхауэра
    SettingsScreen(), // Экран настроек
    // Пятый экран ("Ещё") будет обрабатываться отдельно
  ];

  // Список дополнительных экранов для "Ещё"
  static const List<Map<String, dynamic>> _moreScreens = [
    {'title': 'Поиск', 'screen': SearchScreen(), 'icon': Icons.search},
    {'title': 'Блокноты', 'screen': NotebooksScreen(), 'icon': Icons.book},
    {'title': 'Заметки', 'screen': NotesScreen(), 'icon': Icons.note},
    {
      'title': 'Обратные отсчёты',
      'screen': CountdownsScreen(),
      'icon': Icons.timer,
    },
    {'title': 'Контакты', 'screen': ContactsScreen(), 'icon': Icons.contacts},
    {'title': 'Аккаунт', 'screen': AccountScreen(), 'icon': Icons.person},
    {'title': 'Магазин', 'screen': StoreScreen(), 'icon': Icons.store},
    {
      'title': 'Метки',
      'screen': TagsScreen(),
      'icon': Icons.tag,
    }, // Добавляем экран меток
  ];

  // Функция для переключения между вкладками
  void _onItemTapped(int index) {
    if (index == 4) {
      // Если выбрана вкладка "Ещё", показываем выпадающий список
      _showMoreMenu(context);
    } else {
      setState(() {
        _selectedIndex = index; // Обновляем индекс выбранной вкладки
      });
    }
  }

  // Функция для показа выпадающего списка "Ещё"
  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: _moreScreens.length,
          itemBuilder: (context, index) {
            final screen = _moreScreens[index];
            return ListTile(
              leading: Icon(
                screen['icon'],
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                screen['title'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onTap: () {
                Navigator.pop(context); // Закрываем меню
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => screen['screen']),
                ); // Переходим на выбранный экран
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300), // Анимация переключения
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _mainScreens.elementAt(
          _selectedIndex,
        ), // Отображаем текущий экран
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Задачи'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Календарь',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: 'Матрица'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Ещё'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
