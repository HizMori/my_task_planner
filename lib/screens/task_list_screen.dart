import 'package:flutter/material.dart';
import '../models/task.dart'; // Импортируем модель задачи
import '../services/database_service.dart'; // Импортируем сервис базы данных

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
      appBar: AppBar(title: const Text('Задачи')),
      body: _tasks.isEmpty
          ? const Center(child: Text('Нет задач'))
          : ListView.builder(
              itemCount: _tasks.length, // Количество задач в списке
              itemBuilder: (context, index) {
                final task = _tasks[index]; // Получаем задачу по индексу
                return Dismissible(
                  key: Key(
                    task.id.toString(),
                  ), // Уникальный ключ для элемента (нужен для удаления свайпом)
                  onDismissed: (direction) async {
                    await _databaseService.deleteTask(
                      task.id!,
                    ); // Удаляем задачу из базы данных
                    _loadTasks(); // Обновляем список после удаления
                  },
                  background: Container(
                    color: Colors.red,
                  ), // Фон при свайпе (красный)
                  child: Card(
                    child: ListTile(
                      title: Text(task.title), // Отображаем название задачи
                      subtitle: Text(
                        '${task.category} • ${_getPriorityText(task.priority)}',
                      ), // Отображаем категорию и приоритет
                      trailing: Checkbox(
                        value: task.is_completed, // Текущий статус выполнения
                        onChanged: (value) async {
                          await _databaseService.updateTask(
                            task.copyWith(is_completed: value),
                          ); // Обновляем статус задачи
                          _loadTasks(); // Обновляем список
                        },
                      ),
                      onTap: () {
                        // Здесь можно добавить переход к редактированию задачи
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Добавьте навигацию к экрану создания задачи
          // Например: Navigator.push(context, MaterialPageRoute(builder: (context) => CreateTaskScreen()));
        },
        child: const Icon(Icons.add),
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