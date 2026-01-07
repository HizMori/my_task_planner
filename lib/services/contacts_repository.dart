import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import 'database_service.dart';

class ContactsRepository {
  // ✅ Singleton
  ContactsRepository._();

  static final instance = ContactsRepository._();

  final DatabaseService _db = DatabaseService.instance;

  // ✅ Кэширование
  List<User> _cachedContacts = [];
  DateTime? _lastUpdated;
  final Duration _cacheDuration = const Duration(minutes: 5); // Кэш живёт 5 минут

  bool get _isCacheValid {
    if (_lastUpdated == null) return false;
    return DateTime.now().difference(_lastUpdated!) < _cacheDuration;
  }

  Future<List<User>> getAllContacts() async {
    if (_isCacheValid) {
      return _cachedContacts; // ✅ Берём из кэша
    }

    // ❌ Кэш устарел — обновляем
    final contacts = await _db.readAllContactsExceptMe();
    _cachedContacts = contacts;
    _lastUpdated = DateTime.now();
    return contacts;
  }

  Future<List<User>> searchContacts(String query) async {
    if (query.trim().isEmpty) {
      return await getAllContacts();
    }
    return await _db.searchLocalContacts(query, excludeMe: true);
  }

  Future<void> addContact(User user) async {
    await _db.createUser(user);
    _lastUpdated = null;
  }

  Future<void> removeContact(String userId) async {
    await _db.deleteUser(userId);
    _lastUpdated = null;
  }

  Future<bool> isContact(String userId) async {
    final user = await _db.readUserById(userId);
    if (user == null) return false;

    try {
      final response = await Supabase.instance.client.auth.getUser();
      final myId = response.user?.id;
      return myId != null && user.id != myId;
    } catch (e) {
      return true;
    }
  }
}