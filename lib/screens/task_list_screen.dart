import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../widgets/online_status_icon.dart';
import 'create_task_screen.dart';

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
      final tasks = await _databaseService.readAllTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
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
    final updatedTask = task.copyWith(is_completed: !task.is_completed);
    await _databaseService.updateTask(updatedTask);
    _loadTasks();
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
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                                        _buildLabel(
                                          _getPriorityText(task.priority),
                                          _getPriorityColor(task.priority),
                                        ),
                                        _buildLabel(
                                          _getCategoryText(task.category),
                                          const Color(0xFF7e61f3),
                                        ),
                                      ],
                                    ),
                                    trailing: Checkbox(
                                      value: task.is_completed,
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
      'low' => 'Низкий',
      'medium' => 'Средний',
      'high' => 'Высокий',
      _ => 'Не указан',
    };
  }

  Color _getPriorityColor(String? priority) {
    return switch (priority) {
      'low' => Colors.green,
      'medium' => Colors.orange,
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
}