import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '/screens/group_list_screen.dart';
import '../models/group_member.dart';


class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final DatabaseService _db = DatabaseService.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String? userId;

      try {
        final response = await Supabase.instance.client.auth.getUser();
        userId = response.user?.id;

        if (userId == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось определить пользователя')),
            );
          }
          return;
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка авторизации: $e')),
          );
        }
        return;
      }

      try {
        final now = DateTime.now();
        final groupId = _db.uuid.v4();
        final group = Group(
          id: groupId, // ID через uuid
          name: _nameController.text.trim(),
          creatorId: userId, // реальный ID
          createdAt: now,
          updatedAt: now,
          lastSyncAt: now,
        );
        // Сохраняем в локальную БД
        await _db.createGroup(group);

        // 2. Добавляем создателя в локальные участники
        await _db.createGroupMember(GroupMember(
          groupId: groupId,
          userId: userId,
          joinedAt: now,
          updatedAt: now,
          lastSyncAt: now,
        ));

        // Отправляем в Supabase
        await Supabase.instance.client.from('groups').insert({
          'id': groupId,
          'name': group.name,
          'creator_id': userId,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'last_sync_at': now.toIso8601String(),
        });

        // Добавляем создателя как участника группы в Supabase
        await Supabase.instance.client.from('group_members').insert({
          'group_id': groupId,
          'user_id': userId,
          'joined_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'last_sync_at': now.toIso8601String(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Группа создана!')),
          );
          Navigator.pop(context, group); // Возвращаем созданную группу
          
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 24), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Создать группу')
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Иконка
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF7e61f3).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  size: 40,
                  color: Color(0xFF7e61f3),
                ),
              ),

              const SizedBox(height: 24),

              // Поле ввода названия
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название группы',
                  hintText: 'Например: Друзья, Работа, Учёба',
                  labelStyle: theme.textTheme.bodyMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название группы';
                  }
                  if (value.trim().length < 2) {
                    return 'Название слишком короткое';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _createGroup(),
              ),

              const SizedBox(height: 32),

              // Кнопка "Создать"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Создать группу',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}