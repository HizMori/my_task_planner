import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/group_member.dart';
import '../services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminRightsScreen extends StatefulWidget {
  final GroupMember member;
  final String groupId; // Для контекста

  const AdminRightsScreen({super.key, required this.member, required this.groupId});

  @override
  State<AdminRightsScreen> createState() => _AdminRightsScreenState();
}

class _AdminRightsScreenState extends State<AdminRightsScreen> 
    with TickerProviderStateMixin {
  final DatabaseService _db = DatabaseService.instance;
  late Map<String, bool> _permissions;
  late TextEditingController _titleController;
  bool _isLoading = false;
  late final Map<String, AnimationController> _animControllers;

  @override
  void initState() {
    super.initState();
    _permissions = widget.member.getPermissionsMap();
    // Заполните defaults, если пусто
    _permissions.putIfAbsent('can_edit_group', () => true);
    _permissions.putIfAbsent('can_delete_members', () => true);
    _permissions.putIfAbsent('can_manage_admins', () => false); // Только для creator
    _permissions.putIfAbsent('can_delete_group', () => false); // Только для creator
    _permissions.putIfAbsent('can_manage_tasks', () => true);
    _permissions.putIfAbsent('can_manage_chat', () => true);

    _titleController = TextEditingController(text: widget.member.customTitle ?? '');
    
    // Инициализируем контроллеры анимации
    _animControllers = {
      'can_edit_group': AnimationController(vsync: this, duration: const Duration(milliseconds: 200)),
      'can_delete_members': AnimationController(vsync: this, duration: const Duration(milliseconds: 200)),
      'can_manage_tasks': AnimationController(vsync: this, duration: const Duration(milliseconds: 200)),
      'can_manage_chat': AnimationController(vsync: this, duration: const Duration(milliseconds: 200)),
    };

    // Устанавливаем начальное состояние анимации
    for (var key in _animControllers.keys) {
      _animControllers[key]!.value = _permissions[key]! ? 1.0 : 0.0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.member.role != 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Редактировать права можно только для администраторов')),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _animControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() { _isLoading = true; });
    try {
      final updatedMember = widget.member.copyWith(
        permissions: jsonEncode(_permissions),
        customTitle: _titleController.text.trim(), 
        updatedAt: DateTime.now(),
      );

      print('DEBUG: Saving member with customTitle: ${updatedMember.customTitle}');

      // Обновить в Supabase
      await Supabase.instance.client
        .from('group_members')
        .update({
          'custom_title': updatedMember.customTitle,
          'permissions': updatedMember.permissions,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .match({
        'group_id': widget.groupId,
        'user_id': widget.member.userId,
      });

      // Обновить локально
      await _db.updateGroupMember(updatedMember);

      final trimmedText = _titleController.text.trim();
      final newCustomTitle = trimmedText.isEmpty ? null : trimmedText;
      print('Saving customTitle: "$trimmedText" → becomes $newCustomTitle');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Права обновлены')));
        Navigator.pop(context, true); // Возврат true для обновления списка
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Widget _buildToggle(String title, String key) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final color = const Color(0xFF7e61f3);

    final isDisabled = key == 'can_manage_admins' || key == 'can_delete_group';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16), // Овальные края
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: isDisabled ? Colors.grey : null,
            ),
          ),
          trailing: SwitchTheme(
            data: SwitchThemeData(
              trackOutlineColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return color;
                  }
                  return isDarkMode ? Colors.grey[600] : Colors.grey.withOpacity(0.3);
                },
              ),
              trackOutlineWidth: const MaterialStatePropertyAll(1.0),
            ),
            child: Switch(
              value: _permissions[key] ?? false,
              onChanged: isDisabled
                  ? null
                  : (value) {
                      setState(() {
                        _permissions[key] = value!;
                      });
                    },
              activeColor: color,
              activeTrackColor: isDarkMode ? Colors.grey[800] : Colors.white,
              inactiveTrackColor: isDarkMode ? Colors.grey[700] : Colors.grey.withOpacity(0.2),
              inactiveThumbColor: isDarkMode ? Colors.grey[400] : Colors.grey,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Права администратора',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Поле "Кастомное название роли"
              TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Кастомное название роли',
                labelStyle: theme.textTheme.bodyMedium,
                hintText: 'Например: Модератор',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                prefixIcon: const Icon(Icons.badge, color: Color(0xFF7e61f3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7e61f3), width: 1.5),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
              style: GoogleFonts.poppins(),
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 24),

            // Заголовок "Права доступа"
            Text(
              'Права доступа',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildToggle('Изменять группу', 'can_edit_group'),
                  const SizedBox(height: 8),
                  _buildToggle('Удалять участников', 'can_delete_members'),
                  const SizedBox(height: 8),
                  _buildToggle('Управлять задачами', 'can_manage_tasks'),
                  const SizedBox(height: 8),
                  _buildToggle('Управлять чатом', 'can_manage_chat'),

                  // Отключенные пункты
                  const SizedBox(height: 16),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Управлять администраторами',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Только создатель может назначать и удалять админов',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Удалить группу',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Только создатель может удалить группу',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7e61f3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.1),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))
                : Text(
                    'Сохранить изменения',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}