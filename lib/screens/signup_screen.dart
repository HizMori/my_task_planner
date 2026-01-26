import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sign_in_screen.dart'; // Импорт экрана входа
import '../services/auth_service.dart'; //сохранения токена (проверка входа)
import '../services/database_service.dart'; //для лок БД

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  const LoadingOverlay({super.key, required this.child, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : const Color(0xFF7e61f3),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;
  
  // Controllers для полей
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    // Очищаем controllers и FocusNode
    _loginController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _loginFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Валидация полей
  bool _validateFields() {
    final login = _loginController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    // Валидация всего
    if (login.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showSnackBar('Все поля обязательны для заполнения');
      return false;
    }

    // Валидация login
    if (login.length < 3) {
      _showSnackBar('Логин должен содержать минимум 3 символа');
      return false;
    }

    // Валидация email (regex)
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar('Неверный формат email (пример: name@example.com)');
      return false;
    }

    // Валидация телефона (простой шаблон: +7xxxxxxxxxx или 8xxxxxxxxxx, адаптируйте)
    final phoneRegex = RegExp(r'^(?:\+7|8)?\d{10}$');
    if (!phoneRegex.hasMatch(phone)) {
      _showSnackBar('Неверный формат телефона (пример: +71234567890 или 81234567890)');
      return false;
    }

    // Валидация пароля (мин 6 символов, хотя бы одна буква и одна цифра)
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$');
    if (!passwordRegex.hasMatch(password)) {
      _showSnackBar('Пароль должен содержать минимум 6 символов, включая буквы и цифры');
      return false;
    }

    return true;
  }

  // Внутри _SignUpScreenState
    Future<Map<String, dynamic>?> _fetchUserProfile(String userId) async {
      final supabase = Supabase.instance.client;
      for (int i = 0; i < 10; i++) {
        try {
          final response = await supabase
            .from('users')
            .select()
            .eq('id', userId)
            .single()
            .timeout(const Duration(seconds: 2)) as PostgrestResponse;

          if (response.data is Map<String, dynamic>) {
            return response.data;
          }
        } on PostgrestException catch (e) {
          print('PostgREST error: $e');
        } on TimeoutException {
          print('Попытка ${i + 1}: таймаут при загрузке профиля');
        } catch (e) {
          print('Ошибка загрузки профиля: $e');
        }
        // Подождать перед повторной попыткой
        await Future.delayed(const Duration(milliseconds: 300));
      }
      return null;
    }

  // Метод регистрации
  Future<void> _handleSignUp() async {
    if (_isLoading) return;
    if (!_validateFields()) return;

    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final login = _loginController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Регистрация в Supabase Auth
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {  // Вот это важно!
          'name': login,
          'telephone': phone,
        },
      );

      // Если session null (нормально, если требуется confirm email), продолжаем
      final user = authResponse.user;
      if (user == null) {
        _showSnackBar('Ошибка регистрации: пользователь не создан');
        return;
      }

      // Сохраняем токен (если session есть)
      if (authResponse.session != null) {
        await AuthService.instance.saveToken(authResponse.session!.accessToken);
      }

      // Ждём и получаем профиль из public.users
      final userData = await _fetchUserProfile(user.id);
      if (userData != null) {
        // Синхронизируем в локальную БД
        await DatabaseService.instance.syncUserFromSupabase(userData);
        // Сохраняем current_user_id (ID из public.users)
        await AuthService.instance.saveCurrentUserId(userData['id'] as String);
      } else {
        print('⚠️ Профиль не загрузился — синхронизация отложена до входа');
      }

      _showSnackBar('Регистрация успешна! Теперь войдите в аккаунт');

      // Переход
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );

    } on PostgrestException catch (e) {
      // Обработка ошибок Supabase (например, дубликат email/name/telephone)
      _showSnackBar('Ошибка: ${e.message}');  // Supabase вернет "duplicate key" для UNIQUE
    } catch (e) {
      _showSnackBar('Неизвестная ошибка: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Показ SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // UI экрана регистрации (не трогать!! А то пристрелю)
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Цвета в зависимости от темы
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.grey;
    final fieldFillColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final dividerColor = isDarkMode ? Colors.grey[700] : const Color.fromARGB(84, 158, 158, 158);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
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
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Регистрация',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
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
                      controller: _loginController,
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
                      controller: _emailController,
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
                      controller: _phoneController,
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
                      controller: _passwordController,
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
                    onPressed: _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ).merge(Theme.of(context).elevatedButtonTheme.style),
                    child: Text('Регистрация'),
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
      ),
    );
  }
}