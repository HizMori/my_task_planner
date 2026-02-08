import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/group_member.dart';

class CreateGroupScreen extends StatefulWidget {
  final Group? group;

  const CreateGroupScreen({super.key, this.group});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final DatabaseService _db = DatabaseService.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
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
        final isEditing = widget.group != null;
        late Group group;

        if (isEditing) {
          group = widget.group!.copyWith(
            name: _nameController.text.trim(),
            updatedAt: now,
          );

          // Обновляем в локальной БД
          await _db.updateGroup(group);

          // Синхронизируем с Supabase
          await _db.syncGroupsToSupabase();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Группа обновлена!')),
            );
            Navigator.pop(context, true); // Возвращаем true для обновления
          }
        } else {
          final groupId = _db.uuid.v4();
          group = Group(
            id: groupId,
            name: _nameController.text.trim(),
            creatorId: userId,
            createdAt: now,
            updatedAt: now,
            lastSyncAt: now,
          );

          // Сохраняем в локальную БД
          await _db.createGroup(group);

          // Добавляем создателя в локальные участники
          await _db.createGroupMember(GroupMember(
            groupId: groupId,
            userId: userId,
            joinedAt: now,
            updatedAt: now,
            lastSyncAt: now,
          ));

          // Синхронизируем с Supabase
          await _db.syncGroupsToSupabase();
          await _db.syncGroupMembersToSupabase();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Группа создана!')),
            );
            Navigator.pop(context, true); // Возвращаем true для обновления
          }
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
    final isEditing = widget.group != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 24), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isEditing ? 'Изменить группу' : 'Создать группу'),
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
                onFieldSubmitted: (_) => _saveGroup(),
              ),

              const SizedBox(height: 32),

              // Кнопка "Создать" или "Сохранить"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveGroup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? 'Сохранить' : 'Создать группу',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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