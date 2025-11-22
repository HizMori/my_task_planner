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
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dlqknakuectcbciqssaz.supabase.co',  // Вставь из Dashboard
    anonKey: 'sb_publishable_nzc7YWw8V8N6HwDdzQhI6g_o2sjALYS',  // Вставь из Dashboard
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Метод для определения начального экрана на основе статуса входа и первого запуска
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
          backgroundColor: const Color(0xFFeef4ff),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFFeef4ff),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF000000),
            fontWeight: FontWeight.normal,
          ),
          elevation: 8,
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
            color: const Color(0xFF000000),
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
          backgroundColor: const Color(0xFF1C2526),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF1C2526),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF000000),
            fontWeight: FontWeight.normal,
          ),
          elevation: 8,
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
  OverlayEntry? _overlayEntry;
  double _rotationAngle = 0.0; // Угол поворота для анимации (0 - плюс, 0.125 - крестик вправо)
  final List<bool> _isButtonPressed = List.filled(2, false); // Состояние для каждой кнопки в меню
  bool _isAnimating = false; // Флаг для блокировки анимации во время выполнения

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

  static const List<Map<String, dynamic>> _createOptions = [
    {
      'title': 'Новая задача',
      'screen': CreateTaskScreen(),
      'icon': Icons.check_box,
    },
    {
      'title': 'Новый обратный отсчёт',
      'screen': CountdownsScreen(),
      'icon': Icons.timer,
    },
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      // Ничего не делаем, так как PopupMenuButton сам обрабатывает нажатие
    } else {
      setState(() {
        _selectedIndex = index;
        _screenStack.clear();
        _screenStack.add(_mainScreens[_selectedIndex]);
        _hideCreateMenu(); // Закрываем меню и сбрасываем иконку при переключении экрана
      });
    }
  }

  void pushScreen(Widget screen) {
    setState(() {
      _screenStack.add(screen);
      _hideCreateMenu(); // Закрываем меню и сбрасываем иконку при переходе на новый экран
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
        _hideCreateMenu(); // Закрываем меню и сбрасываем иконку при возврате назад
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

  void _showCreateMenu(BuildContext context, Offset buttonPosition) {
    if (_isAnimating) return; // Игнорируем нажатия во время анимации
    setState(() {
      _isAnimating = true; // Блокируем новые нажатия
      _isButtonPressed.fillRange(0, _isButtonPressed.length, false);
      _rotationAngle = 0.125; // Поворачиваем иконку на 45 градусов вправо (плюс → крестик)
    });

    // Закрываем предыдущее меню, если оно открыто
    _hideCreateMenu();

    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    if (overlay == null) {
      print('Overlay not found');
      return;
    }

    final RenderBox? button = context.findRenderObject() as RenderBox;
    if (button == null) {
      print('Button render object not found');
      return;
    }

    // Настройка ширины меню
    final menuWidth = _createOptions.length * 60.0;

    // Настройка высоты меню
    const triangleHeight = 10.0;
    final menuHeight = 70.0 + triangleHeight;
    final screenWidth = overlay.size.width;

    // Центрирование меню над серединой кнопки
    final left = (buttonPosition.dx + (button.size.width / 2) - (menuWidth / 2)).clamp(0.0, screenWidth - menuWidth);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Прозрачный слой для закрытия меню при тапе вне его
          GestureDetector(
            onTap: _hideCreateMenu,
            child: Container(
              color: Colors.transparent,
            ),
          ),
          // Меню
          Positioned(
            left: left,
            top: buttonPosition.dy - 70.0 - 10,
            child: Material(
              elevation: 8,
              color: Colors.transparent,
              child: PhysicalShape(
                clipper: MenuClipper(),
                color: Theme.of(context).popupMenuTheme.color ?? Theme.of(context).scaffoldBackgroundColor,
                shadowColor: Colors.black.withOpacity(0.2),
                elevation: 8,
                child: ClipPath(
                  clipper: MenuClipper(),
                  child: Container(
                    height: menuHeight,
                    width: menuWidth,
                    color: Theme.of(context).popupMenuTheme.color ?? Theme.of(context).scaffoldBackgroundColor,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _createOptions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        return GestureDetector(
                          onTapDown: (_) {
                            setState(() {
                              _isButtonPressed[index] = true;
                            });
                          },
                          onTapUp: (_) {
                            _hideCreateMenu();
                            setState(() {
                              _isButtonPressed[index] = false;
                              _screenStack.add(option['screen']);
                            });
                          },
                          onTapCancel: () {
                            setState(() {
                              _isButtonPressed[index] = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            child: Icon(
                              option['icon'],
                              color: _isButtonPressed[index] ? const Color(0xFF7e61f3) : Colors.grey[400],
                              size: 30,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    try {
      Overlay.of(context).insert(_overlayEntry!);
      // Снимаем блокировку после завершения анимации
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _isAnimating = false;
        });
      });
    } catch (e) {
      print('Error inserting OverlayEntry: $e');
      setState(() {
        _isAnimating = false;
      });
    }
  }

  void _hideCreateMenu() {
    if (_overlayEntry != null) {
      setState(() {
        _rotationAngle = 0; // Обнуляем угол
        _isAnimating = true; // Блокируем новые нажатия
      });
      _overlayEntry?.remove();
      _overlayEntry = null;
      // Снимаем блокировку после завершения анимации
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _isAnimating = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _hideCreateMenu();
    super.dispose();
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
        floatingActionButton: Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              if (_isAnimating) return; // Игнорируем нажатия во время анимации
              final RenderBox? button = context.findRenderObject() as RenderBox;
              if (button != null) {
                final Offset buttonPosition = button.localToGlobal(Offset.zero);
                if (_overlayEntry == null) {
                  _showCreateMenu(context, buttonPosition);
                } else {
                  _hideCreateMenu();
                }
              } else {
                print('Button render object not found');
              }
            },
            child: AnimatedRotation(
              turns: _rotationAngle, // Используем угол для анимации
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut, // Плавная кривая анимации
              child: FloatingActionButton(
                onPressed: null, // Отключаем стандартный onPressed
                backgroundColor: const Color(0xFFf37e61),
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 2.0,
                focusElevation: 4.0,
                child: Icon(
                  Icons.add, // Всегда используем иконку плюс, поворот создаёт эффект крестика
                  size: 30,
                ),
              ),
            ),
          ),
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
                    offset: const Offset(0, -220),
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

class MenuClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const cornerRadius = 12.0; // Радиус закругления углов
    const triangleHeight = 10.0; // Высота треугольника
    const triangleWidth = 20.0; // Ширина треугольника
    final triangleCenter = size.width / 2; // Центр треугольника

    // Начало с левого верхнего угла
    path.moveTo(0, cornerRadius);
    // Левый верхний закругленный угол
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    // Правая верхняя сторона
    path.lineTo(size.width - cornerRadius, 0);
    // Правый верхний закругленный угол
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    // Правая сторона
    path.lineTo(size.width, size.height - cornerRadius - triangleHeight);
    // Правый нижний закругленный угол
    path.quadraticBezierTo(size.width, size.height - triangleHeight, size.width - cornerRadius, size.height - triangleHeight);
    // Нижняя сторона до начала треугольника
    path.lineTo(triangleCenter + (triangleWidth / 2), size.height - triangleHeight);
    // Правая часть треугольника
    path.lineTo(triangleCenter, size.height);
    // Левая часть треугольника
    path.lineTo(triangleCenter - (triangleWidth / 2), size.height - triangleHeight);
    // Нижняя сторона до левого нижнего угла
    path.lineTo(cornerRadius, size.height - triangleHeight);
    // Левый нижний закругленный угол
    path.quadraticBezierTo(0, size.height - triangleHeight, 0, size.height - cornerRadius - triangleHeight);
    // Левая сторона
    path.lineTo(0, cornerRadius);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
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