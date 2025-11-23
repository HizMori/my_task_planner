import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../main.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  DateTime? _deadline;
  String _priority = 'medium';
  String _category = 'работа';
  final String _creatorId = 'current_user'; // Добавьте реальный ID пользователя
  final DatabaseService _databaseService = DatabaseService.instance;

  // Ключи для получения позиции контейнеров
  final _priorityKey = GlobalKey();
  final _categoryKey = GlobalKey();

  bool _isPriorityActive = false;
  bool _isCategoryActive = false;
  bool _isPriorityMenuOpen = false;
  bool _isCategoryMenuOpen = false;

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удаление задачи'),
          content: const Text('Удалить эту задачу?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      MainScreen.of(context)?.popScreen();
    }
  }

  // Обновлённая функция для отображения выпадающего меню под строкой
  Future<void> _showDropdownMenu({
    required BuildContext context,
    required GlobalKey key,
    required List<String> items,
    required String selectedValue,
    required ValueChanged<String> onChanged,
    required VoidCallback onClose,
  }) async {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size; // Получаем ширину строки

    // Позиция меню начинается под нижней границей контейнера
    final Offset menuPosition = Offset(
      localPosition.dx,
      localPosition.dy + size.height,
    );

    final selectedItem = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        menuPosition.dx,
        menuPosition.dy,
        menuPosition.dx +
            size.width, // Ширина меню равна ширине строки (без регулировки)
        menuPosition.dy +
            (items.length *
                48.0), // Высота меню, основанная на количестве элементов
      ),
      items:
          items.map((item) {
            final isSelected =
                item == selectedValue; // Проверяем, выбран ли элемент
            return PopupMenuItem<String>(
              value: item,
              padding:
                  EdgeInsets.zero, // Убираем внутренние отступы PopupMenuItem
              child: Container(
                width: double.infinity, // Растягиваем на всю доступную ширину
                height:
                    48.0, // Фиксированная высота, чтобы соответствовать стандартной высоте PopupMenuItem
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? const Color(0xFF7e61f3)
                          : null, // Фиолетовый фон для выбранного элемента
                  borderRadius: BorderRadius.zero,
                ),
                alignment:
                    Alignment.centerLeft, // Выравниваем текст по левому краю
                child: Text(
                  item == 'low'
                      ? 'Низкий'
                      : item == 'medium'
                      ? 'Средний'
                      : item == 'high'
                      ? 'Высокий'
                      : item == 'работа'
                      ? 'Работа'
                      : item == 'личное'
                      ? 'Личное'
                      : item == 'учёба'
                      ? 'Учёба'
                      : 'Другое',
                  style: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            );
          }).toList(),
      initialValue: selectedValue,
      color:
          Colors.white, // Устанавливаем белый фон для всего выпадающего списка
    );

    // Вызываем onChanged, если элемент выбран
    if (selectedItem != null) {
      onChanged(selectedItem);
    }

    // Сбрасываем состояние после закрытия меню
    onClose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Новая задача'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => MainScreen.of(context)?.popScreen(),
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
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Удалить'),
                  ),
                ],
            color: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            offset: const Offset(0, kToolbarHeight - 10),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Название',
                  labelStyle: theme.textTheme.bodyMedium,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Введите название';
                  return null;
                },
                onSaved: (value) => _title = value!,
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Описание',
                  labelStyle: theme.textTheme.bodyMedium,
                ),
                onSaved: (value) => _description = value ?? '',
              ),
              ListTile(
                title: Text(
                  _deadline == null ? 'Выбрать дедлайн' : _deadline.toString(),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null && context.mounted) {
                      setState(() {
                        _deadline = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Приоритет', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  GestureDetector(
                    key: _priorityKey,
                    onTap: () {
                      if (_isPriorityMenuOpen) {
                        // Если меню открыто, закрываем его и сбрасываем состояние
                        setState(() {
                          _isPriorityActive = false;
                          _isPriorityMenuOpen = false;
                        });
                        return;
                      }

                      // Открываем меню и устанавливаем активное состояние
                      setState(() {
                        _isPriorityActive = true;
                        _isPriorityMenuOpen = true;
                      });

                      _showDropdownMenu(
                        context: context,
                        key: _priorityKey,
                        items: ['low', 'medium', 'high'],
                        selectedValue: _priority,
                        onChanged: (value) => setState(() => _priority = value),
                        onClose:
                            () => setState(() {
                              _isPriorityActive = false;
                              _isPriorityMenuOpen = false;
                            }),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              _isPriorityActive
                                  ? const Color(0xFF7e61f3)
                                  : Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _priority == 'low'
                                ? 'Низкий'
                                : _priority == 'medium'
                                ? 'Средний'
                                : 'Высокий',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Категория', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  GestureDetector(
                    key: _categoryKey,
                    onTap: () {
                      if (_isCategoryMenuOpen) {
                        // Если меню открыто, закрываем его и сбрасываем состояние
                        setState(() {
                          _isCategoryActive = false;
                          _isCategoryMenuOpen = false;
                        });
                        return;
                      }

                      // Открываем меню и устанавливаем активное состояние
                      setState(() {
                        _isCategoryActive = true;
                        _isCategoryMenuOpen = true;
                      });

                      _showDropdownMenu(
                        context: context,
                        key: _categoryKey,
                        items: ['работа', 'личное', 'учёба', 'другое'],
                        selectedValue: _category,
                        onChanged: (value) => setState(() => _category = value),
                        onClose:
                            () => setState(() {
                              _isCategoryActive = false;
                              _isCategoryMenuOpen = false;
                            }),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              _isCategoryActive
                                  ? const Color(0xFF7e61f3)
                                  : Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _category == 'работа'
                                ? 'Работа'
                                : _category == 'личное'
                                ? 'Личное'
                                : _category == 'учёба'
                                ? 'Учёба'
                                : 'Другое',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final now = DateTime.now(); // Текущее время
                    final task = Task(
                      title: _title,
                      description: _description,
                      deadline: _deadline,
                      priority: _priority,
                      category: _category,
                      creatorId: _creatorId,
                      createdAt: now, // Устанавливаем текущее время
                      updatedAt: now, // Устанавливаем текущее время
                      last_sync_at: null,
                    );
                    await _databaseService.createTask(task);
                    if (context.mounted) {
                      MainScreen.of(context)?.popScreen();
                    }
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}