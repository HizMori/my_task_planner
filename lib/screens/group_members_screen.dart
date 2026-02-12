import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'search_users_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/group_member.dart';
import '../widgets/user_avatar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_rights_screen.dart';
import 'dart:convert';

class GroupMembersScreen extends StatefulWidget {
  final Group group;

  const GroupMembersScreen({super.key, required this.group});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen>
    with TickerProviderStateMixin {
  final DatabaseService _db = DatabaseService.instance;
  List<GroupMember> _members = [];
  Map<String, String> _userNames = {};
  String? _currentUserId;
  bool _isLoading = true;
  final Map<String, GlobalKey> _memberKeys = {};

  // ID группы
  late final String _groupId;
  AnimationController? _menuAnimationController;
  OverlayEntry? _memberMenuEntry; // Для меню

  @override
  void initState() {
    super.initState();
    // Получаем из GroupDetailsScreen через widget.group
    _groupId = widget.group.id;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Получаем ID текущего пользователя
      final response = await Supabase.instance.client.auth.getUser();
      _currentUserId = response.user?.id;

      if (_currentUserId == null) {
        throw Exception("Пользователь не авторизован");
      }

      final uid = _currentUserId;
      if (uid == null) return;

      // Проверяем, состоит ли пользователь в этой группе
      final membershipCheck = await Supabase.instance.client
          .from('group_members')
          .select('group_id')
          .eq('group_id', _groupId)
          .eq('user_id', uid)
          .limit(1);

      if ((membershipCheck as List).isEmpty) {
        throw Exception("Вы не состоите в этой группе");
      }

      // Загружаем участников из Supabase
      final membersData = await Supabase.instance.client
          .from('group_members')
          .select('*, users!inner(name)')
          .eq('group_id', _groupId);

      print('Members data: $membersData');

      _members = [];
      _userNames = {};
      for (var map in (membersData as List)) {
        final member = GroupMember.fromMap(map); // fromMap берёт flat поля
        _members.add(member);
        final name =
            map['users']?['name'] as String? ?? 'Unknown'; // Извлекаем имя
        _userNames[member.userId] = name;

        print('📌 Supabase returned custom_title: ${map['custom_title']} (type: ${map['custom_title']?.runtimeType})');
      }

      setState(() {
        _isLoading = false;
      });
      _memberKeys.clear();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки участников: $e')));
    }
  }

  Future<void> _addMember() async {
    final Set<String> alreadyAddedIds = _members
        .map((member) => member.userId)
        .toSet();

    final selectedUser = await Navigator.push<User?>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SearchUsersScreen(alreadyAddedIds: alreadyAddedIds),
      ),
    );

    if (selectedUser == null) return;

    if (_members.any((m) => m.userId == selectedUser.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Этот пользователь уже в группе')),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final newMember = GroupMember(
        groupId: _groupId,
        userId: selectedUser.id,
        role: 'member',
        permissions: null,
        customTitle: null,
        joinedAt: now,
        updatedAt: now,
        lastSyncAt: now,
      );

      // Добавляем в Supabase
      await Supabase.instance.client
          .from('group_members')
          .insert(newMember.toMap());

      // Добавляем в локальную БД
      await _db.insertGroupMember(newMember); // ← новый метод

      // Обновляем UI
      await _loadData(); // ← обновляем данные после добавления

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedUser.name} добавлен(а) в группу')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось добавить: $e')));
    }
  }

  Future<void> _removeMember(GroupMember member) async {
    final currentMember = _members.firstWhere(
      (m) => m.userId == _currentUserId,
      orElse: () => GroupMember(
        groupId: '',
        userId: '',
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    if (member.userId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя удалить себя из группы')),
      );
      return;
    }
    if (member.isCreator) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя удалить создателя группы')),
      );
      return;
    }
    if (member.isAdmin && !currentMember.canManageAdmins()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Администратор не может удалять других администраторов',
          ),
        ),
      );
      return;
    }

    // Проверка права can_delete_members (если админ)
    if (currentMember.role == 'admin') {
      final perms = currentMember.getPermissionsMap();
      if (!(perms['can_delete_members'] ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('У вас нет права удалять участников')),
        );
        return;
      }
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.black;

    final name = _userNames[member.userId] ?? 'Unknown';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Text(
                'Удалить участника',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: textColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Вы точно хотите удалить ${name} из группы?',
                style: theme.textTheme.bodyMedium?.copyWith(color: hintColor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Нет, оставить',
                style: GoogleFonts.poppins(color: theme.primaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Да, удалить',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.from('group_members').delete().match({
        'group_id': _groupId,
        'user_id': member.userId,
      });

      await _db.deleteGroupMemberLocally(_groupId, member.userId);

      setState(() {
        _members.remove(member);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${name} удалён(а) из группы',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
    }
  }

  void _showMemberMenu(GroupMember member, GlobalKey tileKey) {
    if (_memberMenuEntry != null) return;
    
    final currentMember = _members.firstWhere(
      (m) => m.userId == _currentUserId,
      orElse: () => GroupMember(
        groupId: '',
        userId: '',
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    if (!currentMember.isCreator && !currentMember.isAdmin) return; // Только админы/creator могут показывать меню
    if (member.isCreator && !currentMember.isCreator) return; // Админ не может трогать creator

    final isAdmin = member.role == 'admin';
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Получаем RenderBox через GlobalKey
    final RenderBox? renderBox = tileKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset tilePosition = renderBox.localToGlobal(Offset.zero);
    final Size tileSize = renderBox.size;

    final OverlayState? overlay = Overlay.of(context);
    if (overlay == null) return;

    final Size screenSize = MediaQuery.of(context).size;
    final EdgeInsets safePadding = MediaQuery.of(context).padding;

    // Максимальная ширина меню
    final double maxMenuWidth = screenSize.width * 0.4;
    final double menuHeight = (isAdmin && currentMember.isCreator ? 180 : 60) +
        (!isAdmin && currentMember.isCreator ? 60 : 0);

    // Оффсеты для точного позиционирования
    const double horizontalOffset = -40; // ← слева от карточки
    const double verticalOffset = -10;

    // Расчёт позиции X: слева от карточки
    double preferredLeft = tilePosition.dx + horizontalOffset;
    const double edgeMargin = 8.0;

    // Если слишком близко к левому краю — привязываемся справа
    if (preferredLeft < safePadding.left + edgeMargin) {
      preferredLeft = tilePosition.dx + tileSize.width + 10;
    }

    // проверяем, не выходит ли меню за правый край
    final double menuRightEdge = preferredLeft + maxMenuWidth;
    final double screenRightEdge = screenSize.width - safePadding.right - edgeMargin;

    if (menuRightEdge > screenRightEdge) {
      // Сдвигаем влево так, чтобы правый край меню был у правого края экрана
      preferredLeft -= (menuRightEdge - screenRightEdge);

      // На всякий случай — не позволяем уйти за левый край
      if (preferredLeft < safePadding.left + edgeMargin) {
        // Привязываем к левому краю, обрезаем меню
        preferredLeft = safePadding.left + edgeMargin;
      }
    }

    // Вертикальный сдвиг (Y): хотим, чтобы меню было ЧАСТИЧНО НА КАРТОЧКЕ
    const double overlapY = 8.0; // ← сколько пикселей меню будет "заходить" на карточку
    double preferredTop = tilePosition.dy + tileSize.height - overlapY + verticalOffset;

    // Если места нет снизу — показываем сверху, тоже с перекрытием
    if (preferredTop + menuHeight > screenSize.height - safePadding.bottom) {
      preferredTop = tilePosition.dy - menuHeight + overlapY; // сверху, с заходом
      if (preferredTop < safePadding.top) {
        preferredTop = safePadding.top;
      }
    }

    // Если места нет снизу — показываем сверху
    if (preferredTop + menuHeight > screenSize.height - safePadding.bottom) {
      preferredTop = tilePosition.dy - menuHeight - 10;
      if (preferredTop < safePadding.top) {
        preferredTop = safePadding.top; // Привязка к верху
      }
    }

    // Анимация
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    final scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _menuAnimationController!, curve: Curves.easeOutBack),
    );
    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _menuAnimationController!, curve: Curves.easeOut),
    );

    _memberMenuEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideMemberMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          AnimatedBuilder(
            animation: _menuAnimationController!,
            builder: (context, child) => Positioned(
              left: preferredLeft,
              top: preferredTop,
              child: ScaleTransition(
                scale: scale,
                child: FadeTransition(
                  opacity: opacity,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxMenuWidth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.delete,
                              size: 18,
                              color: isDarkMode ? Colors.red[300] : Colors.red,
                            ),
                            title: Text(
                              "Удалить",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            onTap: () {
                              _hideMemberMenu();
                              _removeMember(member);
                            },
                          ),
                          if (!isAdmin && currentMember.isCreator)
                            ListTile(
                              leading: Icon(
                                Icons.admin_panel_settings,
                                size: 18,
                                color: isDarkMode ? Colors.green[300] : Colors.green,
                              ),
                              title: Text(
                                "Сделать администратором",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              onTap: () {
                                _hideMemberMenu();
                                _promoteToAdmin(member);
                              },
                            ),
                          if (isAdmin && currentMember.isCreator)
                            ListTile(
                              leading: Icon(
                                Icons.edit,
                                size: 18,
                                color: isDarkMode ? Colors.blue[300] : Colors.blue,
                              ),
                              title: Text(
                                "Изменить права",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              onTap: () {
                                _hideMemberMenu();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminRightsScreen(
                                      member: member,
                                      groupId: _groupId,
                                    ),
                                  ),
                                ).then((result) {
                                  if (result == true) _loadData();
                                });
                              },
                            ),
                          if (isAdmin && currentMember.isCreator)
                            ListTile(
                              leading: Icon(
                                Icons.arrow_downward,
                                size: 18,
                                color: isDarkMode ? Colors.orange[300] : Colors.orange,
                              ),
                              title: Text(
                                "Разжаловать",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              onTap: () {
                                _hideMemberMenu();
                                _demoteAdmin(member);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_memberMenuEntry!);
    _menuAnimationController!.forward();
  }

  void _hideMemberMenu() {
    _menuAnimationController?.reverse().then((_) {
      _memberMenuEntry?.remove();
      _memberMenuEntry = null;
     _menuAnimationController?.dispose();
      _menuAnimationController = null;
    });
  }

  Future<void> _promoteToAdmin(GroupMember member) async {
    final currentMember = _members.firstWhere(
      (m) => m.userId == _currentUserId,
      orElse: () => GroupMember(
        groupId: '',
        userId: '',
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    if (!currentMember.canManageAdmins()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Только создатель может назначать админов'),
        ),
      );
      return;
    }

    final updated = member.copyWith(
      role: 'admin',
      permissions: jsonEncode({
        'can_edit_group': true,
        'can_delete_members': true,
        'can_manage_tasks': true,
        'can_manage_chat': true,
      }),
      customTitle: null, // По умолчанию пусто
      updatedAt: DateTime.now(),
    );

    try {
      await Supabase.instance.client
          .from('group_members')
          .update(updated.toMap())
          .match({'group_id': _groupId, 'user_id': member.userId});
      await _db.updateGroupMember(updated);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь назначен администратором')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _demoteAdmin(GroupMember member) async {
    final currentMember = _members.firstWhere(
      (m) => m.userId == _currentUserId,
      orElse: () => GroupMember(
        groupId: '',
        userId: '',
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    if (!currentMember.canManageAdmins()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Только создатель может разжаловать админов'),
        ),
      );
      return;
    }

    final updated = member.copyWith(
      role: 'member',
      permissions: jsonEncode({}),
      customTitle: null,
      updatedAt: DateTime.now(),
    );

    print('Demoting: ${member.userId}, permissions in map: ${updated.toMap()['permissions']}');

    try {
      final response = await Supabase.instance.client
        .from('group_members')
        .update(updated.toMap())
        .match({'group_id': _groupId, 'user_id': member.userId});
      
      print('Supabase response: $response');

      await _db.updateGroupMember(updated);
      await _loadData();

      print('✅ Supabase: update successful');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Пользователь разжалован')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      print('❌ Supabase error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

      final currentMember = _members.firstWhere(
        (m) => m.userId == _currentUserId,
        orElse: () => GroupMember(
          groupId: '',
          userId: '',
          joinedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Основной контент: список участников
          Column(
            children: [
              // Заголовок
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text('Участники', style: theme.textTheme.headlineSmall),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7e61f3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_members.length}',
                        style: const TextStyle(
                          color: Color(0xFF7e61f3),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Список участников
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _members.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_alt_outlined,
                              size: 60,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Нет участников',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final isCreator = member.isCreator;
                          final isAdmin = member.isAdmin;
                          final isMe = member.isMember;
                          final name = _userNames[member.userId] ?? 'Unknown';
                          final isDarkMode =
                              theme.brightness == Brightness.dark;
                          final cardColor = isDarkMode
                              ? Colors.grey[800]
                              : Colors.white;
                          
                          final key = GlobalKey();

                          return GestureDetector(
                            onLongPress: (currentMember.isCreator || currentMember.isAdmin)
                                ? () => _showMemberMenu(member, key)
                                : null,
                            child: Card(
                              color: cardColor,
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: isDarkMode ? 2 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                              ),
                              child: ListTile(
                                key: key,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                leading: UserAvatar(
                                  user: User(
                                    id: member.userId,
                                    name: name,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  ),
                                  radius: 20,
                                ),
                                title: Text(
                                 name,
                                  style: isCreator
                                      ? theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        )
                                      : null,
                                ),
                                subtitle: Wrap(
                                  spacing: 8,
                                  children: [
                                    if (isCreator)
                                      _buildLabel(
                                        'Создатель',
                                        const Color(0xFF7e61f3),
                                      ),
                                    if (isAdmin)
                                      _buildLabel(
                                        member.customTitle ?? 'Администратор',
                                        Colors.green,
                                      ),
                                  ],
                                ),
                                trailing: null,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // Кнопка "Добавить участника" — внизу экрана
          if (!_isLoading && _members.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: _addMember,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Добавить участника'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF7e61f3).withOpacity(0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8),
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

  @override
  void dispose() {
    _menuAnimationController?.dispose();
    super.dispose();
  }
}
