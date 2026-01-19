import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../models/group.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import 'package:collection/collection.dart';
import '../widgets/user_avatar.dart';

class CreateTaskScreen extends StatefulWidget {
  // Добавляем возможность передать группу по умолчанию
  final String? initialGroupId;
  final Task? task;

  const CreateTaskScreen({super.key, this.initialGroupId, this.task});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _deadline;
  String _priority = 'medium';
  String _category = 'работа';
  String? _groupId; // null — значит личная задача
  late String _creatorId; // реальный ID
  String? _assignedTo; // ID пользователя, которому делегирована задача
  User? _assignedUser; // Для отображения имени/аватара

  final DatabaseService _databaseService = DatabaseService.instance;

  List<Group> _groups = [];
  bool _isLoadingGroups = true;

  // Ключи для выпадающих меню
  final _priorityKey = GlobalKey();
  final _categoryKey = GlobalKey();
  final _groupKey = GlobalKey();

  bool _isPriorityActive = false;
  bool _isCategoryActive = false;
  bool _isGroupActive = false;
  bool _isPriorityMenuOpen = false;
  bool _isCategoryMenuOpen = false;
  bool _isGroupMenuOpen = false;

  @override
  void initState() {
    super.initState();
    print('CreateTaskScreen: widget.task = $widget.task');
    _loadUserId().then((_) {
      // Только после того, как _creatorId загружен — грузим группы и задачу
      _loadGroups().then((_) {
        if (widget.task != null) {
          _loadTaskData();
        }
      });
    });
  }

  Future<void> _loadTaskData() async {
    final task = widget.task!;
    print('Загружаем задачу: id=${task.id}, title=${task.title}, description=${task.description}');

    if (mounted) {
      setState(() {
        _titleController.text = task.title;
        _descriptionController.text = task.description ?? '';
        _deadline = task.deadline;
        _priority = task.priority ?? 'medium';
        _category = task.category ?? 'работа';
        _groupId = task.groupId;
        _creatorId = task.creatorId;
        _assignedTo = task.assigned_to;
      });
    }

    if (_assignedTo != null) {
      final user = await _databaseService.readUserById(_assignedTo!);
      if (mounted) {
        setState(() {
          _assignedUser = user;
        });
      }
    } 
    print('Контроллеры заполнены: title="${_titleController.text}", description="${_descriptionController.text}"');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<List<User>> _loadGroupMembers(String groupId) async {
    try {
      final membersResponse = await _databaseService.supabase
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);
      
      print('Участники группы $groupId: ${membersResponse.length} человек'); 
      
      if (membersResponse.isEmpty) return [];

      final userIds = (membersResponse as List<Map<String, dynamic>>)
        .map((m) => m['user_id'] as String)
        .where((id) => id != _creatorId) // Исключаем себя
        .toList();

      if (userIds.isEmpty) return [];

       // Получаем актуальные данные пользователей из Supabase
      final usersResponse = await _databaseService.supabase
          .from('users')
          .select('id, name, email, telephone, created_at, updated_at')
          .filter('id', 'in', userIds);

      if (usersResponse.isEmpty) return [];

       // Преобразуем в список User
      return (usersResponse as List<Map<String, dynamic>>)
          .map((u) => User.fromMap(u))
          .toList();

    } catch (e) {
      print('Ошибка загрузки участников: $e');
      return [];
    }
  }

  Future<void> _showAssignUserDialog() async {
    if (_groupId == null) return;

    // Загружаем участников группы
    final allMembers = await _loadGroupMembers(_groupId!);
    if (allMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет участников в группе')),
      );
      return;
    }

    // Сохраняем начальное состояние
    final User? initialUser = _assignedUser;
    User? selectedUser = _assignedUser; // Текущий выбор в диалоге

    final result = await showDialog<User?>(
      context: context,
      builder: (context) {
        final TextEditingController searchController = TextEditingController();
        List<User> filteredMembers = allMembers;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Назначить участника'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Поисковая строка
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Поиск участника',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  filteredMembers = allMembers;
                                  setStateDialog(() {});
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (query) {
                        if (query.trim().isEmpty) {
                          filteredMembers = allMembers;
                        } else {
                          filteredMembers = allMembers
                              .where((user) => user.name.toLowerCase().contains(query.toLowerCase()))
                              .toList();
                        }
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    // Список участников
                    SizedBox(
                      height: 200,
                      child: filteredMembers.isEmpty
                          ? const Center(child: Text('Не найдено'))
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: filteredMembers.length,
                              itemBuilder: (context, index) {
                                final user = filteredMembers[index];
                                final isSelected = selectedUser?.id == user.id;
                                return ListTile(
                                  leading: UserAvatar(user: user, radius: 20),
                                  title: Text(user.name),
                                  subtitle: Text(user.email ?? 'Нет email'),
                                  trailing: isSelected
                                      ? const Icon(Icons.check, color: Colors.green)
                                      : null,
                                  onTap: () {
                                    setStateDialog(() {
                                      selectedUser = isSelected ? null : user;
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  tileColor: isSelected
                                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null), // ← Возвращаем null → отмена
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedUser), // ← Только если нажали "Назначить"
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7e61f3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.1),
                  ),
                  child: const Text(
                    'Назначить',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              scrollable: true,
            );
          },
        );
      },
    );

    // После закрытия диалога
    if (!mounted) return;

    // Если вернули null → пользователь нажал "Отмена" → ничего не меняем
    if (result == null) {
      // Ничего не делаем — состояние остаётся прежним
      return;
    }

    // Если вернули пользователя — обновляем
    if (result != _assignedUser) {
      setState(() {
        _assignedUser = result;
        _assignedTo = result?.id;
      });
    }
  }

  Future<void> _loadUserId() async {
    try {
      final response = await Supabase.instance.client.auth.getUser();
      final uid = response.user?.id;
      if (mounted) {
        setState(() {
          _creatorId = uid!;
        });
      }
    } catch (e) {
      print('Ошибка получения пользователя: $e');
    }
  }

  Future<void> _loadGroups() async {
    try {
      final response = await Supabase.instance.client.auth.getUser();
      final userId = response.user?.id;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoadingGroups = false;
          });
        }
        return;
      }

      final userGroups = await _databaseService.readUserGroups(userId);

      setState(() {
        _groups = userGroups;
        // Сохраняем группу задачи, если редактируем
        if (widget.task != null && widget.task!.groupId != null) {
          _groupId = widget.task!.groupId;
        } else {
          _groupId = widget.initialGroupId;
        }
        _isLoadingGroups = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGroups = false;
      });
    }
  }

  Future<void> _showDropdownMenu({
    required BuildContext context,
    required GlobalKey key,
    required List<String> items,
    required String selectedValue,
    required ValueChanged<String> onChanged,
    required VoidCallback onClose,
  }) async {
    final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final Offset menuPosition = Offset(
      localPosition.dx,
      localPosition.dy + size.height,
    );

    final selectedItem = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        menuPosition.dx,
        menuPosition.dy,
        menuPosition.dx + size.width,
        menuPosition.dy + (items.length * 48.0),
      ),
      items: items.map((item) {
        final isSelected = item == selectedValue;
        return PopupMenuItem<String>(
          value: item,
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: 48.0,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF7e61f3) : null,
              borderRadius: BorderRadius.zero,
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              _getDisplayText(item),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        );
      }).toList(),
      initialValue: selectedValue,
      color: Colors.white,
    );

    if (selectedItem != null) {
      onChanged(selectedItem);
    }

    onClose();
  }

  // Универсальная функция для отображения текста
  String _getDisplayText(String value) {
    return switch (value) {
      'low' => 'Низкий',
      'medium' => 'Средний',
      'high' => 'Высокий',
      'работа' => 'Работа',
      'личное' => 'Личное',
      'учёба' => 'Учёба',
      'другое' => 'Другое',
      _ => value,
    };
  }

  String _getGroupName() {
    if (_groupId == null) return 'Личная задача';
    final group = _groups.firstWhereOrNull((g) => g.id == _groupId);
    return group?.name ?? 'Группа';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 24), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.task != null ? 'Редактирование' : 'Новая задача'),
        actions: [
          if (widget.task != null) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Удалить задачу?'),
                      content: const Text('Эта задача будет безвозвратно удалена.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Удалить',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await _databaseService.deleteTask(widget.task!.id);
                    if (context.mounted) {
                      Navigator.pop(context, true); // Возвращаем true, чтобы обновить список
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: const [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Удалить задачу',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 16),
              // Название
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Название задачи',
                  hintText: 'Например: поесть, поспать',
                  labelStyle: theme.textTheme.bodyMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                  return 'Введите название';
                  }
                  if (value.trim().length < 2) {
                    return 'Название слишком короткое';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 16),

              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Описание (необязательно)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 24),

              // Дедлайн
              ListTile(
                title: Text(
                  _deadline == null ? 'Выбрать дедлайн' : DateTimeFormat()(_deadline!),
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

              const SizedBox(height: 16),

              // Приоритет
              _buildDropdownField(
                label: 'Приоритет',
                displayText: _getDisplayText(_priority),
                key: _priorityKey,
                isActive: _isPriorityActive,
                onTap: () {
                  if (_isPriorityMenuOpen) {
                    setState(() {
                      _isPriorityActive = false;
                      _isPriorityMenuOpen = false;
                    });
                    return;
                  }

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
                    onClose: () => setState(() {
                      _isPriorityActive = false;
                      _isPriorityMenuOpen = false;
                    }),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Категория
              _buildDropdownField(
                label: 'Категория',
                displayText: _getDisplayText(_category),
                key: _categoryKey,
                isActive: _isCategoryActive,
                onTap: () {
                  if (_isCategoryMenuOpen) {
                    setState(() {
                      _isCategoryActive = false;
                      _isCategoryMenuOpen = false;
                    });
                    return;
                  }

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
                    onClose: () => setState(() {
                      _isCategoryActive = false;
                      _isCategoryMenuOpen = false;
                    }),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Группа
              if (!_isLoadingGroups) ...[
                if (widget.task?.groupId != null && widget.task?.id != null)
                  ...[ // Редактирование существующей групповой задачи — нельзя менять группу
                    Text('Группа', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getGroupName(),
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Группу нельзя изменить',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ]
                else
                  ...[ // Новая задача или редактирование личной — можно выбрать группу
                    Text('Группа', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    GestureDetector(
                      key: _groupKey,
                      onTap: () {
                        if (_isGroupMenuOpen) {
                          setState(() {
                            _isGroupActive = false;
                            _isGroupMenuOpen = false;
                          });
                          return;
                        }

                        setState(() {
                          _isGroupActive = true;
                          _isGroupMenuOpen = true;
                        });

                        _showGroupMenu();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isGroupActive ? const Color(0xFF7e61f3) : Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getGroupName(),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ],

                // Кнопка "Назначить участника" — только если выбрана группа
                if (_groupId != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final group = await _databaseService.readGroupById(_groupId!);
                      final canAssign = _creatorId == group?.creatorId || _creatorId == widget.task?.creatorId;

                      if (!canAssign) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Назначать может только создатель группы или задачи')),
                          );
                        }
                        return;
                      }

                      _showAssignUserDialog();
                    },
                    icon: Icon(
                      _assignedUser != null ? Icons.person : Icons.person_outline,
                      size: 18,
                      color: const Color(0xFF7e61f3),
                    ),
                    label: Text(
                      _assignedUser != null
                          ? 'Назначено: ${_assignedUser!.name}'
                          : 'Назначить участника',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7e61f3),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _assignedUser != null ? const Color(0xFF7e61f3).withOpacity(0.1) : null,
                      side: const BorderSide(color: Color(0xFF7e61f3), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ],
              ] else ...[
                // Загрузка групп
                Text('Группа', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Загрузка групп...'),
                ),
              ],

              const SizedBox(height: 24),

              // Кнопка Сохранить
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final now = DateTime.now();
                    final isEditing = widget.task != null;
                    final task = isEditing
                        ? widget.task!.copyWith(
                            title: _titleController.text.trim(),
                            description: _descriptionController.text,
                            deadline: _deadline,
                            priority: _priority,
                            category: _category,
                            groupId: _groupId,
                            assigned_to: _assignedTo,
                            updatedAt: now,
                          )
                        : Task(
                            id: _databaseService.uuid.v4(),
                            title: _titleController.text.trim(),
                            description: _descriptionController.text,
                            deadline: _deadline,
                            priority: _priority,
                            category: _category,
                            groupId: _groupId,
                            creatorId: _creatorId,
                            assigned_to: _assignedTo,
                            createdAt: now,
                            updatedAt: now,
                            last_sync_at: null,
                          );

                    // Сохраняем в локальную БД
                    if (isEditing) {
                      await _databaseService.updateTask(task);
                    } else {
                      await _databaseService.createTask(task);
                    }

                    await _databaseService.syncTasksToSupabase();

                    // Сброс формы только при создании
                    if (!isEditing) {
                      setState(() {
                        _titleController.text = '';
                        _descriptionController.text = '';
                        _deadline = null;
                        _priority = 'medium';
                        _category = 'other';
                        _groupId = null;
                      });
                      _formKey.currentState?.reset();
                    }

                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                },
                child: Text(widget.task != null ? 'Обновить' : 'Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String displayText,
    required GlobalKey key,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        GestureDetector(
          key: key,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive ? const Color(0xFF7e61f3) : Colors.grey,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(displayText, style: theme.textTheme.bodyMedium),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showGroupMenu() async {
    final items = [
      {'id': null, 'name': 'Личная задача'},
      ..._groups.map((g) => {'id': g.id, 'name': g.name}).toList(),
    ];

    final RenderBox renderBox = _groupKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset localPosition = renderBox.localToGlobal(Offset.zero);
    final Offset menuPosition = Offset(localPosition.dx, localPosition.dy + size.height);

    final selectedId = await showMenu<String?>(
      context: context,
      position: RelativeRect.fromLTRB(
        menuPosition.dx,
        menuPosition.dy,
        menuPosition.dx + size.width,
        menuPosition.dy + (items.length * 48.0),
      ),
      items: items.map((item) {
        final bool isSelected = item['id'] == _groupId;
        return PopupMenuItem<String?>(
          value: item['id'],
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: 48.0,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF7e61f3) : null,
              borderRadius: BorderRadius.zero,
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              item['name'] as String,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
              ),
            ),
          ),
        );
      }).toList(),
      initialValue: _groupId, // <-- важно: чтобы подсветить текущее значение
      color: Colors.white,
    );

    if (selectedId != _groupId) {
      setState(() {
        _groupId = selectedId;
      });
    }

    setState(() {
      _isGroupActive = false;
      _isGroupMenuOpen = false;
    });
  }
}

// Вспомогательный класс для форматирования даты
class DateTimeFormat {
  String call(DateTime dt) {
    final date = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date в $time';
  }
}