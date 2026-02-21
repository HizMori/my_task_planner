import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../screens/create_task_screen.dart';

class EisenhowerScreen extends StatefulWidget {
  final String? groupId;
  final bool hideAppBar;
  const EisenhowerScreen({super.key, this.groupId,  this.hideAppBar = false});

  @override
  State<EisenhowerScreen> createState() => _EisenhowerScreenState();
}

class _EisenhowerScreenState extends State<EisenhowerScreen> {
  
  Future<Map<String, dynamic>> _loadData() async {
    final userId = await AuthService.instance.getCurrentUserId();
    if (userId == null) {
      return {'tasks': <Task>[], 'userId': null};
    }

    List<Task> allTasks;

    if (widget.groupId != null) {
      // Загружаем только групповые задачи для этой группы
      final db = DatabaseService.instance;
      allTasks = await db.readAllTasks();
      allTasks = allTasks
          .where((task) => task.groupId == widget.groupId)
          .toList();
    } else {
      // Загружаем все задачи пользователя (личные + групповые)
      allTasks = await DatabaseService.instance.readUserTasks(userId);
    }
    return {
      'tasks': allTasks,
      'userId': userId,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: Text(widget.groupId != null ? 'Матрица группы' : 'Матрица Эйзенхауэра'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Нет данных'));
          }

          final data = snapshot.data!;
          final List<Task> tasks = data['tasks'];
          final String? currentUserId = data['userId'];

          // Фильтруем задачи по квадрантам
          final urgentImportant = tasks
              .where((t) => t.urgency == 'urgent' && t.priority == 'high')
              .toList();
          final importantNotUrgent = tasks
              .where((t) => t.urgency == 'not_urgent' && t.priority == 'high')
              .toList();
          final urgentNotImportant = tasks
              .where((t) => t.urgency == 'urgent' && t.priority != 'high')
              .toList();
          final notUrgentNotImportant = tasks
              .where((t) => t.urgency == 'not_urgent' && t.priority != 'high')
              .toList();

          final List<List<Task>> quadrants = [
            urgentImportant,
            importantNotUrgent,
            urgentNotImportant,
            notUrgentNotImportant,
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final double blockWidth = constraints.maxWidth / 2;
              final double blockHeight =
                  (constraints.maxHeight - kToolbarHeight + 14) / 2;

              return Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildQuadrantWrapper(
                            context, blockWidth, blockHeight, 0, quadrants[0], currentUserId),
                        _buildQuadrantWrapper(
                            context, blockWidth, blockHeight, 1, quadrants[1], currentUserId),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildQuadrantWrapper(
                            context, blockWidth, blockHeight, 2, quadrants[2], currentUserId),
                        _buildQuadrantWrapper(
                            context, blockWidth, blockHeight, 3, quadrants[3], currentUserId),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuadrantWrapper(
    BuildContext context,
    double width,
    double height,
    int index,
    List<Task> tasks,
    String? currentUserId,
  ) {
    final titles = [
      'Срочно и важно',
      'Не срочно, но важно',
      'Срочно, но не важно',
      'Не срочно и не важно',
    ];

    final colors = [
      const Color(0xFFFF3B30),
      const Color(0xFFFFCC00),
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
    ];

    final romans = ['I', 'II', 'III', 'IV'];

    return SizedBox(
      width: width,
      height: height,
      child: _buildQuadrant(
        context,
        title: titles[index],
        color: colors[index],
        tasks: tasks,
        roman: romans[index],
        currentUserId: currentUserId,
      ),
    );
  }

  Widget _buildQuadrant(
    BuildContext context, {
    required String title,
    required Color color,
    required List<Task> tasks,
    required String roman,
    required String? currentUserId,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = isLight ? Colors.white : const Color(0xFF1F1F1F);

    return Card(
      color: cardColor,
      elevation: isLight ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      roman,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'Нет задач',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isLight ? Colors.grey[500] : Colors.grey[400],
                          ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: tasks.length,
                    itemBuilder: (context, idx) {
                      final task = tasks[idx];
                      final bool isCreator = task.creatorId == currentUserId;
                      final bool isGroupTask = task.groupId != null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateTaskScreen(task: task),
                              ),
                            );
                            if (result == true && mounted) {
                              // Обновляем экран после редактирования
                              setState(() {});
                            }
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: task.is_completed,
                                onChanged: (value) async {
                                  final updatedTask = task.copyWith(
                                    is_completed: !task.is_completed,
                                    updatedAt: DateTime.now(),
                                  );
                                  await DatabaseService.instance
                                      .updateTask(updatedTask);
                                  await DatabaseService.instance
                                      .syncTasksToSupabase();
                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                                activeColor: color,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: BorderSide(
                                  color: isLight
                                      ? Colors.grey[400]!
                                      : Colors.grey[500]!,
                                  width: 1.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: task.is_completed
                                      ? Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Colors.grey,
                                          )
                                      : null,
                                ),
                              ),
                              if (isGroupTask)
                                Icon(
                                  Icons.groups,
                                  size: 16,
                                  color: Colors.blueGrey.withOpacity(0.7),
                                ),
                              if (!isCreator)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.visibility,
                                    size: 16,
                                    color: Colors.grey.withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  void setState(VoidCallback fn) {
    // Этот метод нужен, чтобы Flutter понял, что состояние изменилось
    // Но так как мы в StatelessWidget — нужно переделать в Stateful
  }
}