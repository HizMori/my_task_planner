import 'package:flutter/material.dart';
import '../models/task.dart'; // Импортируем модель задачи
import '../services/database_service.dart'; // Импортируем сервис базы данных
import '../main.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>(); // Ключ для управления формой
  String _title = ''; // Переменная для хранения названия задачи
  String _description = ''; // Переменная для хранения описания задачи
  DateTime? _deadline; // Переменная для хранения дедлайна (может быть null)
  String _priority =
      'medium'; // Переменная для хранения приоритета (по умолчанию "medium")
  String _category =
      'работа'; // Переменная для хранения категории (по умолчанию "работа")
  final DatabaseService _databaseService =
      DatabaseService.instance; // Экземпляр сервиса базы данных

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удаление задачи'),
          content: const Text('Удалить эту задачу?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Отмена — возвращаем false
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Удалить — возвращаем true
              },
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    // Если пользователь подтвердил удаление (result == true), закрываем экран
    if (result == true) {
      MainScreen.of(context)?.popScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новая задача'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Кнопка "Назад"
          onPressed: () {
            MainScreen.of(
              context,
            )?.popScreen(); // Возвращаемся на предыдущий экран
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmationDialog(context);
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Удалить',
                      style: TextStyle(
                        color:
                            theme
                                .textTheme
                                .bodyMedium
                                ?.color, // Цвет текста из темы
                      ),
                    ),
                  ),
                ],
            // Стилизуем фон и форму выпадающего меню
            color: theme.scaffoldBackgroundColor, // Фон меню
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Закруглённые углы
            ),
            elevation: 4, // Тень
            offset: const Offset(
              0,
              kToolbarHeight - 10,
            ), // Смещаем меню вниз на высоту AppBar
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Отступы внутри экрана
        child: Form(
          key: _formKey, // Привязываем ключ к форме для валидации
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Название',
                ), // Поле ввода названия
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название'; // Проверка, что поле не пустое
                  }
                  return null;
                },
                onSaved:
                    (value) => _title = value!, // Сохраняем введенное значение
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Описание',
                ), // Поле ввода описания
                onSaved:
                    (value) =>
                        _description =
                            value ??
                            '', // Сохраняем введенное значение (или пустую строку)
              ),
              ListTile(
                title: Text(
                  _deadline == null ? 'Выбрать дедлайн' : _deadline.toString(),
                ), // Отображаем дедлайн или приглашение выбрать его
                trailing: const Icon(Icons.calendar_today), // Иконка календаря
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(), // Начальная дата — текущая
                    firstDate: DateTime.now(), // Минимальная дата — текущая
                    lastDate: DateTime(2100), // Максимальная дата — 2100 год
                  );
                  if (date != null && context.mounted) {
                    // Проверяем context перед вторым await
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(), // Начальное время — текущее
                    );
                    if (time != null && context.mounted) {
                      // Проверяем context перед setState
                      setState(() {
                        _deadline = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        ); // Устанавливаем полный дедлайн (дата + время)
                      });
                    }
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: _priority, // Текущий выбранный приоритет
                decoration: const InputDecoration(
                  labelText: 'Приоритет',
                ), // Поле выбора приоритета
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Низкий')),
                  DropdownMenuItem(value: 'medium', child: Text('Средний')),
                  DropdownMenuItem(value: 'high', child: Text('Высокий')),
                ],
                onChanged:
                    (value) => setState(
                      () => _priority = value!,
                    ), // Обновляем приоритет при выборе
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Категория',
                ), // Поле ввода категории
                initialValue: _category, // Начальное значение категории
                onSaved:
                    (value) =>
                        _category =
                            value ??
                            'работа', // Сохраняем категорию (по умолчанию "работа")
              ),
              const SizedBox(height: 20), // Добавляем отступ перед кнопкой
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Проверяем, что форма заполнена корректно
                    _formKey.currentState!
                        .save(); // Сохраняем все данные из формы
                    final task = Task(
                      title: _title,
                      description: _description,
                      deadline: _deadline,
                      priority: _priority,
                      category: _category,
                    ); // Создаем объект задачи
                    await _databaseService.create(task);
                    MainScreen.of(context)?.popScreen();
                  }
                },
                child: const Text('Сохранить'), // Текст кнопки сохранения
              ),
            ],
          ),
        ),
      ),
    );
  }
}
