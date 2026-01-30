import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  final FocusNode _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите email')),
      );
      return;
    }
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный формат email')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'taskplanner://reset-password/reset',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ссылка для сброса отправлена на email')),
      );
      Navigator.pop(context);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неизвестная ошибка')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.grey;
    final fieldFillColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final dividerColor = isDarkMode ? Colors.grey[700] : const Color.fromARGB(84, 158, 158, 158);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
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
                  // Заголовок
                  Text(
                    'Восстановление пароля',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Введите ваш email, чтобы получить ссылку для восстановления пароля.',
                    style: GoogleFonts.poppins(
                      color: hintColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Поле ввода email
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
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
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
                          borderSide: const BorderSide(color: Color(0xFF7e61f3), width: 1.5),
                        ),
                      ),
                      onFieldSubmitted: (_) => _sendResetLink(),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Кнопка "Отправить ссылку"
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetLink,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ).merge(Theme.of(context).elevatedButtonTheme.style),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Отправить ссылку'),
                  ),

                  const SizedBox(height: 20),

                  // ИЛИ с полосками
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

                  // Ссылка "Назад к входу"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Уже помните пароль? ",
                        style: GoogleFonts.poppins(color: hintColor),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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