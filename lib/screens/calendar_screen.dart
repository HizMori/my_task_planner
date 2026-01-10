import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../services/database_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _databaseService.readAllTasks();
    final Map<DateTime, List<Task>> eventMap = {};
    for (var task in tasks) {
      if (task.deadline != null) {
        final date = DateTime(
          task.deadline!.year,
          task.deadline!.month,
          task.deadline!.day,
        );
        if (eventMap[date] == null) {
          eventMap[date] = [];
        }
        eventMap[date]!.add(task);
      }
    }
    setState(() {
      _events = eventMap;
    });
  }

  List<Task> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Календарь')), // Стиль из AppBarTheme
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.primaryColor, // Используем #7e61f3
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.deepOrange,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: theme.primaryColor, // Заменили Colors.green на #7e61f3
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    final theme = Theme.of(context);
    final tasks = _getEventsForDay(_selectedDay!);

    if (tasks.isEmpty) {
      return Center(
        child: Text(
          'Нет задач на этот день',
          style: theme.textTheme.bodyMedium, // Явно применяем стиль
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: Text(
            task.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600, // Делаем заголовок чуть жирнее
              color: theme.primaryColor, // #7e61f3 для соответствия теме
            ),
          ),
          subtitle: Text(
            '${task.category ?? 'Без категории'} • ${task.priority ?? 'Без приоритета'}',
            style: theme.textTheme.bodySmall, // Соответствует теме
          ),
          trailing:
              task.is_completed
                  ? Icon(
                    Icons.check,
                    color: Colors.green, // Оставим зелёный для завершённых
                  )
                  : Icon(
                    Icons.hourglass_empty,
                    color: theme.primaryColor, // #7e61f3 для незавершённых
                  ),
        );
      },
    );
  }
}
