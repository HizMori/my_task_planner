import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  int _currentTextIndex = 0;
  double _dragOffset = 0.0; // Смещение текста при перетаскивании
  late AnimationController _animationController; // Для анимации возврата
  late Animation<double> _animation;

  // Список текстов
  final List<String> _texts = [
    'Привет, это крутой планировщик задач.',
    'Организуй свои задачи легко и быстро!',
    'Планируй свой день с удовольствием!',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Обработка перетаскивания
  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx / 250.0; // Нормализуем смещение относительно ширины области
    });
  }

  // Обработка завершения перетаскивания
  void _onDragEnd(DragEndDetails details) {
    // Проверяем, достаточно ли перетащили, чтобы сменить текст
    if (_dragOffset.abs() > 0.5) {
      setState(() {
        if (_dragOffset > 0) {
          // Перетаскивание вправо (предыдущий текст)
          _currentTextIndex = (_currentTextIndex - 1 + _texts.length) % _texts.length;
        } else {
          // Перетаскивание влево (следующий текст)
          _currentTextIndex = (_currentTextIndex + 1) % _texts.length;
        }
        _dragOffset = 0.0; // Сбрасываем смещение после смены текста
      });
    } else {
      // Возвращаем текст в центр с анимацией
      _animation = Tween<double>(begin: _dragOffset, end: 0.0).animate(_animationController);
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Определяем индексы текстов для отображения
    final int nextTextIndex = (_currentTextIndex + 1) % _texts.length;
    final int prevTextIndex = (_currentTextIndex - 1 + _texts.length) % _texts.length;

    // Выбираем изображение в зависимости от темы
    final String imagePath = Theme.of(context).brightness == Brightness.light
        ? 'assets/images/welcome_image_dark.png'
        : 'assets/images/welcome_image_light.png';

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
                imagePath,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              // GestureDetector для перетаскивания текста
              GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: Container(
                  width: 250, // Фиксированная ширина области
                  height: 60, // Фиксированная высота области
                  child: ClipRect(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Предыдущий текст (слева)
                        Transform.translate(
                          offset: Offset((_dragOffset - 1.0) * 250, 0), // Смещение влево
                          child: Text(
                            _texts[prevTextIndex],
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        // Текущий текст (в центре)
                        Transform.translate(
                          offset: Offset(_dragOffset * 250, 0), // Текущее смещение
                          child: Text(
                            _texts[_currentTextIndex],
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        // Следующий текст (справа)
                        Transform.translate(
                          offset: Offset((_dragOffset + 1.0) * 250, 0), // Смещение вправо
                          child: Text(
                            _texts[nextTextIndex],
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
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
                            ? const Color(0xFF7e61f3)
                            : Colors.white,
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
                  minimumSize: const Size(320, 49),
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
                    minimumSize: const Size(320, 49),
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