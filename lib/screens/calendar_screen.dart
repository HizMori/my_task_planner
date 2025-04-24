import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart'; // Импорт модели задачи
import '../services/database_service.dart'; // Импорт сервиса для работы с базой данных

// Класс экрана календаря, наследуемся от StatefulWidget, так как экран будет динамически обновляться
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

// Состояние экрана календаря
class _CalendarScreenState extends State<CalendarScreen> {
  final DatabaseService _databaseService =
      DatabaseService.instance; // Экземпляр сервиса базы данных
  DateTime _focusedDay =
      DateTime.now(); // День, на который сейчас сфокусирован календарь
  DateTime? _selectedDay; // День, который пользователь выбрал (может быть null)
  Map<DateTime, List<Task>> _events =
      {}; // Карта: ключ — дата, значение — список задач на эту дату

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // При запуске выбираем текущий день
    _loadTasks(); // Загружаем задачи из базы данных
  }

  // Асинхронный метод для загрузки всех задач и их группировки по датам
  Future<void> _loadTasks() async {
    final tasks =
        await _databaseService.readAllTasks(); // Получаем все задачи из базы
    final Map<DateTime, List<Task>> eventMap =
        {}; // Временная карта для событий
    for (var task in tasks) {
      if (task.deadline != null) {
        // Проверяем, есть ли у задачи дедлайн
        // Создаём объект даты без времени (только год, месяц, день)
        final date = DateTime(
          task.deadline!.year,
          task.deadline!.month,
          task.deadline!.day,
        );
        if (eventMap[date] == null) {
          eventMap[date] =
              []; // Если для этой даты ещё нет списка задач, создаём его
        }
        eventMap[date]!.add(task); // Добавляем задачу в список для этой даты
      }
    }
    setState(() {
      _events = eventMap; // Обновляем состояние с новыми событиями
    });
  }

  // Метод для получения списка задач на конкретный день
  List<Task> _getEventsForDay(DateTime day) {
    final date = DateTime(
      day.year,
      day.month,
      day.day,
    ); // Приводим дату к формату без времени
    return _events[date] ??
        []; // Возвращаем список задач или пустой список, если задач нет
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь'),
        backgroundColor:
            Theme.of(context).primaryColor, // Заголовок экрана в верхней панели
        leading: IconButton(
          icon: const Icon(Icons.menu), // Кнопка для открытия Drawer
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      body: Column(
        children: [
          // Виджет календаря из пакета table_calendar
          TableCalendar(
            firstDay: DateTime.utc(
              2020,
              1,
              1,
            ), // Самая ранняя дата, которую можно выбрать
            lastDay: DateTime.utc(2030, 12, 31), // Самая поздняя дата
            focusedDay:
                _focusedDay, // День, на который сейчас сфокусирован календарь
            selectedDayPredicate:
                (day) =>
                    isSameDay(_selectedDay, day), // Проверяем, выбран ли день
            onDaySelected: (selectedDay, focusedDay) {
              // Обработчик выбора дня пользователем
              setState(() {
                _selectedDay = selectedDay; // Обновляем выбранный день
                _focusedDay = focusedDay; // Обновляем фокус
              });
            },
            eventLoader:
                _getEventsForDay, // Функция, которая возвращает задачи для каждого дня
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent, // Цвет кружка для сегодняшнего дня
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepOrange, // Цвет кружка для выбранного дня
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.green, // Цвет маркера для дней с задачами
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(
            height: 8.0,
          ), // Отступ между календарём и списком задач
          Expanded(
            child: _buildTaskList(), // Список задач на выбранный день
          ),
        ],
      ),
    );
  }

  // Метод для построения списка задач под календарём
  Widget _buildTaskList() {
    final tasks = _getEventsForDay(
      _selectedDay!,
    ); // Получаем задачи для выбранного дня
    if (tasks.isEmpty) {
      return const Center(
        child: Text('Нет задач на этот день'),
      ); // Если задач нет, показываем сообщение
    }
    return ListView.builder(
      itemCount: tasks.length, // Количество задач в списке
      itemBuilder: (context, index) {
        final task = tasks[index]; // Текущая задача из списка
        return ListTile(
          title: Text(task.title), // Название задачи
          subtitle: Text(
            '${task.category} • ${task.priority}',
          ), // Категория и приоритет задачи
          trailing:
              task.isCompleted
                  ? const Icon(
                    Icons.check,
                    color: Colors.green,
                  ) // Иконка для завершённой задачи
                  : const Icon(
                    Icons.hourglass_empty,
                    color: Colors.red,
                  ), // Иконка для незавершённой
        );
      },
    );
  }
}
