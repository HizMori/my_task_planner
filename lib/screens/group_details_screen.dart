import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group.dart';
import 'group_members_screen.dart';
import 'group_chat_screen.dart';
import 'group_tasks_screen.dart';
import '../services/database_service.dart';
import 'create_group_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_member.dart';
import '../screens/eisenhower_screen.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
    final currentMember = await _db.readGroupMember(_group.id, _currentUserId!);
    if (currentMember == null || (!currentMember.isCreator && !(currentMember.getPermissionsMap()['can_edit_group'] ?? false))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('У вас нет прав на редактирование группы')));
      return;
    }
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
    
  final currentMember = await _db.readGroupMember(_group.id, _currentUserId!);
  if (currentMember == null || !currentMember.canDeleteGroup()) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('У вас нет прав на удаление группы')));
    return;
  }

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

      await Supabase.instance.client.from('groups').delete().eq('id', groupId);

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

  Future<bool> _canEditGroup() async {
    if (_currentUserId == null) return false;
    if (_currentUserId == _group.creatorId) return true;

    try {
      final member = await _db.readGroupMember(_group.id, _currentUserId!);
      return member?.getPermissionsMap()['can_edit_group'] ?? false;
    } catch (e) {
      return false;
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
          // Определяем, может ли текущий пользователь редактировать группу
          FutureBuilder<bool>(
            future: _canEditGroup(),
            builder: (context, snapshot) {
              final canEdit = snapshot.data ?? false;
              final isCreator = _currentUserId == _group.creatorId;

              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              // Показываем PopupMenuButton, если пользователь — создатель или может редактировать
              if (isCreator || canEdit) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _editGroup();
                    } else if (value == 'delete') {
                      _deleteGroup();
                    } else if (value == 'leave') {
                      await _leaveGroup();
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
                    if (isCreator)
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
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.orange, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'Выйти из группы',
                            style: TextStyle(color: Colors.orange, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                  offset: const Offset(-10, 40),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: theme.scaffoldBackgroundColor,
                );
              }

              // Участник без прав — просто кнопка "Выйти"
              return IconButton(
                icon: const Icon(Icons.exit_to_app, color: Colors.red),
                tooltip: 'Выйти из группы',
                onPressed: _leaveGroup,
              );
            },
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
            Tab(
              icon: Icon(Icons.grid_view), 
              text: 'Приоритеты'
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
          // Вкладка: Приоритеты
          EisenhowerScreen(groupId: _group.id, hideAppBar: true),
        ],
      ),
    );
  }

  Future<String> _fetchUserName(GroupMember member) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', member.userId)
          .single();
      return (response['name'] as String?)?.trim() ?? 'Неизвестно';
    } catch (e) {
      return 'Неизвестно';
    }
  }

  Future<Map<String, String>> _loadAdminNames(List<GroupMember> members) async {
    final Map<String, String> namesMap = {};
    for (final member in members) {
      try {
        final response = await Supabase.instance.client
            .from('users')
            .select('name')
            .eq('id', member.userId)
            .single();
        final name = (response['name'] as String?)?.trim() ?? 'Неизвестно';
        namesMap[member.userId] = member.customTitle ?? name;
      } catch (e) {
        namesMap[member.userId] = member.customTitle ?? 'Неизвестно';
      }
    }
    return namesMap;
  }

  Future<void> _leaveGroup() async {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.black;

    // Проверяем, является ли пользователь создателем
    final bool isCreator = _currentUserId == _group.creatorId;

    if (isCreator) {
      List<GroupMember> members = [];
      try {
        final response = await Supabase.instance.client
            .from('group_members')
            .select('*, users(name)')
            .eq('group_id', _group.id)
            .order('joined_at');

        members = response.map((e) => GroupMember.fromMap(e)).toList();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки участников: $e')),
        );
        return;
      }

      // Фильтруем администраторов (включая custom права)
      final List<GroupMember> adminCandidates = members.where((m) {
        final perms = m.getPermissionsMap();
        final canManageMembers = perms['can_manage_members'] ?? false;
        final canEditGroup = perms['can_edit_group'] ?? false;
        return (m.isAdmin || canManageMembers || canEditGroup) &&
              m.userId != _currentUserId;
      }).toList();

      if (adminCandidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Невозможно выйти: назначьте хотя бы одного администратора'),
          ),
        );
        return; // ❌ Нельзя выйти — некому передать права
      }

      final Map<String, String> adminNames = await _loadAdminNames(adminCandidates);

      // Диалог выбора нового создателя
      final selectedAdmin = await showDialog<String?>(
        context: context,
        builder: (context) {
          String? selectedUserId = adminCandidates.isNotEmpty ? adminCandidates[0].userId : null;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: theme.scaffoldBackgroundColor,
                title: Text(
                  'Передать права создателя',
                  style: TextStyle(color: textColor),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Выберите администратора:',
                        style: TextStyle(color: hintColor),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedUserId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Администратор',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: adminCandidates.map((member) {
                          final displayName = adminNames[member.userId] ?? 'Неизвестно';
                          return DropdownMenuItem(
                            value: member.userId,
                            child: Text(displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedUserId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Выберите администратора';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text('Отмена', style: GoogleFonts.poppins(color: theme.primaryColor)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, selectedUserId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7e61f3),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Далее'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (selectedAdmin == null) return;

      // Подтверждение выхода
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text('Выйти из группы?', style: TextStyle(color: textColor)),
          content: Text(
            'Вы передадите права создателя и покинете группу.',
            style: TextStyle(color: hintColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Отмена', style: GoogleFonts.poppins(color: theme.primaryColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Выйти'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() { _isLoading = true; });

      try {
        // Выполняем передачу прав через DatabaseService
        await _db.transferOwnershipAndLeave(
          groupId: _group.id,
          oldCreatorId: _currentUserId!,
          newCreatorId: selectedAdmin,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Права переданы, вы вышли из группы')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }

    } else {
      // Обычный выход (не создатель)
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Выйти из группы?'),
          backgroundColor: theme.scaffoldBackgroundColor,
          content: const Text(
            'Вы действительно хотите выйти из этой группы?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Выйти', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() { _isLoading = true; });

      try {
        await _db.transferUserTasksAndRemoveAssignments(
          groupId: _group.id,
          userId: _currentUserId!,
          newCreatorId: _group.creatorId,
        );

        await Supabase.instance.client
            .from('group_members')
            .delete()
            .match({'group_id': _group.id, 'user_id': _currentUserId!});

        await _db.deleteGroupMemberLocally(_group.id, _currentUserId!);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Вы вышли из группы')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }
}