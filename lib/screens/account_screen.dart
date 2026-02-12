import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart'; // Для logout
import '../services/database_service.dart'; // Для fetch пользователя
import '../models/user.dart'; // Модель
import 'welcome_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../widgets/user_avatar.dart';
import 'package:google_fonts/google_fonts.dart';

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
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await AuthService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 🔁 Сначала синхронизируем пользователя из Supabase
      final supabaseUser = await Supabase.instance.client.auth.getUser();
      final remoteUserData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', supabaseUser.user!.id)
          .single();

      // 📥 Синхронизируем в локальную БД
      await DatabaseService.instance.syncUserFromSupabase(remoteUserData);

      // 📖 Теперь читаем из локальной БД — уже обновлённые данные
      final user = await DatabaseService.instance.readUserById(userId);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке пользователя: $e');

      // На случай ошибки — всё равно попробуем показать кэшированного пользователя
      final userId = await AuthService.instance.getCurrentUserId();
      if (userId != null) {
        final cachedUser = await DatabaseService.instance.readUserById(userId);
        setState(() {
          _user = cachedUser;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Метод для выхода из аккаунта
  Future<void> _logout() async {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.grey;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Выход',
              style: theme.textTheme.headlineSmall?.copyWith(color: textColor),
            ),
          ],
        ),
        content: Text(
          'Вы уверены, что хотите выйти?',
          style: theme.textTheme.bodyMedium?.copyWith(color: hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Отмена',
              style: GoogleFonts.poppins(color: theme.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              'Выйти',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (result != true) return;

    // Выходим из Supabase
    final supabase = Supabase.instance.client;
    await supabase.auth.signOut();

    // Очищаем все данные
    await AuthService.instance.deleteToken();
    await AuthService.instance.deleteCurrentUserId();
    await AuthService.instance.setLoggedIn(false);

    // Перенаправляем на начальный экран
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Профиль')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 24), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Профиль')
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_user != null) ...[
              const SizedBox(height: 20),
              // Аватар и данные
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UserAvatar(user: _user!, radius: 40),
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
              const Spacer(flex: 1),
            ] else ...[
              const SizedBox(height: 40),
              const Text(
                'Не удалось загрузить данные',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              const Spacer(flex: 2),
            ],

            // Кнопка "Выйти" всегда видна
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
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