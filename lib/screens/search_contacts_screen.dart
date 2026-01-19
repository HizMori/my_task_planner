import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../services/database_service.dart';
import '../widgets/user_avatar.dart';

class UserListTile extends StatelessWidget {
  final User user;
  final Widget? trailing;

  const UserListTile({
    super.key,
    required this.user,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(user: user, radius: 20),
      title: Text(user.name),
      subtitle: Text(user.email ?? 'Нет email'),
      trailing: trailing,
    );
  }
}

class SearchContactsScreen extends StatefulWidget {
  const SearchContactsScreen({super.key});

  @override
  State<SearchContactsScreen> createState() => _SearchContactsScreenState();
}

class _SearchContactsScreenState extends State<SearchContactsScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Можно сразу показать популярных пользователей или оставить пустым
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _db.searchGlobalUsers(query);
      // Исключим уже добавленных
      final localUsers = await _db.readAllUsers();
      final localIds = localUsers.map((u) => u.id).toSet();
      final filtered = results.where((user) => !localIds.contains(user.id)).toList();

      setState(() {
        _searchResults = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка поиска: $e')),
      );
    }
  }

  Future<void> _addContact(User user) async {
    try {
      await _db.createUser(user);
      // Удаляем из результатов, чтобы нельзя было добавить дважды
      setState(() {
        _searchResults.removeWhere((u) => u.id == user.id);
      });
      // Показываем уведомление
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} добавлен в контакты'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось добавить: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск контактов'), // Добавлен заголовок
      ),
      body: Column(
        children: [
          // Поле поиска — теперь как в ContactsScreen
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск среди контактов',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
              ),
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _searchUsers,
              onChanged: (query) {
                // Убираем пробелы
                final trimmed = query.trim();
                _searchUsers(trimmed);
              },
            ),
          ),
          // Результаты поиска
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchController.text.isEmpty
                    ? const Center(
                        child: Text(
                          'Введите имя для поиска',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              'Ничего не найдено',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return UserListTile(
                                user: user,
                                trailing: IconButton(
                                  icon: const Icon(Icons.person_add, color: Colors.green),
                                  onPressed: () => _addContact(user),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}