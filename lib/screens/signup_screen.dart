import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sign_in_screen.dart'; // Импорт экрана входа

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Состояние видимости пароля
  bool _isPasswordVisible = false;

  // FocusNode для отслеживания фокуса полей
  final FocusNode _loginFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Добавляем слушатели для фокуса
    _loginFocusNode.addListener(() => setState(() {}));
    _emailFocusNode.addListener(() => setState(() {}));
    _phoneFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // Очищаем FocusNode
    _loginFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Цвета в зависимости от темы
    final backgroundColor = isDarkMode ? Colors.grey[900] : const Color(0xFFeef4ff);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.grey;
    final fieldFillColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final dividerColor = isDarkMode ? Colors.grey[700] : const Color.fromARGB(84, 158, 158, 158);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Логотип (заглушка, как в SignInScreen)
                Icon(
                  Icons.task_alt,
                  size: 100,
                  color: isDarkMode ? Colors.white : const Color(0xFF7e61f3),
                ),
                const SizedBox(height: 20),
                Text(
                  'Task manager',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Регистрация',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                // Поле Login
                Container(
                  decoration: BoxDecoration(
                    boxShadow: _loginFocusNode.hasFocus
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.2),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: TextFormField(
                    focusNode: _loginFocusNode,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.person,
                        color: _loginFocusNode.hasFocus
                            ? const Color(0xFF7e61f3)
                            : (isDarkMode ? Colors.grey[400] : Colors.grey),
                      ),
                      hintText: 'Ваш логин',
                      hintStyle: GoogleFonts.poppins(color: hintColor),
                      filled: true,
                      fillColor: fieldFillColor,
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
                // Поле email
                Container(
                  decoration: BoxDecoration(
                    boxShadow: _emailFocusNode.hasFocus
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.2),
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
                            : (isDarkMode ? Colors.grey[400] : Colors.grey),
                      ),
                      hintText: 'Ваша почта',
                      hintStyle: GoogleFonts.poppins(color: hintColor),
                      filled: true,
                      fillColor: fieldFillColor,
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
                // Поле phone
                Container(
                  decoration: BoxDecoration(
                    boxShadow: _phoneFocusNode.hasFocus
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.2),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: TextFormField(
                    focusNode: _phoneFocusNode,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.phone,
                        color: _phoneFocusNode.hasFocus
                            ? const Color(0xFF7e61f3)
                            : (isDarkMode ? Colors.grey[400] : Colors.grey),
                      ),
                      hintText: 'Ваш телефон',
                      hintStyle: GoogleFonts.poppins(color: hintColor),
                      filled: true,
                      fillColor: fieldFillColor,
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
                // Поле password
                Container(
                  decoration: BoxDecoration(
                    boxShadow: _passwordFocusNode.hasFocus
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.2),
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
                            : (isDarkMode ? Colors.grey[400] : Colors.grey),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: _isPasswordVisible
                              ? const Color(0xFF7e61f3)
                              : (isDarkMode ? Colors.grey[400] : Colors.grey),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      hintText: 'Пароль',
                      hintStyle: GoogleFonts.poppins(color: hintColor),
                      filled: true,
                      fillColor: fieldFillColor,
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
                // Кнопка Sign up
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7e61f3),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Регистрация',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // OR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: dividerColor,
                        margin: const EdgeInsets.only(right: 10),
                      ),
                    ),
                    Text(
                      'ИЛИ',
                      style: GoogleFonts.poppins(
                        color: hintColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: dividerColor,
                        margin: const EdgeInsets.only(left: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Социальные кнопки (заглушка, как в SignInScreen)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.g_mobiledata,
                        size: 40,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.language,
                        size: 40,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.telegram,
                        size: 40,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Вход
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "У вас уже есть аккаунт? ",
                      style: GoogleFonts.poppins(color: hintColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Войти',
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
    );
  }
}