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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Задачи')),
      body: FutureBuilder<List<Task>>(
        future:
            _databaseService
                .readAllTasks(), // Асинхронно загружаем список задач
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            ); // Показываем индикатор загрузки
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка: ${snapshot.error}'),
            ); // Показываем сообщение об ошибке
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Нет задач')); // Если задач нет
          } else {
            final tasks = snapshot.data!; // Получаем список задач из snapshot
            return ListView.builder(
              itemCount: tasks.length, // Количество задач в списке
              itemBuilder: (context, index) {
                final task = tasks[index]; // Получаем задачу по индексу
                return Dismissible(
                  key: Key(
                    task.id.toString(),
                  ), // Уникальный ключ для элемента (нужен для удаления свайпом)
                  onDismissed: (direction) {
                    _databaseService.delete(
                      task.id!,
                    ); // Удаляем задачу из базы данных
                    setState(() {}); // Обновляем экран после удаления
                  },
                  background: Container(
                    color: Colors.red,
                  ), // Фон при свайпе (красный)
                  child: Card(
                    child: ListTile(
                      title: Text(task.title), // Отображаем название задачи
                      subtitle: Text(
                        '${task.category} • ${task.priority}',
                      ), // Отображаем категорию и приоритет
                      trailing: Checkbox(
                        value: task.isCompleted, // Текущий статус выполнения
                        onChanged: (value) {
                          setState(() {
                            _databaseService.update(
                              task.copyWith(isCompleted: value),
                            ); // Обновляем статус задачи
                          });
                        },
                      ),
                      onTap: () {
                        // Здесь можно добавить переход к редактированию задачи
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
