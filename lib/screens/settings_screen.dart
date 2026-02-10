import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_task_planner/main.dart';
import 'package:my_task_planner/models/app_settings.dart';
import 'package:my_task_planner/themes/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'edit_profile_screen.dart';
import 'welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/lock_screen.dart';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _user;
  bool _isLoading = true;
  AppSettings? _settings;
  bool _isLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLockSetting();
  }

  Future<void> _loadLockSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(LockScreen.PREFS_KEY_ENABLED) ?? false;
    if (mounted) {
      setState(() {
        _isLockEnabled = enabled;
      });
    }
  }

  Future<void> _setPinCode() async {
    final pinController = TextEditingController();
    final hintController = TextEditingController();

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.grey;
    final fieldFillColor = isDarkMode ? Colors.grey[800] : Colors.white;

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.lock, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Установите PIN',
                style: theme.textTheme.headlineSmall?.copyWith(color: textColor),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Поле PIN — в стиле SignInScreen
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.pin, color: theme.primaryColor),
                    labelText: '4-значный PIN',
                    labelStyle: GoogleFonts.poppins(color: hintColor),
                    floatingLabelStyle: GoogleFonts.poppins(color: theme.primaryColor),
                    filled: true,
                    fillColor: fieldFillColor,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: textColor,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Поле Подсказка — аналогично
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: TextField(
                  controller: hintController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.help_outline, color: theme.primaryColor),
                    labelText: 'Подсказка',
                    labelStyle: GoogleFonts.poppins(color: hintColor),
                    floatingLabelStyle: GoogleFonts.poppins(color: theme.primaryColor),
                    filled: true,
                    fillColor: fieldFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
                    ),
                  ),
                  style: GoogleFonts.poppins(color: textColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Подсказка не хранится в открытом виде',
                style: theme.textTheme.bodySmall?.copyWith(color: hintColor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Отмена',
                style: GoogleFonts.poppins(color: hintColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final pin = pinController.text;
                if (pin.length == 4) {
                  Navigator.pop(context, {
                    'pin': pin,
                    'hint': hintController.text.trim(),
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN должен быть 4-значным')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    // Генерируем резервный код: 6 символов (A-Z, 0-9)
    final recoveryCode = _generateRecoveryCode();
    final prefs = await SharedPreferences.getInstance();

    // Сохраняем данные
    await prefs.setString(LockScreen.PREFS_KEY_PIN_HASH, _hash(result['pin']!));
    await prefs.setString(LockScreen.PREFS_KEY_HINT, result['hint']!);
    await prefs.setString(LockScreen.PREFS_KEY_RECOVERY_CODE_HASH, _hash(recoveryCode));
    await prefs.setBool(LockScreen.PREFS_KEY_ENABLED, true);

    // Показываем резервный код один раз
    await _showRecoveryCodeDialog(recoveryCode);

    setState(() {
      _isLockEnabled = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Блокировка включена')));
  }

  String _generateRecoveryCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (i) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _showRecoveryCodeDialog(String code) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text("Резервный код"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Сохраните этот код. Он понадобится, если вы забудете PIN:",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            SelectableText(
              code,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                backgroundColor: Colors.grey[100],
              ),
            ),
            SizedBox(height: 16),
            Text(
              "⚠️ Если потеряете этот код и забудете PIN — доступ к данным будет потерян.",
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: Text("Я сохранил"),
          ),
        ],
      ),
    );
  }

  String _hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _disableLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(LockScreen.PREFS_KEY_PIN_HASH);
    await prefs.setBool(LockScreen.PREFS_KEY_ENABLED, false);
    if (mounted) {
      setState(() {
        _isLockEnabled = false;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Блокировка отключена')));
  }

  Future<void> _loadUserData() async {
    final userId = await AuthService.instance.getCurrentUserId();
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final supabase = Supabase.instance.client;

    try {
      final userResponse = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final user = User.fromMap(userResponse);
      print('✅ Загружен аватар из Supabase: ${user.avatarUrl}');

      // Сохраним в локальную БД (опционально — для оффлайна)
      await DatabaseService.instance.updateUser(user);

      AppSettings? settings = await DatabaseService.instance.readAppSettings(userId);
      if (settings == null) {
        settings = AppSettings(
          userId: userId,
          theme: 'system',
          notificationsEnabled: true,
          reminderTime: 15,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await DatabaseService.instance.createAppSettings(settings);
      }

      if (mounted) {
        setState(() {
          _user = user;
          _settings = settings;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      print('Ошибка загрузки пользователя из Supabase: $e');
      
      // 🔽 Резерв: загрузка из локальной БД
      final user = await DatabaseService.instance.readUserById(userId);
      print('🔽 Используем пользователя из локальной БД: ${user?.avatarUrl}');

      AppSettings? settings = await DatabaseService.instance.readAppSettings(userId);
      if (settings == null) {
        settings = AppSettings(
          userId: userId,
          theme: 'system',
          notificationsEnabled: true,
          reminderTime: 15,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await DatabaseService.instance.createAppSettings(settings);
      }

      if (mounted) {
        setState(() {
          _user = user;
          _settings = settings;
          _isLoading = false;
        });
      }
    }
  }

  // Выбор и обрезка изображения
  Future<void> _pickAndCropImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Обрезка', toolbarColor: Colors.deepPurple),
        IOSUiSettings(title: 'Обрезка'),
      ],
    );

    if (croppedFile == null) return;

    await _uploadImage(File(croppedFile.path));
  }

  // Загрузка изображения в Supabase
  Future<void> _uploadImage(File file) async {
    final supabase = Supabase.instance.client;
    final userId = _user!.id;
    final fileName = '$userId.jpg';

    try {
      // 1. Загрузка в Storage
      await supabase.storage.from('avatars').upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2. Получение публичного URL
      final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      print('Uploaded avatar URL: $imageUrl');

      // 3. Обновление в Supabase
      await supabase.from('users').update({'avatar_url': imageUrl}).eq('id', userId);

      // 4. Обновление в локальной БД
      final updatedUser = _user!.copyWith(avatarUrl: imageUrl);
      await DatabaseService.instance.updateUser(updatedUser);

      // 5. Обновить UI
      if (mounted) {
        setState(() {
          _user = updatedUser;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аватар успешно обновлён!')),
      );
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    if (_user == null) return;

    final supabase = Supabase.instance.client;
    final userId = _user!.id;

    try {
      // 1. Помечаем как удалённого (soft delete)
      await supabase
          .from('users')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', userId);

      // 2. Очистка локальных данных
      await DatabaseService.instance.deleteDB();
      await AuthService.instance.deleteToken();
      await AuthService.instance.deleteCurrentUserId();
      await AuthService.instance.setLoggedIn(false);

      // 3. Переход
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
      );
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        backgroundColor: theme.scaffoldBackgroundColor,
        content: const Text(
          'Это действие нельзя отменить. Все ваши данные будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Реализуем удаление аккаунта
    await _deleteAccount();
  }

  String _getThemeLabel(String? theme) {
    switch (theme) {
      case 'light': return 'Светлая';
      case 'dark': return 'Тёмная';
      default: return 'Системная';
    }
  }

  Future<void> _showThemeBottomSheet() async {
    final currentTheme = (_settings?.theme ?? 'system');
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Системная'),
            trailing: currentTheme == 'system' ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, 'system'),
          ),
          ListTile(
            title: const Text('Светлая'),
            trailing: currentTheme == 'light' ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, 'light'),
          ),
          ListTile(
            title: const Text('Тёмная'),
            trailing: currentTheme == 'dark' ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, 'dark'),
          ),
        ],
      ),
    );

    if (result == null || result == currentTheme) return;

    // Обновляем в БД
    final userId = _user!.id;
    final newSettings = AppSettings(
      userId: userId,
      theme: result,
      notificationsEnabled: _settings?.notificationsEnabled ?? true,
      reminderTime: _settings?.reminderTime ?? 15,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await DatabaseService.instance.updateAppSettings(newSettings);

    // Перезапускаем UI с новой темой
    if (mounted) {
      setState(() {
        _settings = newSettings;
      });
    }

    // Просто обновляем через Provider
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.setTheme(result); // 'light', 'dark', 'system'
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final inactiveColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 24), 
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 24), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Кнопка "Редактировать"
          IconButton(
            icon: Icon(
              Icons.edit, 
              size: 24,
              color: inactiveColor,
              ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
              if (result is User) {
                setState(() {
                  _user = result; // Обновляем после возврата
                });
              }
            },
          ),
          // Кнопка "Меню"
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete_account') {
                await _showDeleteAccountDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete_account',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text(
                      'Удалить аккаунт',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
            // offset сдвигает меню вниз и влево
            offset: const Offset(-10, 40), // x: -10 (чуть левее), y: 40 (вниз от AppBar)
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            icon: Icon(
              Icons.more_vert,
              color: inactiveColor
              ),
            color: theme.scaffoldBackgroundColor,
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Основной контейнер для центрирования
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF7e61f3).withOpacity(0.15),
                        child: _user?.avatarUrl != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: _user!.avatarUrl!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  placeholder: (context, url) => Container(
                                    color: const Color(0xFF7e61f3).withOpacity(0.15),
                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: const Color(0xFF7e61f3).withOpacity(0.15),
                                    child: Text(
                                      _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: Color(0xFF7e61f3),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                _user?.name.isNotEmpty == true ? _user!.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Color(0xFF7e61f3),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                      ),
                      // Кнопка камеры — поверх аватара
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            onPressed: _pickAndCropImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user?.name ?? 'Пользователь',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: Icon(
                Icons.palette,
                color: inactiveColor,
                ),
              title: const Text('Тема'),
              subtitle: Text(_getThemeLabel(_settings?.theme)),
              onTap: _showThemeBottomSheet,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.lock,
                color: inactiveColor,
                ),
              title: const Text('Блокировка приложения'),
              subtitle: Text(_isLockEnabled ? 'Включена' : 'Выключена'),
              onTap: () {
                if (_isLockEnabled) {
                  _disableLock();
                } else {
                  _setPinCode();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}