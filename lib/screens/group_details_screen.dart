import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group.dart';
import 'group_members_screen.dart';
import 'group_chat_screen.dart';
import 'group_tasks_screen.dart';
import '../services/database_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить группу?'),
        content: const Text(
          'Все задачи, сообщения и участники этой группы будут безвозвратно удалены.',
        ),
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 24), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.group.name),
        centerTitle: true,
        actions: [
          // Кнопка "ещё" с меню
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteGroup();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Удалить группу',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
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
            color: theme.scaffoldBackgroundColor,
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
          GroupMembersScreen(group: widget.group),
          // Вкладка: Чат
          GroupChatScreen(groupId: widget.group.id),
          // Вкладка: Задачи
          GroupTasksScreen(group: widget.group),
        ],
      ),
    );
  }
}