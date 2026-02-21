import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/group.dart';
import '../services/database_service.dart';
import 'create_task_screen.dart';
import '../main.dart';
import '../models/user.dart';
import '../models/task_assignee.dart';

class GroupTasksScreen extends StatefulWidget {
  final Group group;

  const GroupTasksScreen({super.key, required this.group});

  @override
  State<GroupTasksScreen> createState() => _GroupTasksScreenState();
}

class _GroupTasksScreenState extends State<GroupTasksScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<Task> _tasks = [];
  bool _isLoading = true;
  Map<String, User?> _groupUsersCache = {};
  Map<String, List<User>> _taskAssignees = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _db.syncTasksFromSupabase();
      await _db.syncTasksToSupabase();
      await _loadGroupMembersAndCache(); 
      await _db.syncGroupsFromSupabase();
      await _db.syncGroupMembersFromSupabase(); 
      await _db.syncTaskAssigneesFromSupabase();
      _loadTasks();
    });
  }

  Future<void> _loadGroupMembersAndCache() async {
    try {
      // Получаем ID участников группы из Supabase (не из локальной БД!)
      final membersData = await _db.supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', widget.group.id);

      final List<String> userIds = (membersData as List)
          .map((m) => m['user_id'] as String)
          .toList();

      if (userIds.isEmpty) {
        setState(() {
          _groupUsersCache = {};
        });
        return;
      }

      // Загружаем профили пользователей из Supabase
      final usersData = await _db.supabase
          .from('users')
          .select('id, name, created_at, updated_at')
          .filter('id', 'in', userIds);

      final List<User> users = (usersData as List)
          .map((u) => User.fromMap(u))
          .toList();

      // Сохраняем в локальную БД для будущих запросов
      for (final user in users) {
        await _db.createUser(user);
      }

      // Строим кэш по ID
      final Map<String, User> cache = {
        for (final user in users) user.id: user,
      };

      if (mounted) {
        setState(() {
          _groupUsersCache = cache;
        });
      }
    } catch (e) {
      print('Ошибка загрузки участников из Supabase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить участников: $e')),
      );

      // Даже если ошибка — попробуем подгрузить из локальной БД
      _loadGroupMembersAndCacheFromLocal();
    }
  }

  Future<void> _loadGroupMembersAndCacheFromLocal() async {
    try {
      final groupMembers = await _db.readGroupMembers(widget.group.id);
      final userIds = groupMembers.map((m) => m.userId).toList();

      final Map<String, User> cache = {};

      for (final userId in userIds) {
        final user = await _db.readUserById(userId);
        if (user != null) {
          cache[user.id] = user;
        }
      }

      if (mounted) {
        setState(() {
          _groupUsersCache = cache;
        });
      }
    } catch (e) {
      print('Ошибка загрузки участников из локальной БД: $e');
    }
  }

  Future<void> _loadTasks() async {
    try {
      final allTasks = await _db.readAllTasks();
      final groupTasks = allTasks
          .where((task) => task.groupId == widget.group.id)
          .toList();

      if (mounted) {
        setState(() {
          _tasks = groupTasks;
        });
      }

      // Загружаем назначенных
      for (final task in groupTasks) {
        final assignees = await _db.readTaskAssignees(task.id!);
        final userIds = assignees.map((a) => a.userId).toList();
        final users = await _db.readAllUsers();
        final assignedUsers = users.where((u) => userIds.contains(u.id)).toList();

        if (mounted) {
          setState(() {
            _taskAssignees[task.id!] = assignedUsers;
          });
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createTask() async {
     final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskScreen(initialGroupId: widget.group.id),
      ),
    );

    if (result == true) {
      // Обновляем список после создания
      _loadTasks();
    }
  }

  Future<void> _deleteTask(Task task) async {
    await _db.deleteTask(task.id!);
    _loadTasks(); // Обновляем список
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Задача "${task.title}" удалена')),
    );
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    // Обновляем состояние в памяти сразу
    final now = DateTime.now();
    final updatedTask = task.copyWith(
      is_completed: !task.is_completed,
      updatedAt: now, // Обязательно обновляем
    );

    // Находим индекс задачи
    final index = _tasks.indexOf(task);
    if (index == -1) return;

    // Обновляем в списке
    if (mounted) {
      setState(() {
        _tasks[index] = updatedTask;
      });
    }

    // Асинхронно обновляем в базе
    await _db.updateTask(updatedTask);
    await _db.syncTasksToSupabase(); // Отправляем изменения в Supabase
    // Не обязательно вызывать _loadTasks() — мы уже обновили UI
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Задачи'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Счётчик задач
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Задач: ${_tasks.length}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Выполнено: ${_tasks.where((t) => t.is_completed).length}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Список задач
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _tasks.isEmpty
                        ? const Center(
                            child: Text(
                              'Нет задач. Нажмите "Создать", чтобы добавить первую.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _tasks.length,
                            itemBuilder: (context, index) {
                              final isDarkMode = theme.brightness == Brightness.dark;
                              final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
                              final task = _tasks[index];
                              return Dismissible(
                                key: Key('task-${task.id}'),
                                direction: DismissDirection.startToEnd,
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 16),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (direction) => _deleteTask(task),
                                child: Card(
                                  color: cardColor,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: isDarkMode ? 2 : 1,
                                  child: ListTile(
                                    title: Text(
                                      task.title,
                                      style: task.is_completed
                                          ? theme.textTheme.bodyMedium?.copyWith(
                                              decoration: TextDecoration.lineThrough,
                                              color: Colors.grey,
                                            )
                                          : null,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            _buildLabel(_getPriorityText(task.priority), _getPriorityColor(task.priority)),
                                            _buildLabel(_getCategoryText(task.category), const Color(0xFF7e61f3)),
                                            _buildLabel(_getUrgencyText(task.urgency), _getUrgencyColor(task.urgency))
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        _buildAssignedTo(task),
                                      ],
                                    ),
                                    trailing: Checkbox(
                                      value: task.is_completed,
                                      activeColor: const Color(0xFF7e61f3),
                                      onChanged: (value) => _toggleTaskCompletion(task),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CreateTaskScreen(task: task),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadTasks();
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),

          // Кнопка "Создать задачу" — внизу
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _createTask,
              icon: const Icon(Icons.add, size: 20, color: Colors.white),
              label: const Text(
                'Создать задачу',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7e61f3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 0),
                elevation: 6,
                shadowColor: const Color(0xFF7e61f3).withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedTo(Task task) {
    final assignedUsers = _taskAssignees[task.id] ?? [];
    if (assignedUsers.isEmpty) return SizedBox();

    return Wrap(
      spacing: 8,
      children: [
        for (var user in assignedUsers)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 12, color: const Color(0xFF7e61f3)),
              const SizedBox(width: 4),
              Text(
                user.name,
                style: TextStyle(
                  fontSize: 10,
                  color: const Color(0xFF7e61f3),
                ),
              ),
            ],
          ),
        if (assignedUsers.length > 3)
          Text(
            '+${assignedUsers.length - 3}',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF7e61f3),
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getPriorityText(String? priority) {
    return switch (priority) {
      'low' => 'Не важно',
      'high' => 'Важно',
      _ => 'Не указан',
    };
  }

  Color _getPriorityColor(String? priority) {
    return switch (priority) {
      'low' => Colors.green,
      'high' => Colors.red,
      _ => Colors.grey,
    };
  }

  String _getCategoryText(String? category) {
    return switch (category) {
      'работа' => 'Работа',
      'личное' => 'Личное',
      'учёба' => 'Учёба',
      'другое' => 'Другое',
      _ => 'Без категории',
    };
  }

  String _getUrgencyText(String? urgency) {
    return switch (urgency) {
      'urgent' => 'Срочно',
      'not_urgent' => 'Не срочно',
      _ => 'Не указано',
    };
  }

  Color _getUrgencyColor(String? urgency) {
    return switch (urgency) {
      'urgent' => Colors.orange,
      'not_urgent' => Colors.blueGrey,
      _ => Colors.grey,
    };
  }
}