import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/countdowns_screen.dart';
import 'screens/account_screen.dart';
import 'screens/create_task_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/group_list_screen.dart';
import 'screens/create_group_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'themes/app_theme.dart';
import 'themes/theme_provider.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dlqknakuectcbciqssaz.supabase.co',
    anonKey: 'sb_publishable_nzc7YWw8V8N6HwDdzQhI6g_o2sjALYS',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Метод для определения начального экрана на основе статуса входа и первого запуска
  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isFirstLaunch) {
      await prefs.setBool('isFirstLaunch', false);
      return const WelcomeScreen();
    }

    if (!isLoggedIn) {
      return const WelcomeScreen();
    }

    // Пробуем онлайн-вход
    try {
      final response = await supabase.auth.getUser();
      final user = response.user;
      if (user != null) {
        await AuthService.instance.syncCurrentUser();
        return const MainScreen();
      }
    } catch (e) {
      print('Онлайн-аутентификация не удалась: $e');
    }

    // Офлайн-вход: если есть локальные данные
    final userId = await AuthService.instance.getCurrentUserId();
    if (userId != null) {
      final localUser = await DatabaseService.instance.readUserById(userId);
      if (localUser != null) {
        print('Офлайн-вход: пользователь найден в локальной БД');
        return const MainScreen();
      }
    }

    // Очищаем флаг, если не удалось войти
    await AuthService.instance.setLoggedIn(false);
    return const WelcomeScreen();
  }

  Future<ThemeMode> _loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  if (!isLoggedIn) return ThemeMode.system;

  final userId = await AuthService.instance.getCurrentUserId();
  if (userId == null) return ThemeMode.system;

  final settings = await DatabaseService.instance.readAppSettings(userId);
  final theme = settings?.theme ?? 'system';

  switch (theme) {
    case 'light': return ThemeMode.light;
    case 'dark': return ThemeMode.dark;
    default: return ThemeMode.system;
  }
}

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Task Planner',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'RU'),
            Locale('en', 'US'),
          ],
          locale: const Locale('ru'),
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode, // ✅ Теперь безопасно
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
      },
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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin{
  int _selectedIndex = 0;
  final List<Widget> _screenStack = [];
  late List<Widget> _mainScreens;
  OverlayEntry? _overlayEntry;
  double _rotationAngle = 0.0; // Угол поворота для анимации (0 - плюс, 0.125 - крестик вправо)
  late List<bool> _isButtonPressed; // Состояние для каждой кнопки в меню
  bool _isAnimating = false; // Флаг для блокировки анимации во время выполнения
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  OverlayEntry? _moreOverlayEntry;
  bool _isMoreMenuVisible = false;
  double _moreMenuOffsetY = 0.0; // Для анимации slide
  late AnimationController _moreMenuController;
  int _previousSelectedIndex = 0;  // Новая переменная для хранения предыдущего состояния
  bool _isMenuOpenUpward = true;
  late AnimationController _createMenuController;
  late Animation<double> _createMenuSlide;
  late Animation<double> _createMenuFade;

  int get screenStackLength => _screenStack.length;

  @override
  void initState() {
    super.initState();
    _moreMenuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _mainScreens = [
      const HomeScreen(),
      TaskListScreen(),
      GroupListScreen(),
      const Scaffold(),
    ];
    _screenStack.add(_mainScreens[_selectedIndex]);
    _isButtonPressed = List.filled(_createOptions.length, false);
    
    _createMenuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _createMenuSlide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _createMenuController, curve: Curves.easeOut),
    );

    _createMenuFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _createMenuController, curve: Curves.easeIn),
    );

    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged
      .map((results) => results.isNotEmpty ? results.first : ConnectivityResult.none)
      .listen((ConnectivityResult result) {
        if (result == ConnectivityResult.wifi || result == ConnectivityResult.mobile) {
          _syncIfOnline();
      }
    });
  }

  static const List<Map<String, dynamic>> _moreScreens = [
    {
      'title': 'Календарь',
      'screen': CalendarScreen(),
      'icon': Icons.calendar_today,
    },
    {
      'title': 'Обратные отсчёты',
      'screen': CountdownsScreen(),
      'icon': Icons.timer,
    },
    {
      'title': 'Контакты',
      'screen': ContactsScreen(),
      'icon': Icons.contacts,
    },
    {
      'title': 'Аккаунт',
      'screen': AccountScreen(),
      'icon': Icons.person,
    },
    {
      'title': 'Настройки',
      'screen': SettingsScreen(),
      'icon': Icons.settings,
    },
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
    {
      'title': 'Новая группа',
      'screen': CreateGroupScreen(),
      'icon': Icons.groups,
    },
  ];

  // Синхронизация при каждом переходе
  Future<void> _syncIfOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        await AuthService.instance.syncCurrentUser();
        await DatabaseService.instance.syncTasksToSupabase();
        await DatabaseService.instance.syncMessagesToSupabase();
      }
    } on SocketException {
      // Нет интернета — пропускаем
    } catch (e) {
      print('Ошибка проверки интернета: $e');
    }
  }

  void _onItemTapped(int index) async {
    if (index == 3) {
      // Меню — не синхронизируем
    } else {
      setState(() {
        _selectedIndex = index;
        _screenStack.clear();
        _screenStack.add(_mainScreens[_selectedIndex]);
        _hideCreateMenu();
      });
      // Синхронизация при переключении вкладок
      await _syncIfOnline();
    }
  }

  void pushScreen(Widget screen) {
    setState(() {
      _screenStack.add(screen);
      _hideCreateMenu();
    });
    // Синхронизация при переходе на новый экран
    _syncIfOnline();
  }

  void popScreen() {
    if (_screenStack.length > 1) {
      setState(() {
        _screenStack.removeLast();
        _hideCreateMenu();
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
    if (_isAnimating || _overlayEntry != null) return;

    setState(() {
      _isAnimating = true;
      _isButtonPressed.fillRange(0, _isButtonPressed.length, false);
      _rotationAngle = 0.125;
    });

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Size overlaySize = overlay.size;

    final menuWidth = _createOptions.length * 60.0;
    const triangleHeight = 10.0;
    final menuHeight = 70.0 + triangleHeight;
    final screenWidth = overlaySize.width;

    final left = (buttonPosition.dx + (button.size.width / 2) - (menuWidth / 2)).clamp(0.0, screenWidth - menuWidth);

    // Сбрасываем анимацию
    _createMenuController.reset();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
      final isDarkMode = theme.brightness == Brightness.dark;
      
      // Определяем цвета как в навигации
      final activeColor = theme.primaryColor;
      final inactiveColor = isDarkMode ? Colors.grey[500]! : Colors.grey[400];
        
        return Stack(
          children: [
            // Фон — закрывает всё и закрывает меню при тапе
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideCreateMenu,
                child: AnimatedBuilder(
                  animation: _createMenuFade,
                  builder: (context, child) => Container(
                    color: Colors.transparent,
                  ),
                ),
                behavior: HitTestBehavior.translucent,
              ),
            ),
            // Анимированное меню
            AnimatedBuilder(
              animation: _createMenuController,
              builder: (context, child) => Positioned(
                left: left,
                top: buttonPosition.dy - 70.0 - 10 - _createMenuSlide.value,
                child: Opacity(
                  opacity: _createMenuFade.value,
                  child: Material(
                    elevation: 8,
                    color: Colors.transparent,
                    child: PhysicalShape(
                      clipper: MenuClipper(),
                      color: isDarkMode 
                          ? (theme.popupMenuTheme.color ?? Colors.grey[800]!)
                          : (theme.popupMenuTheme.color ?? const Color(0xFFF8F9FA)),
                      shadowColor: isDarkMode 
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.2),
                      elevation: 8,
                      child: ClipPath(
                        clipper: MenuClipper(),
                        child: Container(
                          height: menuHeight,
                          width: menuWidth,
                          color: isDarkMode ? Colors.grey[800] : const Color(0xFFF8F9FA),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _createOptions.asMap().entries.map((entry) {
                              final index = entry.key;
                              final option = entry.value;
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (_) {
                                  setState(() {
                                    _isButtonPressed[index] = true;
                                  });
                                },
                                onTapUp: (_) {
                                  _hideCreateMenu();
                                  setState(() {
                                    _isButtonPressed[index] = false;
                                  });
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => option['screen']),
                                  );
                                },
                                onTapCancel: () {
                                  setState(() {
                                    _isButtonPressed[index] = false;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isButtonPressed[index] 
                                        ? (isDarkMode 
                                            ? const Color(0x445F7DFF) 
                                            : const Color(0x337e61f3))
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    option['icon'],
                                    color: _isButtonPressed[index] 
                                      ? theme.primaryColor
                                      : inactiveColor,
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
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context)?.insert(_overlayEntry!);

    // Запускаем анимацию
    _createMenuController.forward();

    // Снимаем блокировку после анимации
    _createMenuController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  void _hideCreateMenu() {
    if (_overlayEntry == null) return;

    setState(() {
      _isAnimating = true;
      _rotationAngle = 0; // Возвращаем + из ×
    });

    // Обратная анимация
    _createMenuController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;

      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  void _hideMoreMenu() {
    if (_moreOverlayEntry != null) {
      // Reverse анимация: slide down
      setState(() {
        _isAnimating = true;
        _isMoreMenuVisible = false;
        _selectedIndex = _previousSelectedIndex;
      });
      _moreMenuController.reverse().then((_) {
        // После окончания анимации — удаляем Overlay
        _moreOverlayEntry?.remove();
        _moreOverlayEntry = null;
        setState(() {
          _isAnimating = false;
        });
      });
    }
  }

  void _showMoreMenu(BuildContext context, Offset buttonPosition, Size buttonSize) {  // Добавили buttonSize как параметр
    if (_isAnimating) return;
    _hideMoreMenu();
    _previousSelectedIndex = _selectedIndex;
    

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final double menuWidth = 200.0;  // Ваша ширина меню
    final double menuHeight = _moreScreens.length * 50.0 + 20.0;  // Примерная высота (подкорректируйте, если нужно)
    final double screenWidth = overlay.size.width;
    final double screenHeight = overlay.size.height;

    // Центрирование по X
    double left = buttonPosition.dx + (buttonSize.width / 2) - (menuWidth / 2);
    left = left.clamp(0.0, screenWidth - menuWidth);  // Не даём уйти за края

    // Позиционирование по Y: выше кнопки для upward меню
    double padding = 20.0;  // Отступ от кнопки
    double initialTop = buttonPosition.dy - menuHeight - padding;

    // Проверка места сверху: если не влезает, открываем ниже (fallback)
    final double availableSpaceAbove = buttonPosition.dy;
    bool openUpward = availableSpaceAbove > menuHeight + padding;
    if (!openUpward) {
      initialTop = buttonPosition.dy + buttonSize.height + padding;
      if (initialTop + menuHeight > screenHeight) {
        initialTop = screenHeight - menuHeight;  // Clamp снизу
      }
    }

    _isMenuOpenUpward = openUpward;

    setState(() {
      _isAnimating = true;
    });

    _moreOverlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        
        return Stack(
          children: [
            GestureDetector(
              onTap: _hideMoreMenu,
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              left: left,
              top: initialTop,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _moreMenuController,
                    curve: Curves.easeOutBack,
                  ),
                ),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _moreMenuController,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    color: isDarkMode 
                        ? Colors.grey[800]!
                        : const Color(0xFFF8F9FA),
                    child: Container(
                      width: menuWidth,
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _moreScreens.asMap().entries.map((entry) {
                          final index = entry.key;
                          final screen = entry.value;
                          return ListTile(
                            leading: Icon(
                              screen['icon'], 
                              color: theme.primaryColor
                            ),
                            title: Text(
                              screen['title'],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            onTap: () {
                              _hideMoreMenu();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => screen['screen']),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );


    Overlay.of(context).insert(_moreOverlayEntry!);
    _moreMenuController.reset();
    _moreMenuController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isAnimating = false;
        _isMoreMenuVisible = true;
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _hideCreateMenu();
    _hideMoreMenu();
    _moreMenuController.dispose();
    _createMenuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Цвета для навигации в зависимости от темы
    final activeColor = theme.primaryColor;
    final inactiveColor = isDarkMode ? Colors.grey[500]! : const Color(0xFFB0BEC5);
    final navBarBgColor = theme.scaffoldBackgroundColor;
    final shadowColor = isDarkMode 
        ? Colors.white.withOpacity(0.04) 
        : Colors.black.withOpacity(0.04);
    final fabColor = const Color(0xFFf37e61); // Цвет FAB остается фиксированным

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
              if (_isAnimating) return;
              final RenderBox? button = context.findRenderObject() as RenderBox?;
              if (button != null) {
                final Offset buttonPosition = button.localToGlobal(Offset.zero);
                if (_overlayEntry == null) {
                  _showCreateMenu(context, buttonPosition);
                } else {
                  _hideCreateMenu(); // Закрываем при повторном нажатии
                }
              }
            },
            child: AnimatedRotation(
              turns: _rotationAngle,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: FloatingActionButton(
                onPressed: null,
                backgroundColor: fabColor,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: isDarkMode ? 4.0 : 2.0,
                child: const Icon(Icons.add, size: 30),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: const Offset(0, 0),
                blurRadius: 20,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: shadowColor,
                offset: const Offset(-1, -1),
                blurRadius: 25,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: shadowColor,
                offset: const Offset(2, -2),
                blurRadius: 25,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: shadowColor,
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
              surfaceTintColor: isDarkMode ? Colors.grey[800] : Colors.white,
              shape: const CircularNotchedRectangle(),
              notchMargin: 8.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.home,
                      color: _selectedIndex == 0 ? activeColor : inactiveColor,
                    ),
                    onPressed: () => _onItemTapped(0),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.checklist,
                      color: _selectedIndex == 1 ? activeColor : inactiveColor,
                    ),
                    onPressed: () => _onItemTapped(1),
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    icon: Icon(
                      Icons.groups,
                      color: _selectedIndex == 2 ? activeColor : inactiveColor,
                    ),
                    onPressed: () => _onItemTapped(2),
                  ),
                  Builder(  // Добавили Builder для правильного context
                    builder: (context) => 
                    IconButton(
                      icon: Icon(
                        Icons.more_horiz,
                        color: _selectedIndex == 3 ? activeColor : inactiveColor,
                      ),
                      onPressed: () {
                        if (_isAnimating) return;
                        final RenderBox button = context.findRenderObject() as RenderBox;
                        final Offset buttonPosition = button.localToGlobal(Offset.zero);
                        final Size buttonSize = button.size;  // Теперь доступен size
                        if (_isMoreMenuVisible) {
                          _hideMoreMenu(); // Это уже сбросит _selectedIndex
                        } else {
                          setState(() {
                            _previousSelectedIndex = _selectedIndex;
                            _selectedIndex = 3;
                          });
                          _showMoreMenu(context, buttonPosition, buttonSize);
                        }
                      },
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