import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'search_users_screen.dart';

class GroupMembersScreen extends StatefulWidget {
  const GroupMembersScreen({super.key});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<User> _members = [];
  String? _currentUserId;
  String _groupName = 'Моя группа'; // Заглушка — в дальнейшем передаём из GroupDetails
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Имитация загрузки участников
      // В будущем: _members = await _db.getMembersOfGroup(groupId);
      // Пока — заглушка
      final users = await _db.readAllUsers();
      _members = users.take(5).toList(); // Берём первых 5 пользователей

      // Получаем ID текущего пользователя
      // В будущем: через Supabase.auth.getUser()
      _currentUserId = 'current_user'; // Пока заглушка

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }

  Future<void> _addMember() async {
    final selectedUser = await Navigator.push<User?>(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchUsersScreen(),
      ),
    );

    if (selectedUser != null && !_members.any((m) => m.id == selectedUser.id)) {
      setState(() {
        _members.add(selectedUser);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedUser.name} добавлен(а) в группу')),
      );
    }
  }

  void _removeMember(User user) {
    if (user.id == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя удалить себя из группы')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить участника'),
        content: Text('Удалить ${user.name} из группы?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _members.remove(user);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user.name} удалён(а) из группы')),
              );
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Участники',
                  style: theme.textTheme.headlineSmall,
                ),
                const Spacer(),
                Text(
                  '(${_members.length})',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),

          // Кнопка "Добавить участника"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _addMember,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Добавить участника'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Список участников
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _members.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_alt_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Нет участников',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _members.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = _members[index];
                          final isCreator = index == 0; // Пусть первый — создатель
                          final isMe = user.id == _currentUserId;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF7e61f3).withOpacity(0.15),
                              child: Text(
                                user.name.characters.take(1).toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF7e61f3),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user.name,
                              style: isCreator
                                  ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)
                                  : null,
                            ),
                            subtitle: Row(
                              children: [
                                if (isCreator)
                                  _buildLabel('Создатель', const Color(0xFF7e61f3))
                                else if (isMe)
                                  _buildLabel('Вы', Colors.blue),
                              ],
                            ),
                            trailing: isMe || isCreator
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                                    onPressed: () => _removeMember(user),
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}