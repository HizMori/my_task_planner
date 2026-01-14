import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class UserListTile extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;

  const UserListTile({
    super.key,
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatarUrl != null
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Text(user.name[0].toUpperCase())
            : null,
      ),
      title: Text(user.name),
      subtitle: Text(user.email ?? 'Нет email'),
      onTap: onTap,
    );
  }
}

class SearchUsersScreen extends StatefulWidget {
  final Set<String> alreadyAddedIds;
  const SearchUsersScreen({super.key, required this.alreadyAddedIds});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

      // Получаем ID текущего пользователя
      final myId = await _getCurrentUserId();

      // Фильтруем: исключаем:
      // - себя
      // - уже добавленных
      final filtered = results.where((user) {
        return user.id != myId && !widget.alreadyAddedIds.contains(user.id);
      }).toList();

      setState(() {
        _searchResults = filtered;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка поиска: $e')),
      );
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      final response = await Supabase.instance.client.auth.getUser();
      return response.user?.id;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить участника'),
      ),
      body: Column(
        children: [
          // Поисковая строка
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск пользователей',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _searchUsers,
              onChanged: (query) => _searchUsers(query.trim()),
            ),
          ),

          // Результаты
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
                                onTap: () {
                                  Navigator.pop(context, user);
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}