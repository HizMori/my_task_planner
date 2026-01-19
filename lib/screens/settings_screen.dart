import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'edit_profile_screen.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

      // 🔁 Сохраним в локальную БД (опционально — для оффлайна)
      await DatabaseService.instance.updateUser(user);

      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      print('Ошибка загрузки пользователя из Supabase: $e');
      
      // 🔽 Резерв: загрузка из локальной БД
      final user = await DatabaseService.instance.readUserById(userId);
      print('🔽 Используем пользователя из локальной БД: ${user?.avatarUrl}');

      if (mounted) {
        setState(() {
          _user = user;
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
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

    // 🔥 Реализуем удаление аккаунта
    await _deleteAccount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            icon: const Icon(Icons.edit, size: 24),
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
            icon: Icon(Icons.more_vert),
            color: Theme.of(context).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            const Spacer(),
          ],
        ),
      ),
    );
  }
}