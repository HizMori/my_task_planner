import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/countdowns_screen.dart';
import 'screens/account_screen.dart';
import 'screens/create_task_screen.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isFirstLaunch || !isLoggedIn) {
      return const WelcomeScreen();
    }
    return const MainScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Planner',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF7e61f3),
        scaffoldBackgroundColor: const Color(0xFFeef4ff),
        textTheme: TextTheme(
          bodyMedium: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF000000),
            fontWeight: FontWeight.normal,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF000000),
          ),
          headlineLarge: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7e61f3),
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.normal,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7e61f3),
          ),
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7e61f3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ).copyWith(
            textStyle: MaterialStateProperty.all(
              GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Color(0xFFeef4ff),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF7e61f3),
        scaffoldBackgroundColor: const Color(0xFF1C2526),
        textTheme: TextTheme(
          bodyMedium: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFFFFFFFF),
            fontWeight: FontWeight.normal,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFFFFF),
          ),
          headlineLarge: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7e61f3),
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white70,
            fontWeight: FontWeight.normal,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7e61f3),
          ),
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7e61f3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ).copyWith(
            textStyle: MaterialStateProperty.all(
              GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Color(0xFF1C2526),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Ошибка при загрузке')),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}

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
      const HomeScreen(),
      const TaskListScreen(),
      const CalendarScreen(),
      const Scaffold(),
    ];
    _screenStack.add(_mainScreens[_selectedIndex]);
  }

  static const List<Map<String, dynamic>> _moreScreens = [
    {
      'title': 'Обратные отсчёты',
      'screen': CountdownsScreen(),
      'icon': Icons.timer,
    },
    {'title': 'Контакты', 'screen': ContactsScreen(), 'icon': Icons.contacts},
    {'title': 'Аккаунт', 'screen': AccountScreen(), 'icon': Icons.person},
    {'title': 'Настройки', 'screen': SettingsScreen(), 'icon': Icons.settings},
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      // Ничего не делаем, так как PopupMenuButton сам обрабатывает нажатие
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
    Future.delayed(Duration.zero, () {
      if (_screenStack.length > 1) {
        setState(() {});
      }
    });
  }

  void popScreen() {
    if (_screenStack.length > 1) {
      setState(() {
        _screenStack.removeLast();
      });
      setState(() {});
    }
  }

  Future<bool> _onWillPop() async {
    if (_screenStack.length > 1) {
      popScreen();
      return false;
    }
    return true;
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFeef4ff),
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
                  pushScreen(const CreateTaskScreen());
                },
                icon: const Icon(Icons.check_box, color: Colors.white),
                label: const Text('Новая задача'),
                style: ElevatedButton.styleFrom(
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
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
          backgroundColor: const Color(0xFFf37e61),
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 2.0,
          focusElevation: 4.0,
          child: const Icon(Icons.add, size: 30),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.light
                    ? Colors.black.withOpacity(0.04)
                    : Colors.white.withOpacity(0.04),
                offset: const Offset(0, 0),
                blurRadius: 20,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: theme.brightness == Brightness.light
                    ? Colors.black.withOpacity(0.04)
                    : Colors.white.withOpacity(0.04),
                offset: const Offset(-1, -1),
                blurRadius: 25,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: theme.brightness == Brightness.light
                    ? Colors.black.withOpacity(0.04)
                    : Colors.white.withOpacity(0.04),
                offset: const Offset(2, -2),
                blurRadius: 25,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: theme.brightness == Brightness.light
                    ? Colors.black.withOpacity(0.02)
                    : Colors.white.withOpacity(0.02),
                offset: const Offset(0, -3),
                blurRadius: 40,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipPath(
            clipper: NavBarClipper(),
            child: BottomAppBar(
              color: theme.scaffoldBackgroundColor,
              shape: const CircularNotchedRectangle(),
              notchMargin: 8.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.home,
                      color: _selectedIndex == 0
                          ? const Color(0xFF7e61f3)
                          : const Color(0xFFB0BEC5),
                    ),
                    onPressed: () => _onItemTapped(0),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.checklist,
                      color: _selectedIndex == 1
                          ? const Color(0xFF7e61f3)
                          : const Color(0xFFB0BEC5),
                    ),
                    onPressed: () => _onItemTapped(1),
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    icon: Icon(
                      Icons.calendar_today,
                      color: _selectedIndex == 2
                          ? const Color(0xFF7e61f3)
                          : const Color(0xFFB0BEC5),
                    ),
                    onPressed: () => _onItemTapped(2),
                  ),
                  PopupMenuButton<int>(
                    onSelected: (index) {
                      setState(() {
                        _screenStack.add(_moreScreens[index]['screen']);
                      });
                    },
                    itemBuilder: (context) => _moreScreens.asMap().entries.map((entry) {
                      final index = entry.key;
                      final screen = entry.value;
                      return PopupMenuItem<int>(
                        value: index,
                        child: Row(
                          children: [
                            Icon(
                              screen['icon'],
                              color: const Color(0xFF7e61f3),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              screen['title'],
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    icon: Icon(
                      Icons.more_horiz,
                      color: _selectedIndex == 3
                          ? const Color(0xFF7e61f3)
                          : const Color(0xFFB0BEC5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const notchRadius = 30.0;
    const cornerRadius = 20.0;
    final notchCenter = size.width / 2;

    path.moveTo(0, size.height);
    path.lineTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.lineTo(notchCenter - notchRadius, 0);
    path.quadraticBezierTo(notchCenter, 0, notchCenter, notchRadius);
    path.quadraticBezierTo(notchCenter, 0, notchCenter + notchRadius, 0);
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}