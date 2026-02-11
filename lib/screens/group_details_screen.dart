import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group.dart';
import 'group_members_screen.dart';
import 'group_chat_screen.dart';
import 'group_tasks_screen.dart';
import '../services/database_service.dart';
import 'create_group_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService.instance;
  bool _isLoading = false;
  String? _currentUserId;
  late Group _group;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _group = widget.group;
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final response = await Supabase.instance.client.auth.getUser();
      if (mounted) {
        setState(() {
          _currentUserId = response.user?.id;
        });
      }
    } catch (e) {
      print('Ошибка получения userId: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _editGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupScreen(group: _group),
      ),
    );

    if (result == true && mounted) {
      // Reload group from DB to update UI
      final updatedGroup = await _db.readGroupById(_group.id);
      if (updatedGroup != null) {
        setState(() {
          _group = updatedGroup;
        });
      }
    }
  }

  Future<void> _deleteGroup() async {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.black;
    
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
                'Удалить группу',
                style: theme.textTheme.headlineSmall?.copyWith(color: textColor),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Все задачи, сообщения и участники этой группы будут безвозвратно удалены.',
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

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final groupId = widget.group.id;

      // Удаляем всё, что связано с группой
      await _db.deleteTasksByGroupId(groupId);     // Задачи
      await _db.deleteMessagesByGroupId(groupId);  // Сообщения
      await _db.deleteAllMembersByGroupId(groupId); // Участники
      await _db.deleteGroupById(groupId);          // Сама группа

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Группа удалена')),
        );
        Navigator.pop(context, true); // Возвращаем true — можно обновить список
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCreator = _currentUserId == _group.creatorId;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 24), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_group.name),
        centerTitle: true,
        actions: [
          // Кнопка "ещё" или "выйти" в зависимости от роли
          if (isCreator)
            // Меню для создателя: Изменить / Удалить
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  _editGroup();
                } else if (value == 'delete') {
                  _deleteGroup();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Изменить группу',
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Удалить группу',
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
              offset: const Offset(-10, 40),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: theme.scaffoldBackgroundColor,
            )
          else
            // Кнопка "Выйти из группы" для участников
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.red),
              tooltip: 'Выйти из группы',
              onPressed: _leaveGroup,
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Участники',
            ),
            Tab(
              icon: Icon(Icons.chat_bubble),
              text: 'Чат',
            ),
            Tab(
              icon: Icon(Icons.checklist),
              text: 'Задачи',
            ),
          ],
          indicatorColor: const Color(0xFF7e61f3),
          labelColor: const Color(0xFF7e61f3),
          unselectedLabelColor: Colors.grey,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.normal),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Вкладка: Участники
          GroupMembersScreen(group: _group),
          // Вкладка: Чат
          GroupChatScreen(groupId: _group.id),
          // Вкладка: Задачи
          GroupTasksScreen(group: _group),
        ],
      ),
    );
  }

  Future<void> _leaveGroup() async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из группы?'),
        backgroundColor: theme.scaffoldBackgroundColor,
        content: const Text(
          'Вы действительно хотите выйти из этой группы? Вы больше не будете видеть её задачи и чат.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Выйти',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final groupId = _group.id;
      final userId = _currentUserId!;
      final creatorId = _group.creatorId;

      // Выполняем логику передачи задач и удаления назначений
      await _db.transferUserTasksAndRemoveAssignments(
        groupId: groupId,
        userId: userId,
        newCreatorId: creatorId,
      );

      // 1. Удаляем из Supabase
      await Supabase.instance.client
          .from('group_members')
          .delete()
          .match({'group_id': groupId, 'user_id': userId});

      // 2. Удаляем из локальной БД
      await _db.deleteGroupMemberLocally(groupId, userId);

      // 3. Уведомление
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вы вышли из группы')),
        );
        Navigator.pop(context, true); // Возвращаем true — можно обновить список групп
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выходе: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}