import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../services/contacts_repository.dart';
import 'search_contacts_screen.dart';
import '../widgets/user_avatar.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactsRepository _contactsRepo = ContactsRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  List<User> _contacts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });
    final contacts = await _contactsRepo.getAllContacts();
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _searchContacts(String query) async {
    if (query.isEmpty) {
      _loadContacts();
      return;
    }
    final results = await _contactsRepo.searchContacts(query);
    setState(() {
      _contacts = results;
    });
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
        title: const Text('Контакты')
        ),
      body: Stack(
        children: [
          // Основной контент: поиск и список
          Column(
            children: [
              // Поиск
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

              const SizedBox(height: 8),

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
                                key: Key(user.id),
                                direction: DismissDirection.startToEnd,
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
                                  await _contactsRepo.removeContact(user.id);
                                  setState(() {
                                    _contacts.removeAt(index);
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${user.name} удалён из контактов'),
                                      action: SnackBarAction(
                                        label: 'Отменить',
                                        onPressed: () async {
                                          await _contactsRepo.addContact(user);
                                          setState(() {
                                            _contacts.insert(index, user);
                                          });
                                        },
                                      ),
                                      duration: const Duration(seconds: 3),
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
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
                                    leading: UserAvatar(user: user, radius: 20),
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

          // Кнопка "Добавить контакт" — внизу
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchContactsScreen(),
                  ),
                ).then((_) {
                  _searchContacts(_searchController.text);
                });
              },
              icon: const Icon(Icons.person_add, size: 20, color: Colors.white),
              label: const Text(
                'Добавить контакт',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7e61f3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 0),
                elevation: 6,
                shadowColor: const Color(0xFF7e61f3).withOpacity(0.3),
              ),
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