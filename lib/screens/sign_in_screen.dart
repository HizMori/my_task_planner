import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'signup_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Состояние видимости пароля
  bool _isPasswordVisible = false;
  // Состояние переключателя "Запомнить меня"
  bool _isRememberMe = true;
  // FocusNode для отслеживания фокуса полей
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Добавляем слушатели для фокуса
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // Очищаем FocusNode
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Метод для установки состояния входа и перехода на MainScreen
  Future<void> _handleLogin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('isFirstLaunch', false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeef4ff),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Логотип
                  Container(
                    child: const Icon(
                      Icons.task_alt,
                      size: 100,
                      color: Color(0xFF7e61f3),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Task manager',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Вход',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Поле Ваша почта
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: _emailFocusNode.hasFocus
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: TextFormField(
                      focusNode: _emailFocusNode,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.email,
                          color: _emailFocusNode.hasFocus
                              ? const Color(0xFF7e61f3)
                              : Colors.grey,
                        ),
                        hintText: 'Ваша почта',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF7e61f3), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Поле пароль
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: _passwordFocusNode.hasFocus
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: TextFormField(
                      focusNode: _passwordFocusNode,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.lock,
                          color: _passwordFocusNode.hasFocus
                              ? const Color(0xFF7e61f3)
                              : Colors.grey,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        hintText: 'Пароль',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF7e61f3), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  // "Забыл пароль" и "Запомнить меня" на разных уровнях
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Забыл пароль?',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF7e61f3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SwitchTheme(
                        data: SwitchThemeData(
                          trackOutlineColor: MaterialStateProperty.resolveWith(
                            (states) {
                              if (states.contains(MaterialState.selected)) {
                                return const Color(0xFF7e61f3);
                              }
                              return Colors.grey.withOpacity(0.3);
                            },
                          ),
                          trackOutlineWidth: MaterialStateProperty.all(1.0),
                        ),
                        child: Switch(
                          value: _isRememberMe,
                          onChanged: (value) {
                            setState(() {
                              _isRememberMe = value;
                            });
                          },
                          activeColor: const Color(0xFF7e61f3),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white,
                          inactiveThumbColor: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Запомнить меня',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Кнопка Sign in
                  ElevatedButton(
                    onPressed: () => _handleLogin(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7e61f3),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Вход',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ИЛИ с полосками
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color.fromARGB(84, 158, 158, 158),
                          margin: const EdgeInsets.only(right: 10),
                        ),
                      ),
                      Text(
                        'ИЛИ',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color.fromARGB(84, 158, 158, 158),
                          margin: const EdgeInsets.only(left: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Социальные кнопки (заглушка)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.g_mobiledata,
                          size: 40,
                          color: Colors.grey,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.language,
                          size: 40,
                          color: Colors.grey,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.telegram,
                          size: 40,
                          color: Colors.grey,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Регистрация
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "У вас нет аккаунта? ",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Зарегистрируйтесь',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF7e61f3),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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