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
import 'screens/tags_screen.dart'; // Экран управления метками
import 'screens/create_task_screen.dart'; // Экран создания задачи

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
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
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
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

// Виджет для быстрого создания
class CreateWidget extends StatelessWidget {
  const CreateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.menu), // Кнопка для открытия Drawer
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Новая заметка, задача или что-то ещё...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onTap: () {
                MainScreen.of(context)?.pushScreen(const SearchScreen());
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      MainScreen.of(context)?.pushScreen(const NotesScreen());
                    },
                    icon: const Icon(Icons.note),
                    label: const Text('Новая заметка'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      MainScreen.of(
                        context,
                      )?.pushScreen(const CreateTaskScreen());
                    },
                    icon: const Icon(Icons.check_box),
                    label: const Text('Новая задача'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B59B6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                MainScreen.of(context)?.pushScreen(const CountdownsScreen());
              },
              icon: const Icon(Icons.timer),
              label: const Text('Новый обратный отсчёт'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Главный экран с нижней навигацией
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();

  static _MainScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainScreenState>();
  }
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screenStack = [];
  late List<Widget> _mainScreens;

  int get screenStackLength => _screenStack.length;

  @override
  void initState() {
    super.initState();
    _mainScreens = [
      const CreateWidget(),
      const TaskListScreen(),
      const CalendarScreen(),
      const EisenhowerScreen(),
    ];
    _screenStack.add(_mainScreens[_selectedIndex]);
  }

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
    {'title': 'Метки', 'screen': TagsScreen(), 'icon': Icons.tag},
    {'title': 'Настройки', 'screen': SettingsScreen(), 'icon': Icons.settings},
  ];

  void _onItemTapped(int index) {
    if (index == 4) {
      _showMoreMenu(context);
    } else {
      setState(() {
        _selectedIndex = index;
        _screenStack.clear();
        _screenStack.add(_mainScreens[_selectedIndex]);
      });
    }
  }

  void pushScreen(Widget screen) {
    setState(() {
      _screenStack.add(screen);
    });
  }

  void popScreen() {
    if (_screenStack.length > 1) {
      setState(() {
        _screenStack.removeLast();
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_screenStack.length > 1) {
      popScreen();
      return false;
    }
    return true;
  }

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
                Navigator.pop(context);
                setState(() {
                  _screenStack.add(screen['screen']);
                });
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Row(
                  children: [
                    // Аватар
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage(
                        'assets/images/17404f5729d1a652c70d.png', // Путь на изображение аватара
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Имя пользователя
                    Expanded(
                      child: Text(
                        'Kawai Fukuro',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Кнопки Поиск и Настройки
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context); // Закрываем Drawer
                        pushScreen(const SearchScreen());
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context); // Закрываем Drawer
                        pushScreen(const SettingsScreen());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _screenStack.last,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Создать'),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Задачи'),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Календарь',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_on),
              label: 'Матрица',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Ещё'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
