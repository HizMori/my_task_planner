import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentTextIndex = 0;

  // Список текстов
  final List<String> _texts = [
    'Привет, это крутой планировщик задач.',
    'Организуй свои задачи легко и быстро!',
    'Планируй свой день с удовольствием!',
  ];

  // Обработка свайпа влево (следующий текст)
  void _onSwipeLeft() {
    setState(() {
      _currentTextIndex = (_currentTextIndex + 1) % _texts.length;
    });
  }

  // Обработка свайпа вправо (предыдущий текст)
  void _onSwipeRight() {
    setState(() {
      _currentTextIndex =
          (_currentTextIndex - 1 + _texts.length) % _texts.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    'Добро пожаловать',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Task Manager',
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Image.asset(
                'assets/images/welcome_image.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              // GestureDetector для обработки свайпов
              GestureDetector(
                onHorizontalDragEnd: (DragEndDetails details) {
                  // Свайп влево (velocity.x < 0)
                  if (details.velocity.pixelsPerSecond.dx < 0) {
                    _onSwipeLeft();
                  }
                  // Свайп вправо (velocity.x > 0)
                  else if (details.velocity.pixelsPerSecond.dx > 0) {
                    _onSwipeRight();
                  }
                },
                child: Container(
                  width: 250,
                  child: SizedBox(
                    height: 60, // Фиксированная высота для текста
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        final offsetAnimation = Tween<Offset>(
                          begin: const Offset(1.0, 0.0), // Смещение вправо
                          end: const Offset(0.0, 0.0), // Конечная позиция
                        ).animate(animation);
                        final reverseOffsetAnimation = Tween<Offset>(
                          begin: const Offset(-1.0, 0.0), // Смещение влево
                          end: const Offset(0.0, 0.0), // Конечная позиция
                        ).animate(animation);
                        return ClipRect(
                          child: SlideTransition(
                            position: child.key == ValueKey(_currentTextIndex)
                                ? offsetAnimation
                                : reverseOffsetAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _texts[_currentTextIndex],
                        key: ValueKey(_currentTextIndex),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Индикаторы (точки)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_texts.length, (index) {
                  return Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: _currentTextIndex == index
                            ? const Color(0xFF7e61f3) // Изменён цвет активного индикатора
                            : Colors.white, // Неактивные индикаторы остаются серыми
                      ),
                      if (index < _texts.length - 1) const SizedBox(width: 4),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(320, 49), // Новая ширина и высота
                ).merge(Theme.of(context).elevatedButtonTheme.style),
                child: const Text('Войти'),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(0, 1),
                      blurRadius: 10.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.scaffoldBackgroundColor,
                    foregroundColor: const Color(0xFF7e61f3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF7e61f3)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(320, 49), // Новая ширина и высота
                    elevation: 0,
                  ),
                  child: const Text('Зарегистрироваться'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}