import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'search_users_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class GroupMembersScreen extends StatefulWidget {
  final Group group;

  const GroupMembersScreen({super.key, required this.group});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<User> _members = [];
  String? _currentUserId;
  bool _isLoading = true;

  // Добавь ID группы — важно!
  late final String _groupId;

  @override
  void initState() {
    super.initState();
    // Получаем из GroupDetailsScreen через widget.group
    _groupId = widget.group.id;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Получаем ID текущего пользователя
      final response = await Supabase.instance.client.auth.getUser();
      _currentUserId = response.user?.id;

      if (_currentUserId == null) {
        throw Exception("Пользователь не авторизован");
      }

      final uid = _currentUserId;
      if (uid == null) return;

      // Проверяем, состоит ли пользователь в этой группе
      final membershipCheck = await Supabase.instance.client
          .from('group_members')
          .select('group_id')
          .eq('group_id', _groupId)
          .eq('user_id', uid)
          .limit(1);
      
      if ((membershipCheck as List).isEmpty) {
        throw Exception("Вы не состоите в этой группе");
      }

      // Загружаем участников из Supabase
      final membersData = await Supabase.instance.client
          .from('group_members')
          .select('user_id')
          .eq('group_id', _groupId);

      final userIds = (membersData as List).map((m) => m['user_id'] as String).toList();

      // Загружаем профили пользователей
      final usersData = await Supabase.instance.client
          .from('users')
          .select('id, name, created_at, updated_at')
          .filter('id', 'in', userIds);

      print('Users data: $usersData');

      _members = (usersData as List).map((u) => User.fromMap(u)).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки участников: $e')),
      );
    }
  }

  Future<void> _addMember() async {
    final selectedUser = await Navigator.push<User?>(context,
        MaterialPageRoute(builder: (context) => const SearchUsersScreen()));

    if (selectedUser == null || _members.any((m) => m.id == selectedUser.id)) {
      return;
    }

    try {
      final now = DateTime.now().toIso8601String();

      // Добавляем в Supabase
      await Supabase.instance.client.from('group_members').insert({
        'group_id': _groupId,
        'user_id': selectedUser.id,
        'joined_at': now,
        'updated_at': now,
        'last_sync_at': now,
      });

      // Добавляем в локальный список
      setState(() {
        _members.add(selectedUser);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${selectedUser.name} добавлен(а) в группу')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Не удалось добавить: $e')));
    }
  }

  void _removeMember(User user) {
    if (user.id == _currentUserId) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Нельзя удалить себя из группы')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить участника'),
        content: Text('Удалить ${user.name} из группы?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client
                    .from('group_members')
                    .delete()
                    .match({'group_id': _groupId, 'user_id': user.id});

                setState(() {
                  _members.remove(user);
                });

                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('${user.name} удалён(а) из группы')));
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
              }
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
                          final isCreator = user.id == widget.group.creatorId;
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
                                  _buildLabel('Создатель', const Color(0xFF7e61f3)),
                                if (isMe)
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