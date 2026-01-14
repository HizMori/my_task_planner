import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/group.dart';
import '../services/database_service.dart';
import 'create_task_screen.dart';
import '../main.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final allTasks = await _db.readAllTasks();
      final groupTasks = allTasks
          .where((task) => task.groupId == widget.group.id)
          .toList();
      setState(() {
        _tasks = groupTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки задач: $e')),
      );
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
    final updatedTask = task.copyWith(is_completed: !task.is_completed);
    await _db.updateTask(updatedTask);
    _loadTasks(); // Обновляем список
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