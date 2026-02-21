import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../widgets/online_status_icon.dart';
import 'create_task_screen.dart';
import '../services/auth_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Task> _tasks = [];
  bool _isLoading = true;

 @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _databaseService.syncTasksFromSupabase();
      await _databaseService.syncTasksToSupabase();
      _loadTasks();
    });
  }

  Future<void> _loadTasks() async {
    try {
      final userId = await AuthService.instance.getCurrentUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final allUserTasks = await _databaseService.readUserTasks(userId);
      final personalTasks = allUserTasks.where((task) => task.groupId == null).toList();

      if (mounted) {
        setState(() {
          _tasks = personalTasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки задач: $e')),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    await _databaseService.deleteTask(task.id);
    _loadTasks();
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
    await _databaseService.updateTask(updatedTask);
    // Не обязательно вызывать _loadTasks() — мы уже обновили UI
    await _databaseService.syncTasksToSupabase(); // Отправляем изменения в Supabase
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи'),
        actions: [
          const OnlineStatusIcon(),
          const SizedBox(width: 12),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Основной контент
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.checklist_outlined, size: 60, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Нет задач',
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
                                    subtitle: Wrap(
                                      spacing: 8,
                                      children: [
                                        _buildLabel(_getPriorityText(task.priority), _getPriorityColor(task.priority)),
                                        _buildLabel(_getCategoryText(task.category), const Color(0xFF7e61f3)),
                                        _buildLabel(_getUrgencyText(task.urgency), _getUrgencyColor(task.urgency))
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
        ],
      ),
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