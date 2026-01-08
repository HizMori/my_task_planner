import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../models/user.dart'; // Модель
import '../services/auth_service.dart'; // Для logout

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  bool _isLoading = true;
  
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
  void initState() {
    super.initState();
    _loadUser();
  }

  // Загрузка данных пользователя
  Future<void> _loadUser() async {
    final userId = await AuthService.instance.getCurrentUserId();
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final user = await DatabaseService.instance.readUserById(userId);
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Главное')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Главное')),
        body: const Center(child: Text('Пользователь не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Главное'),
        automaticallyImplyLeading: false,
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Приветствие
            Text(
              '${_getGreeting()}, ${_user!.name}!',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
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
                    return Center(child: Text('Нет задач на сегодня'));
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
                      return Center(child: Text('Нет задач на сегодня'));
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
                              value: task.is_completed,
                              onChanged: (value) {
                                setState(() {
                                  _databaseService.updateTask(
                                    task.copyWith(is_completed: value),
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
