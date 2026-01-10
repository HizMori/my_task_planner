import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/message.dart';
import '../models/app_settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:uuid/uuid.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('planner.db');
    return _database!;
  }

  // Инициализация БД (создаёт новую БД)
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,  // Увеличили версию для миграции (добавили supabase_user_id)
      onCreate: _createDB,
      // onUpgrade: _upgradeDB,
    );
  }

  Future<List<User>> searchLocalContacts(String query, {bool excludeMe = false}) async {
    final db = await database;
    String? myId;
    if (excludeMe) {
      try {
        final response = await Supabase.instance.client.auth.getUser();
        myId = response.user?.id;
      } catch (e) {
        // Ошибка при получении пользователя — не исключаем никого
        myId = null;
      }
    }

    var whereClause = 'name LIKE ?';
    var whereArgs = ['%$query%'];

    if (excludeMe && myId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(myId);
    }

    final result = await db.query('users', where: whereClause, whereArgs: whereArgs);
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<List<User>> searchGlobalUsers(String query) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('users')
          .select('id, name, email, telephone, avatar_url, created_at, updated_at, last_sync_at')
          .ilike('name', '%$query%')
          .limit(10);

      return response.map((map) => User.fromMap(map)).toList();
    } catch (e) {
      print('Ошибка поиска пользователя: $e');
      return [];
    }
  }

  // Миграция БД (для добавления новых полей)
  /*
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Добавляем supabase_user_id в users
      await db.execute('ALTER TABLE users ADD COLUMN supabase_user_id TEXT;');
    }
  }
  */

  // Создание таблиц (выполняется при первой установке или после удаления)
  Future _createDB(Database db, int version) async {
    // Таблица задач (расширенная)
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY ,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        deadline TEXT, 
        priority TEXT NOT NULL,
        category TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        assigned_to TEXT,
        group_id TEXT,
        creator_id TEXT,
        created_at TEXT,
        updated_at TEXT,
        last_sync_at TEXT
      )
    ''');

    // Таблица пользователей/контактов
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        telephone TEXT,
        avatar_url TEXT,
        created_at TEXT,
        updated_at TEXT,
        last_sync_at TEXT
      )
    ''');

    // Таблица групп
    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        creator_id TEXT,
        created_at TEXT,
        updated_at TEXT,
        last_sync_at TEXT
      )
    ''');

    // Участники групп
    await db.execute('''
      CREATE TABLE group_members (
        group_id TEXT,
        user_id TEXT,
        joined_at TEXT,
        updated_at TEXT,
        last_sync_at TEXT,
        PRIMARY KEY (group_id, user_id)
      )
    ''');

    // Сообщения чата
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        group_id TEXT,
        sender_id TEXT,
        content TEXT NOT NULL,
        sent_at TEXT
      )
    ''');

    // Настройки приложения
    await db.execute('''
      CREATE TABLE app_settings (
        user_id TEXT PRIMARY KEY,
        theme TEXT DEFAULT 'system',
        notifications_enabled INTEGER DEFAULT 1,
        reminder_time INTEGER DEFAULT 15,
        created_at TEXT,
        updated_at TEXT,
        last_sync_at TEXT
      )
    ''');
  }

  // Метод для удаления БД (стирает все данные при каждом запуске, для тестов)
  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'planner.db');
    await deleteDatabase(path);
  }

  // Новый метод: Синхронизация пользователя из Supabase в локальную БД
  Future<void> syncUserFromSupabase(Map<String, dynamic> supabaseUserData) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'id': supabaseUserData['id'],
        'name': supabaseUserData['name'],
        'email': supabaseUserData['email'],
        'telephone': supabaseUserData['telephone'],
        'avatar_url': supabaseUserData['avatar_url'],
        'created_at': supabaseUserData['created_at'],
        'updated_at': supabaseUserData['updated_at'],
        'last_sync_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,  // Обновляет, если существует
    );
  }

  final _uuid = Uuid();
  Uuid get uuid => _uuid;

  // CRUD для задач
  Future<Task> createTask(Task task) async {
    final db = await database;
    final id = task.id ?? _uuid.v4(); // Если id нет — генерируем
    await db.insert('tasks', task.copyWith(id: id).toMap());
    return task.copyWith(id: id);
  }

  Future<List<Task>> readAllTasks() async {
    final db = await database;
    final result = await db.query('tasks');
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String? id) async {
    if (id == null) return 0; // Если id нет — нечего удалять
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD для пользователей
  Future<User> createUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap());
    return user;
  }

  Future<User?> readUserById(String id) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<User?> readUserBySupabaseId(String supabaseId) async {  // Новый метод для поиска по supabase_user_id
    final db = await database;
    final result = await db.query('users', where: 'supabase_user_id = ?', whereArgs: [supabaseId]);
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<List<User>> readAllUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<List<User>> readAllContactsExceptMe() async {
    try {
      final response = await Supabase.instance.client.auth.getUser();
      final myId = response.user?.id;
      final users = await readAllUsers();
      if (myId == null) return users;
      return users.where((user) => user.id != myId).toList();
    } catch (e) {
      // Если ошибка (например, нет сессии) — возвращаем всех
      final users = await readAllUsers();
      return users;
    }
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(String id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD для групп
  Future<Group> createGroup(Group group) async {
    final db = await database;
    await db.insert('groups', group.toMap());
    return group;
  }

  Future<List<Group>> readAllGroups() async {
    final db = await database;
    final result = await db.query('groups');
    return result.map((map) => Group.fromMap(map)).toList();
  }

  Future<int> updateGroup(Group group) async {
    final db = await database;
    return await db.update(
      'groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteGroup(int id) async {
    final db = await database;
    return await db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD для участников групп
  Future<GroupMember> createGroupMember(GroupMember member) async {
    final db = await database;
    await db.insert('group_members', member.toMap());
    return member;
  }

  Future<List<GroupMember>> readGroupMembers(int groupId) async {
    final db = await database;
    final result = await db.query('group_members', where: 'group_id = ?', whereArgs: [groupId]);
    return result.map((map) => GroupMember.fromMap(map)).toList();
  }

  Future<int> deleteGroupMember(int groupId, int userId) async {
    final db = await database;
    return await db.delete('group_members', where: 'group_id = ? AND user_id = ?', whereArgs: [groupId, userId]);
  }

  // CRUD для сообщений
  Future<Message> createMessage(Message message) async {
    final db = await database;
    await db.insert('messages', message.toMap());
    return message;
  }

  Future<List<Message>> readMessagesForGroup(int groupId) async {
    final db = await database;
    final result = await db.query('messages', where: 'group_id = ?', whereArgs: [groupId]);
    return result.map((map) => Message.fromMap(map)).toList();
  }

  Future<int> updateMessage(Message message) async {
    final db = await database;
    return await db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<int> deleteMessage(int id) async {
    final db = await database;
    return await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD для настроек
  Future<AppSettings> createAppSettings(AppSettings settings) async {
    final db = await database;
    await db.insert('app_settings', settings.toMap());
    return settings;
  }

  Future<AppSettings?> readAppSettings(int userId) async {
    final db = await database;
    final result = await db.query('app_settings', where: 'user_id = ?', whereArgs: [userId]);
    if (result.isEmpty) return null;
    return AppSettings.fromMap(result.first);
  }

  Future<int> updateAppSettings(AppSettings settings) async {
    final db = await database;
    return await db.update(
      'app_settings',
      settings.toMap(),
      where: 'user_id = ?',
      whereArgs: [settings.userId],
    );
  }

  Future<int> deleteAppSettings(int userId) async {
    final db = await database;
    return await db.delete('app_settings', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future close() async {
    final db = await database;
    await db.close();
  }
}