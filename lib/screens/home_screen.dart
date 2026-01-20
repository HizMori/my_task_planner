import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../widgets/online_status_icon.dart';
import 'create_task_screen.dart';
import '../models/task_assignee.dart';
import '../models/task_assignee.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  bool _isLoading = true;
  final DatabaseService _db = DatabaseService.instance;
  List<Task> _upcomingTasks = [];
  String? _userId; 
  Map<String, List<String>> _taskAssigneesCache = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Доброе утро';
    } else if (hour < 17) {
      return 'Добрый день';
    } else {
      return 'Добрый вечер';
    }
  }

  Future<void> _loadData() async {
    final userId = await AuthService.instance.getCurrentUserId();
    if (userId != null) {
      _userId = userId;
      final user = await _db.readUserById(userId);

      final userTasks = await _db.readUserTasks(userId);

      // Фильтруем невыполненные с дедлайном
      final upcoming = userTasks
          .where((task) => !task.is_completed && task.deadline != null)
          .toList()
        ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

      _upcomingTasks = upcoming.take(10).toList();

      // Загружаем назначенных для всех задач
      final allAssignees = await _db.readAllTaskAssignees();
      _taskAssigneesCache = {};
      for (final assignee in allAssignees) {
        _taskAssigneesCache
            .putIfAbsent(assignee.taskId, () => [])
            .add(assignee.userId);
      }

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    final difference = taskDate.difference(today).inDays;

    if (difference == 0) return 'Сегодня';
    if (difference == 1) return 'Завтра';
    if (difference == -1) return 'Вчера';

    final dayOfWeek = switch (date.weekday) {
      1 => 'Пн',
      2 => 'Вт',
      3 => 'Ср',
      4 => 'Чт',
      5 => 'Пт',
      6 => 'Сб',
      7 => 'Вс',
      _ => '',
    };

    final day = date.day;
    final month = switch (date.month) {
      1 => 'янв',
      2 => 'фев',
      3 => 'мар',
      4 => 'апр',
      5 => 'мая',
      6 => 'июн',
      7 => 'июл',
      8 => 'авг',
      9 => 'сен',
      10 => 'окт',
      11 => 'ноя',
      12 => 'дек',
      _ => '',
    };

    return '$dayOfWeek, $day $month';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Главное')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Разделяем задачи на просроченные и предстоящие
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<Task> overdueTasks = _upcomingTasks
        .where((task) => task.deadline!.isBefore(now))
        .toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

    final List<Task> upcomingTasks = _upcomingTasks
        .where((task) => !task.deadline!.isBefore(now))
        .toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Главное'),
        actions: const [
          OnlineStatusIcon(),
          SizedBox(width: 12),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Приветствие
            Text(
              '${_getGreeting()}, ${_user?.name ?? 'Пользователь'}!',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Вот что предстоит',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Просроченные задачи
                  if (overdueTasks.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Просроченные',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._buildTaskList(overdueTasks, theme, _userId!),
                      ],
                    ),

                  // Разделитель между группами (если обе группы есть)
                  if (overdueTasks.isNotEmpty && upcomingTasks.isNotEmpty)
                    const SizedBox(height: 16),

                  // Предстоящие задачи
                  if (upcomingTasks.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Предстоящие',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7e61f3),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._buildTaskList(upcomingTasks, theme, _userId!),
                      ],
                    ),

                  // Если нет задач вообще
                  if (overdueTasks.isEmpty && upcomingTasks.isEmpty)
                    const Center(
                      child: Text(
                        'Нет задач',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Вспомогательная функция для построения списка задач
  List<Widget> _buildTaskList(List<Task> tasks, ThemeData theme, String userId) {
    return tasks.asMap().entries.map((entry) {
      final index = entry.key;
      final task = entry.value;
      final deadline = task.deadline!;
      bool showDateHeader = true;

      if (index > 0) {
        final prevDeadline = tasks[index - 1].deadline!;
        showDateHeader = prevDeadline.day != deadline.day ||
            prevDeadline.month != deadline.month ||
            prevDeadline.year != deadline.year;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDateHeader)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _formatDateHeader(deadline),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _getPriorityInitial(task.priority),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                task.title,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatTime(deadline),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      _buildLabel(
                        _getCategoryText(task.category),
                        const Color(0xFF7e61f3),
                      ),
                    ],
                  ),
                  if (task.id != null && _taskAssigneesCache[task.id]?.contains(userId) == true)
                    Row(
                      children: [
                        Icon(Icons.person, size: 12, color: const Color(0xFF7e61f3)),
                        const SizedBox(width: 4),
                        Text('Назначено вам', style: TextStyle(fontSize: 10, color: const Color(0xFF7e61f3))),
                      ],
                    ),
                  if (task.deadline!.isBefore(DateTime.now()))
                    Row(
                      children: [
                        Icon(Icons.warning_amber, size: 12, color: Colors.red),
                        const SizedBox(width: 4),
                        Text('Просрочено', style: TextStyle(fontSize: 10, color: Colors.red)),
                      ],
                    ),
                ],
              ),
              trailing: Checkbox(
                value: task.is_completed,
                onChanged: (value) async {
                  if (value == null) return;

                    // Оптимистичное обновление
                    final now = DateTime.now();
                    final updatedTask = task.copyWith(
                      is_completed: value,
                      updatedAt: now,
                    );

                    // Обновляем в списке
                    setState(() {
                      _upcomingTasks[index] = updatedTask;
                      // Удаляем из списка, если выполнена
                      if (updatedTask.is_completed) {
                        _upcomingTasks.removeAt(index);
                      }
                    });

                    // Сохраняем в БД и синхронизируем
                    await _db.updateTask(updatedTask);
                    await _db.syncTasksToSupabase();
                  },
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
                  _loadData(); // Обновляем после редактирования
                }
              },
            ),
          ),
        ],
      );
    }).toList();
  }

  Color _getPriorityColor(String? priority) {
    return switch (priority) {
      'high' => Colors.red,
      'medium' => Colors.orange,
      'low' => Colors.green,
      _ => Colors.grey,
    };
  }

  String _getPriorityInitial(String? priority) {
    return switch (priority) {
      'high' => 'В',
      'medium' => 'С',
      'low' => 'Н',
      _ => '?',
    };
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

  String _getCategoryText(String? category) {
    return switch (category) {
      'работа' => 'Работа',
      'личное' => 'Личное',
      'учёба' => 'Учёба',
      'другое' => 'Другое',
      _ => 'Без категории',
    };
  }
}