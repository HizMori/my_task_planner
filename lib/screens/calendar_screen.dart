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

  Color _getPriorityColor(String? priority) {
    return switch (priority) {
      'high' => Colors.red,
      'medium' => Colors.orange,
      'low' => Colors.green,
      _ => Colors.grey,
    };
  }

  String _getPriorityInitial(String? priority) {
    return switch (priority) {
      'high' => 'В',
      'medium' => 'С',
      'low' => 'Н',
      _ => '?',
    };
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

  String _getCategoryText(String? category) {
    return switch (category) {
      'работа' => 'Работа',
      'личное' => 'Личное',
      'учёба' => 'Учёба',
      'другое' => 'Другое',
      _ => 'Без категории',
    };
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 24), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Календарь')
        ),
      body: Column(
        children: [
          // Кастомный заголовок с кнопками и названием месяца
          _buildCustomHeader(theme.textTheme),
          const SizedBox(height: 8),
          // Календарь БЕЗ встроенного заголовка
          TableCalendar(
            locale: 'ru_RU',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            headerVisible: false,
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
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.deepOrange,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              // Можно немного увеличить отступы для дней
              cellPadding: const EdgeInsets.all(4.0),
            ),
            // Увеличиваем высоту строки дней недели
            daysOfWeekHeight: 20,
            // Опционально: кастомный стиль для дней недели
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              weekendStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            startingDayOfWeek: StartingDayOfWeek.monday,
          ),
          const SizedBox(height: 8.0),
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }

  // Кастомный заголовок с названием месяца и кнопками
  Widget _buildCustomHeader(TextTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Кнопка "Назад"
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
              });
            },
          ),
          // Название месяца и года
          Text(
            '${_getMonthName(_focusedDay.month)} ${_focusedDay.year} г.',
            style: theme.headlineMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          // Кнопка "Вперёд"
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
              });
            },
          ),
        ],
      ),
    );
  }

  // Перевод номера месяца в название с большой буквы
  String _getMonthName(int month) {
    return switch (month) {
      1 => 'Январь',
      2 => 'Февраль',
      3 => 'Март',
      4 => 'Апрель',
      5 => 'Май',
      6 => 'Июнь',
      7 => 'Июль',
      8 => 'Август',
      9 => 'Сентябрь',
      10 => 'Октябрь',
      11 => 'Ноябрь',
      12 => 'Декабрь',
      _ => 'Неизвестно',
    };
  }

  Widget _buildTaskList() {
    final theme = Theme.of(context);
    final tasks = _getEventsForDay(_selectedDay!);
    final now = DateTime.now();

    if (tasks.isEmpty) {
      return Center(
        child: Text(
          'Нет задач на этот день',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final deadline = task.deadline!;
        final isOverdue = !task.is_completed && deadline.isBefore(now);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Фон для просроченных задач
              if (isOverdue)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isOverdue ? Colors.red[300] : _getPriorityColor(task.priority),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _getPriorityInitial(task.priority),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  task.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: isOverdue ? TextDecoration.lineThrough : null,
                    color: isOverdue ? Colors.red[700] : null,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red[500] : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildLabel(
                          _getCategoryText(task.category),
                          const Color(0xFF7e61f3),
                        ),
                      ],
                    ),
                    if (isOverdue)
                      Row(
                        children: [
                          Icon(Icons.warning_amber, size: 10, color: Colors.red[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Просрочено',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                trailing: task.is_completed
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : isOverdue
                        ? const Icon(Icons.access_time, color: Colors.red)
                        : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
