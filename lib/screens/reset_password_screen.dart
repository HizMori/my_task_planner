import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? accessToken; // можно передать, если получили из deep link

  const ResetPasswordScreen({super.key, this.accessToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (newPassword.isEmpty || confirm.isEmpty) {
      _showSnackBar('Заполните оба поля');
      return;
    }

    if (newPassword != confirm) {
      _showSnackBar('Пароли не совпадают');
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('Пароль должен быть не короче 6 символов');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Если мы пришли по deep link — сессия уже должна быть активна
      // Но на всякий случай можно обновить пользователя
      final response = await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        _showSnackBar('Пароль успешно изменён! Теперь можете войти');
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on AuthException catch (e) {
      _showSnackBar('Ошибка: ${e.message}');
    } catch (e) {
      _showSnackBar('Неизвестная ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый пароль')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Придумайте новый пароль',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Новый пароль',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Повторите пароль',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Сохранить новый пароль'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}