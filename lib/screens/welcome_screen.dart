import 'package:flutter/material.dart';
import 'sign_in_screen.dart'; // Импорт экрана входа
import 'signup_screen.dart'; // Импорт экрана регистрации

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Фон из темы
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Добро пожаловать в Task Manager',
                style: theme.textTheme.headlineSmall, // Стиль заголовка из темы
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Icon(
                Icons
                    .group_work, // Иконка с людьми и галочкой (пример из material)
                size: 100,
                color: theme.textTheme.bodyMedium?.color, // Цвет текста из темы
              ),
              const SizedBox(height: 20),
              Text(
                'Привет, здесь тебя ждёт много дел, это крутой планировщик задач.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.circle, size: 8, color: Colors.grey),
                  SizedBox(width: 4),
                  Icon(Icons.circle, size: 8, color: Colors.grey),
                  SizedBox(width: 4),
                  Icon(Icons.circle, size: 8, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Переход на экран входа
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF9C27B0,
                  ), // Фиолетовый фон для "Sign in"
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(
                    double.infinity,
                    0,
                  ), // Ширина на весь экран
                ),
                child: const Text('Войти'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Переход на экран регистрации
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300], // Серый фон для "Sign up"
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: const Text('Зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
