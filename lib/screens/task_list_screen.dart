import 'package:flutter/material.dart';
import '../models/task.dart'; // Импортируем модель задачи
import '../services/database_service.dart'; // Импортируем сервис базы данных
import '../widgets/online_status_icon.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final DatabaseService _databaseService =
      DatabaseService.instance; // Создаем экземпляр сервиса базы данных
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _databaseService.readAllTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи'),
        actions: [
          const OnlineStatusIcon(),
          const SizedBox(width: 12),
        ],
        automaticallyImplyLeading: false,
        ),
      body: _tasks.isEmpty
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
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return Dismissible(
                key:Key(task.id ?? ''),
                onDismissed: (direction) async {
                  // Сохраняем копию задачи на случай, если нужно будет отменить
                  final removedTask = task;
                  final removedIndex = index;
                   // Удаляем из БД
                  await _databaseService.deleteTask(task.id);
                  // Удаляем из списка СРАЗУ (без ожидания перезагрузки)
                  setState(() {
                    _tasks.removeAt(index);
                  });
                  // Показываем Snackbar с возможностью отмены (опционально)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Задача удалена'),
                      action: SnackBarAction(
                        label: 'Отменить',
                        onPressed: () async {
                          // Возвращаем задачу обратно
                          setState(() {
                            _tasks.insert(removedIndex, removedTask);
                          });
                          // И восстанавливаем в БД
                          await _databaseService.createTask(removedTask);
                        },
                      ),
                    ),
                  );
                },
                background: Container(color: Colors.red),
                child: Card(
                  child: ListTile(
                    title: Text(task.title),
                    subtitle: Text(
                      '${task.category} • ${_getPriorityText(task.priority)}',
                    ),
                    trailing: Checkbox(
                      value: task.is_completed,
                      onChanged: (value) async {
                        await _databaseService.updateTask(task.copyWith(is_completed: value));
                        _loadTasks();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
  }

  String _getPriorityText(String? priority) {
    switch (priority) {
      case 'low':
        return 'Низкий';
      case 'medium':
        return 'Средний';
      case 'high':
        return 'Высокий';
      default:
        return 'Не указан';
    }
  }
}