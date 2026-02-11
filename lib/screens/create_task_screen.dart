import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../models/group.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import 'package:collection/collection.dart';
import '../widgets/user_avatar.dart';
import '../models/task_assignee.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateTaskScreen extends StatefulWidget {
  // Добавляем возможность передать группу по умолчанию
  final String? initialGroupId;
  final Task? task;

  const CreateTaskScreen({super.key, this.initialGroupId, this.task});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

enum _TaskViewMode { create, edit, view }

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _deadline;
  String _priority = 'medium';
  String _category = 'работа';
  String? _groupId; // null — значит личная задача
  late String _creatorId; // реальный ID
  List<String> _selectedUserIds = []; // ID назначенных
  List<User> _selectedUsers = []; // Назначенные пользователи

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
        _determineViewMode();
        if (widget.task != null) {
          _loadTaskData();
        }
      });
    });
  }

  _TaskViewMode _viewMode = _TaskViewMode.create;

  void _determineViewMode() {
    if (widget.task == null) {
      _viewMode = _TaskViewMode.create;
      return;
    }

    final task = widget.task!;
    final isTaskCreator = _creatorId == task.creatorId;
    final isGroupCreator = _groups.any((g) => g.id == task.groupId && g.creatorId == _creatorId);

    if (isTaskCreator || isGroupCreator) {
      _viewMode = _TaskViewMode.edit;
    } else {
      _viewMode = _TaskViewMode.view;
    }

    if (mounted) {
      setState(() {}); // Обновим интерфейс
    }
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
      });
    }

    // Загрузка назначенных пользователей
    if (task.id != null) {
      final assignees = await _databaseService.readTaskAssignees(task.id!);
      final userIds = assignees.map((a) => a.userId).toList();
      final users = await _databaseService.readAllUsers();
      final selectedUsers = users.where((u) => userIds.contains(u.id)).toList();

      if (mounted) {
        setState(() {
          _selectedUserIds = userIds;
          _selectedUsers = selectedUsers;
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
    Set<String> selectedUserIds = _selectedUserIds.toSet(); // Текущий выбор в диалоге

    final result = await showDialog<Set<String>>(
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
                                final isSelected = selectedUserIds.contains(user.id);
                                return ListTile(
                                  leading: UserAvatar(user: user, radius: 20),
                                  title: Text(user.name),
                                  subtitle: Text(user.email ?? 'Нет email'),
                                  trailing: isSelected
                                      ? const Icon(Icons.check, color: Colors.green)
                                      : null,
                                  onTap: () {
                                    setStateDialog(() {
                                      if (isSelected) {
                                        selectedUserIds.remove(user.id);
                                      } else {
                                        selectedUserIds.add(user.id);
                                      }
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
                  onPressed: () => Navigator.pop(context, selectedUserIds), // ← Только если нажали "Назначить"
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
    if (result == null) return;

    if (result != null && mounted) {
      final users = await _databaseService.readAllUsers();
      final selectedUsers = users.where((u) => result.contains(u.id)).toList();

      setState(() {
        _selectedUserIds = result.toList();
        _selectedUsers = selectedUsers;
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
              color: isSelected 
                  ? theme.primaryColor
                  : (isDarkMode ? Colors.grey[800] : Colors.white),
              borderRadius: BorderRadius.zero,
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              _getDisplayText(item),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
          ),
        );
      }).toList(),
      initialValue: selectedValue,
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isDarkMode 
            ? BorderSide(color: Colors.grey[700]!)
            : BorderSide(color: Colors.grey[300]!),
      ),
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
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _viewMode == _TaskViewMode.view 
          ? _buildViewModeBody(context, theme) 
          : _buildEditModeBody(context, theme),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.black;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 24),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        _viewMode == _TaskViewMode.create
            ? 'Новая задача'
            : _viewMode == _TaskViewMode.edit
                ? 'Редактирование'
                : 'Просмотр задачи',
      ),
      actions: [
        // Иконка глаза — только в режиме просмотра
        if (_viewMode == _TaskViewMode.view)
          Icon(
            Icons.visibility,
            color: Colors.grey[600],
            size: 20,
          ),
        // Меню "Удалить" — только в режиме редактирования
        if (widget.task != null && _viewMode == _TaskViewMode.edit)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: theme.scaffoldBackgroundColor,
            onSelected: (value) async {
              if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: theme.scaffoldBackgroundColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                          const SizedBox(width: 20),
                          Text(
                            'Удалить задачу',
                            style: theme.textTheme.headlineSmall?.copyWith(color: textColor),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Вы удалите задачу.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: hintColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                              ),
                              child: Text(
                                'Нет, сохранить',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: Text(
                                'Да, удалить',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )
                      ],
                    );
                  },
                );
                if (confirmed == true) {
                  await _databaseService.deleteTask(widget.task!.id);
                  if (context.mounted) {
                    Navigator.pop(context, true);
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
                    Text('Удалить задачу', style: TextStyle(color: Colors.red, fontSize: 14)),
                  ],
                ),
              ),
            ],
            // offset сдвигает меню вниз и влево
            offset: const Offset(-10, 40), // x: -10 (чуть левее), y: 40 (вниз от AppBar)
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
      ],
    );
  }

  Widget _buildViewModeBody(BuildContext context, ThemeData theme) {
    final task = widget.task!;

    return IgnorePointer(
      ignoring: true,
      child: Form(
        child: ListView(
          children: [
            const SizedBox(height: 16),

            // Название
            TextFormField(
              initialValue: task.title,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Название задачи',
                labelStyle: theme.textTheme.bodyMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabled: false,
                disabledBorder: OutlineInputBorder( // сохраняем стиль рамки
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Описание
            TextFormField(
              initialValue: task.description ?? '',
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Описание',
                labelStyle: theme.textTheme.bodyMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabled: false,
                disabledBorder: OutlineInputBorder( // сохраняем стиль рамки
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Дедлайн
            ListTile(
              title: Text(
                task.deadline == null
                    ? 'Нет дедлайна'
                    : DateTimeFormat()(task.deadline!),
                style: (theme.textTheme.bodyMedium?.copyWith(
                  color: task.deadline == null ? Colors.grey : theme.textTheme.bodyMedium?.color,
                )),
              ),
              trailing: const Icon(Icons.calendar_today, color: Colors.grey),
              enabled: false,
            ),

            const SizedBox(height: 16),

            // Приоритет
            _buildDropdownField(
              label: 'Приоритет',
              labelStyle: theme.textTheme.bodyMedium,
              displayText: _getDisplayText(task.priority ?? 'medium'),
              key: _priorityKey,
              isActive: false,
              onTap: () {}, // пустой, чтобы не реагировал
              theme: theme,
            ),

            const SizedBox(height: 16),

            // Категория
            _buildDropdownField(
              label: 'Категория',
              labelStyle: theme.textTheme.bodyMedium,
              displayText: _getDisplayText(task.category ?? 'работа'),
              key: _categoryKey,
              isActive: false,
              onTap: () {},
              theme: theme,
            ),

            const SizedBox(height: 16),

            // Группа
            if (task.groupId != null) ...[
              Text('Группа', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FutureBuilder<Group?>(
                  future: _databaseService.readGroupById(task.groupId!),
                  builder: (context, snapshot) {
                    final groupName = snapshot.hasData && snapshot.data != null
                        ? snapshot.data!.name
                        : 'Загрузка...';
                    return Text(
                      groupName,
                      style: theme.textTheme.bodyMedium,
                    );
                  },
                ),
              ),
            ] else ...[
              Text('Группа', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Личная задача', style: TextStyle(color: Colors.grey)),
              ),
            ],

            const SizedBox(height: 16),

            // Назначенные — как в режиме редактирования
            if (_selectedUsers.isNotEmpty) ...[
              Text('Назначено', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (var user in _selectedUsers)
                    Chip(
                      label: Text(user.name),
                      avatar: UserAvatar(user: user, radius: 12),
                      backgroundColor: const Color(0xFF7e61f3).withOpacity(0.1),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Создатель
            Text('Создатель', style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            FutureBuilder<User?>(
              future: _databaseService.readUserById(task.creatorId),
              builder: (context, snapshot) {
                final creatorName = snapshot.hasData && snapshot.data != null
                    ? snapshot.data!.name
                    : 'Загрузка...';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(creatorName, style: theme.textTheme.bodyMedium),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditModeBody(BuildContext context, ThemeData theme) {
    return IgnorePointer(
      ignoring: _viewMode == _TaskViewMode.view,
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
                theme: theme,
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
                theme: theme,
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
                      // Если режим просмотра — ничего не делаем
                      if (_viewMode == _TaskViewMode.view) {
                        return;
                      }
                      // Только при редактировании — проверяем права
                      if (widget.task != null) {
                        final group = await _databaseService.readGroupById(_groupId!);
                        final canAssign = _creatorId == group?.creatorId || _creatorId == widget.task?.creatorId;

                        if (!canAssign) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Редактировать назначение может только создатель группы или задачи')),
                            );
                          }
                          return;
                        }
                      }

                      // При создании — любой участник может назначить
                      _showAssignUserDialog();
                    },
                    icon: Icon(
                      _selectedUsers.isEmpty ? Icons.person_outline : Icons.person,
                      size: 18,
                      color: _viewMode == _TaskViewMode.view
                          ? Colors.grey
                          : const Color(0xFF7e61f3),
                    ),
                    label: Text(
                       _selectedUsers.isEmpty
                          ? 'Назначить участника'
                          : 'Назначено: ${_selectedUsers.length}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _viewMode == _TaskViewMode.view
                            ? Colors.grey
                            : const Color(0xFF7e61f3),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedUsers.isNotEmpty
                          ? (_viewMode == _TaskViewMode.view
                              ? Colors.grey.withOpacity(0.1)
                              : const Color(0xFF7e61f3).withOpacity(0.1))
                          : null,
                      side: BorderSide(
                        color: _viewMode == _TaskViewMode.view
                            ? Colors.grey
                            : const Color(0xFF7e61f3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                  // Показываем выбранных пользователей
                  if (_selectedUsers.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (var user in _selectedUsers)
                          Chip(
                            label: Text(user.name),
                            avatar: UserAvatar(user: user, radius: 12),
                            backgroundColor: const Color(0xFF7e61f3).withOpacity(0.1),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedUsers.remove(user);
                                _selectedUserIds.remove(user.id);
                              });
                            },
                          ),
                      ],
                    ),
                  ],
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
                onPressed: _viewMode == _TaskViewMode.view ? null : () async {
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

                    // Удаляем старые назначения
                    await _databaseService.deleteAllAssigneesByTaskId(task.id);

                    // Добавляем новые
                    for (final userId in _selectedUserIds) {
                      final assignee = TaskAssignee(
                        taskId: task.id!,
                        userId: userId,
                        assignedAt: now,
                        updatedAt: now,
                        lastSyncAt: null,
                      );
                      await _databaseService.createTaskAssignee(assignee);
                    }

                    // Синхронизация
                    await _databaseService.syncTasksToSupabase();
                    await _databaseService.syncTaskAssigneesToSupabase();
                    // Сброс формы только при создании
                    if (!isEditing) {
                      setState(() {
                        _titleController.text = '';
                        _descriptionController.text = '';
                        _deadline = null;
                        _priority = 'medium';
                        _category = 'other';
                        _groupId = null;
                        _selectedUserIds.clear();
                        _selectedUsers.clear();
                        _formKey.currentState?.reset();
                      });
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
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String displayText,
    required GlobalKey key,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeData theme, 
    TextStyle? labelStyle,
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
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
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isDarkMode 
            ? BorderSide(color: Colors.grey[700]!)
            : BorderSide(color: Colors.grey[300]!),
      ),
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