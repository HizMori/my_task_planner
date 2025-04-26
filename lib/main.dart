import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/eisenhower_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/search_screen.dart';
import 'screens/notebooks_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/countdowns_screen.dart';
import 'screens/account_screen.dart';
import 'screens/store_screen.dart';
import 'screens/tags_screen.dart';
import 'screens/create_task_screen.dart';
import 'screens/create_note_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Planner',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2A9D8F), // Акцентный зелёный
        scaffoldBackgroundColor: const Color(0xFFF5F5DC), // Кремовый фон
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
            backgroundColor: const Color(0xFF2A9D8F),
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
        primaryColor: const Color(0xFF2A9D8F),
        scaffoldBackgroundColor: const Color(0xFF1C2526),
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
            backgroundColor: const Color(0xFF2A9D8F),
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
      const HomeScreen(), // Главный экран
      const TaskListScreen(), // Задачи
      const CalendarScreen(), // Календарь
      const Scaffold(), // Заглушка для "Ещё"
    ];
    _screenStack.add(_mainScreens[_selectedIndex]);
  }

  static const List<Map<String, dynamic>> _moreScreens = [
    {'title': 'Поиск', 'screen': SearchScreen(), 'icon': Icons.search},
    {'title': 'Блокноты', 'screen': NotebooksScreen(), 'icon': Icons.book},
    {
      'title': 'Обратные отсчёты',
      'screen': CountdownsScreen(),
      'icon': Icons.timer,
    },
    {'title': 'Контакты', 'screen': ContactsScreen(), 'icon': Icons.contacts},
    {
      'title': 'Матрица Эйзенхауэра',
      'screen': EisenhowerScreen(),
      'icon': Icons.grid_on,
    },
    {'title': 'Заметки', 'screen': NotesScreen(), 'icon': Icons.notes},
    {'title': 'Аккаунт', 'screen': AccountScreen(), 'icon': Icons.person},
    {'title': 'Магазин', 'screen': StoreScreen(), 'icon': Icons.store},
    {'title': 'Метки', 'screen': TagsScreen(), 'icon': Icons.tag},
    {'title': 'Настройки', 'screen': SettingsScreen(), 'icon': Icons.settings},
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      // "Ещё"
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
      backgroundColor: const Color(0xFFF5F5DC),
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
              leading: Icon(screen['icon'], color: const Color(0xFF2A9D8F)),
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

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5F5DC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  pushScreen(const CreateNoteScreen());
                },
                icon: const Icon(Icons.note, color: Colors.white),
                label: const Text('Новая заметка'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  pushScreen(const CreateTaskScreen());
                },
                icon: const Icon(Icons.check_box, color: Colors.white),
                label: const Text('Новая задача'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  pushScreen(const CountdownsScreen());
                },
                icon: const Icon(Icons.timer, color: Colors.white),
                label: const Text('Новый обратный отсчёт'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        drawer: Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF2A9D8F)),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage(
                        'assets/images/17404f5729d1a652c70d.png',
                      ),
                    ),
                    const SizedBox(width: 16),
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
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        pushScreen(const SearchScreen());
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showCreateOptions(context);
          },
          backgroundColor: const Color(0xFFE76F51),
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 30),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: ClipPath(
          clipper: NavBarClipper(),
          child: BottomAppBar(
            color: const Color(0xFF2A9D8F),
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.home,
                    color:
                        _selectedIndex == 0
                            ? Colors.white
                            : const Color(0xFFB0BEC5),
                  ),
                  onPressed: () => _onItemTapped(0),
                ),
                IconButton(
                  icon: Icon(
                    Icons.checklist,
                    color:
                        _selectedIndex == 1
                            ? Colors.white
                            : const Color(0xFFB0BEC5),
                  ),
                  onPressed: () => _onItemTapped(1),
                ),
                const SizedBox(width: 40),
                IconButton(
                  icon: Icon(
                    Icons.calendar_today,
                    color:
                        _selectedIndex == 2
                            ? Colors.white
                            : const Color(0xFFB0BEC5),
                  ),
                  onPressed: () => _onItemTapped(2),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    color:
                        _selectedIndex == 3
                            ? Colors.white
                            : const Color(0xFFB0BEC5),
                  ),
                  onPressed: () => _onItemTapped(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Кастомный клиппер для создания выреза в BottomAppBar
class NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const notchRadius = 30.0;
    final notchCenter = size.width / 2;

    path.lineTo(notchCenter - notchRadius, 0);
    path.quadraticBezierTo(notchCenter, 0, notchCenter, notchRadius);
    path.quadraticBezierTo(notchCenter, 0, notchCenter + notchRadius, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
