import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart'; // Для logout
import '../services/database_service.dart'; // Для fetch пользователя
import '../models/user.dart'; // Модель
import 'welcome_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Загрузка данных пользователя
  Future<void> _loadUser() async {
    final userId = await AuthService.instance.getCurrentUserId();
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final user = await DatabaseService.instance.readUserById(userId);
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  // Метод для выхода из аккаунта
  Future<void> _logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (result != true) return;
    await AuthService.instance.deleteToken();
    await AuthService.instance.deleteCurrentUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isFirstLaunch', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Аккаунт')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Аккаунт')),
        body: const Center(child: Text('Пользователь не найден')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Аккаунт')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Аватар и данные
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: _user!.avatarUrl != null
                      ? NetworkImage(_user!.avatarUrl!)  // Если avatar_url из Supabase
                      : const AssetImage('assets/images/17404f5729d1a652c70d.png') as ImageProvider,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_user!.name, style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text(_user!.email ?? 'Нет email', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(_user!.telephone ?? 'Нет телефона', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const Spacer(), // Пространство, чтобы кнопка "Выйти" была внизу
            // Кнопка "Выйти"
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // Красный цвет для кнопки "Выйти"
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: const Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }
}