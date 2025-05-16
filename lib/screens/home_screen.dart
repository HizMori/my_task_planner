import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Импортируем для явного использования Poppins
import '../models/task.dart';
import '../services/database_service.dart';
import 'create_task_screen.dart';
import 'create_note_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Главное')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Приветствие
            Text(
              '${_getGreeting()}, Kawai Fukuro!',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            // Кнопки быстрого действия
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateTaskScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    icon: const Icon(Icons.check_box, color: Colors.white),
                    label: const Text(
                      'Добавить задачу',
                    ), // Стиль из elevatedButtonTheme
                    style: theme.elevatedButtonTheme.style,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateNoteScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    icon: const Icon(Icons.note, color: Colors.white),
                    label: const Text(
                      'Добавить заметку',
                    ), // Стиль из elevatedButtonTheme
                    style: theme.elevatedButtonTheme.style,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Заголовок "Задачи на сегодня"
            Text('Задачи на сегодня', style: theme.textTheme.headlineLarge),
            const SizedBox(height: 16),
            // Список задач на сегодня
            Expanded(
              child: FutureBuilder<List<Task>>(
                future: _databaseService.readAllTasks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Ошибка: ${snapshot.error}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'Нет задач на сегодня',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  } else {
                    final tasks =
                        snapshot.data!.where((task) {
                          if (task.dueDate == null) return false;
                          final dueDate = DateTime.parse(task.dueDate!);
                          final today = DateTime.now();
                          return dueDate.year == today.year &&
                              dueDate.month == today.month &&
                              dueDate.day == today.day;
                        }).toList();

                    if (tasks.isEmpty) {
                      return Center(
                        child: Text(
                          'Нет задач на сегодня',
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Card(
                          color: const Color(0xFFF5F5DC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              color: Color(0xFF6B705C),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              task.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF2A9D8F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${task.category ?? 'Без категории'} • ${task.priority ?? 'Без приоритета'}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                            trailing: Checkbox(
                              value: task.isCompleted,
                              onChanged: (value) {
                                setState(() {
                                  _databaseService.update(
                                    task.copyWith(isCompleted: value),
                                  );
                                });
                              },
                            ),
                            onTap: () {
                              // Можно добавить переход к редактированию задачи
                            },
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
