import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../services/database_service.dart';
import 'search_contacts_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<User> _contacts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllContacts();
  }

  Future<void> _loadAllContacts() async {
    setState(() {
      _isLoading = true;
    });
    final allContacts = await _db.readAllUsers();
    setState(() {
      _contacts = allContacts;
      _isLoading = false;
    });
  }

  Future<void> _searchContacts(String query) async {
    if (query.isEmpty) {
      _loadAllContacts();
      return;
    }
    final results = await _db.searchLocalContacts(query);
    setState(() {
      _contacts = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Контакты'),
      ),
      body: Column(
        children: [
          // Поиск среди контактов
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
              ),
              onChanged: _searchContacts,
            ),
          ),
          // Кнопка "Добавить контакт"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchContactsScreen(),
                  ),
                ).then((_) {
                  // После возврата — обновим список контактов
                  _searchContacts(_searchController.text);
                });
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Добавить контакт'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Список контактов
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                    ? const Center(child: Text('Нет контактов'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final user = _contacts[index];
                          return Dismissible(
                            key: Key(user.id), // Ключ по id — обязателен
                            direction: DismissDirection.startToEnd, // Свайп влево (с права налево)
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) async {
                              // Удаляем из локальной БД
                              await _db.deleteUser(user.id);

                              // Удаляем из списка
                              setState(() {
                                _contacts.removeAt(index);
                              });

                              // Показываем SnackBar с возможностью отмены
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${user.name} удалён из контактов'),
                                  action: SnackBarAction(
                                    label: 'Отменить',
                                    onPressed: () async {
                                      // При отмене — снова добавляем
                                      await _db.createUser(user);
                                      setState(() {
                                        _contacts.insert(index, user);
                                      });
                                    },
                                  ),
                                  duration: const Duration(seconds: 3),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
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
                              ),
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
