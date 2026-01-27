import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/app_settings.dart';

class ThemeProvider extends ChangeNotifier {
  late ThemeMode _themeMode;
  String _themeSetting = 'system'; // 'light', 'dark', 'system'

  ThemeMode get themeMode => _themeMode;
  String get themeSetting => _themeSetting;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final userId = await AuthService.instance.getCurrentUserId();
    if (userId == null) {
      _themeMode = ThemeMode.system;
      notifyListeners();
      return;
    }

    final settings = await DatabaseService.instance.readAppSettings(userId);
    _themeSetting = settings?.theme ?? 'system';

    _applyThemeMode(_themeSetting);
    notifyListeners();
  }

  void _applyThemeMode(String theme) {
    switch (theme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
  }

  Future<void> setTheme(String theme) async {
    final userId = await AuthService.instance.getCurrentUserId();
    if (userId == null) return;

    // Обновляем в БД
    final settings = await DatabaseService.instance.readAppSettings(userId);
    final newSettings = (settings ?? AppSettings(
      userId: userId,
      theme: 'system',
      notificationsEnabled: true,
      reminderTime: 15,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )).copyWith(theme: theme, updatedAt: DateTime.now());

    if (settings == null) {
      await DatabaseService.instance.createAppSettings(newSettings);
    } else {
      await DatabaseService.instance.updateAppSettings(newSettings);
    }

    // Обновляем состояние
    _themeSetting = theme;
    _applyThemeMode(theme);
    notifyListeners();
  }
}
