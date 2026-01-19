import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await Supabase.instance.client.auth.getUser();
      final userId = response.user?.id;
      if (userId == null) return;

      final userResponse = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      _user = User.fromMap(userResponse);

      setState(() {
        _nameController.text = _user!.name;
        _emailController.text = _user!.email ?? '';
        _phoneController.text = _user!.telephone ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;
    final now = DateTime.now();
    final newEmail = _emailController.text.trim();

    try {
      // Обновляем в Supabase кастомную таблицу public.users
      await supabase.from('users').update({
        'name': _nameController.text.trim(),
        'email': newEmail.isEmpty ? null : newEmail,
        'telephone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'updated_at': now.toIso8601String(),
      }).eq('id', _user!.id);

      // Обновляем локально
      final updatedUser = _user!.copyWith(
        name: _nameController.text.trim(),
        email: newEmail.isEmpty ? null : newEmail,
        telephone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        updatedAt: now,
      );

      await DatabaseService.instance.updateUser(updatedUser);

      // Проверяем, изменился ли email по сравнению с auth.users
    final authEmail = supabase.auth.currentUser?.email;
      if (newEmail.isNotEmpty && newEmail != authEmail) {
        try {
          await supabase.auth.updateUser(UserAttributes(email: newEmail));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Проверьте почту для подтверждения нового email')),
          );
        } on AuthException catch (e) {
          // Показываем ошибку, но не прерываем — public.users уже обновлён
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось обновить email для входа: ${e.message}')),
          );
        }
      }

      // Обновляем состояние в AccountScreen при возврате
      if (mounted) {
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Редактирование'),
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
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Редактирование'),
        // Убрали кнопку "Сохранить" из AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 16),

              // Имя
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Имя',
                  hintText: 'Введите ваше имя',
                  labelStyle: theme.textTheme.bodyMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Введите имя';
                  if (value.trim().length < 2) return 'Имя слишком короткое';
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@email.com',
                  labelStyle: theme.textTheme.bodyMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !value.contains('@')) {
                    return 'Введите корректный email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Телефон
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Телефон',
                  hintText: '+7 (999) 123-45-67',
                  labelStyle: theme.textTheme.bodyMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 32),

              // Кнопка "Сохранить" — как в CreateTaskScreen
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7e61f3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                ),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
