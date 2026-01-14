import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/database_service.dart';
import 'group_details_screen.dart';
import 'create_group_screen.dart';
import '../widgets/online_status_icon.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<Group> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _db.readAllGroups();
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки групп: $e')),
      );
    }
  }

  void _openGroupDetails(Group group) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(group: group),
      ),
    );

    // Если вернули true — значит, группу удалили
    if (result == true) {
      await _loadGroups(); // Обновляем список
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Группы'),
        actions: [
          const OnlineStatusIcon(),
          const SizedBox(width: 12),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Ваши группы',
                  style: theme.textTheme.headlineSmall,
                ),
                const Spacer(),
                Text(
                  '${_groups.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Список групп
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _groups.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Нет групп',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            Text(
                              'Нажмите +, чтобы создать первую',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7e61f3).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.groups_rounded,
                                  color: Color(0xFF7e61f3),
                                ),
                              ),
                              title: Text(
                                group.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: FutureBuilder<int>(
                                future: _getMemberCount(group.id),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Text(
                                      _formatMemberCount(snapshot.data!),
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  }
                                  return const Text('Загрузка...');
                                },
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () => _openGroupDetails(group),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Метод для подсчёта участников группы
  Future<int> _getMemberCount(String groupId) async {
    try {
      final response = await Supabase.instance.client
          .from('group_members')
          .select('user_id') // можно даже select('id') или select('*')
          .eq('group_id', groupId)
          .count(CountOption.exact);

      return response.count ?? 0;
    } catch (e) {
      debugPrint('Ошибка при подсчёте участников: $e');
      return 0;
    }
  }

  String _formatMemberCount(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return '$count участник';
    } else if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return '$count участника';
    } else {
      return '$count участников';
    }
  }
}