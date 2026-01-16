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
  SupabaseClient get supabase => Supabase.instance.client;

  DatabaseService._init();

  // Скачивание задач из Supabase → локальная БД
  Future<void> syncTasksFromSupabase() async {
    try {
      final supabaseUser = await supabase.auth.getUser();
      final myId = supabaseUser.user?.id;
      if (myId == null) return;

      final lastSync = await _getLastSyncTime('tasks');
      final response = await supabase
          .from('tasks')
          .select()
          .gt('updated_at', lastSync.toIso8601String());

      final db = await database;

      for (var item in response) {
        final task = Task.fromSupabaseMap(item);
        await db.insert(
          'tasks',
          task.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await _setLastSyncTime('tasks', DateTime.now());
    } catch (e) {
      print('Ошибка синхронизации задач: $e');
    }
  }

  Future<void> insertGroupMember(GroupMember member) async {
    final db = await database;
    await db.insert(
      'group_members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteGroupMemberLocally(String groupId, String userId) async {
    final db = await database;
    await db.delete(
      'group_members',
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, userId],
    );
  }

  // Отправка локальных изменений в Supabase
  Future<void> syncTasksToSupabase() async {
    try {
      final db = await database;
      final result = await db.query(
        'tasks',
        where: 'updated_at > last_sync_at OR last_sync_at IS NULL',
      );

      final tasksToSync = result.map((e) => Task.fromMap(e)).toList();

      for (var task in tasksToSync) {
        final taskData = task.toMapSupabase();

        if (task.id == null) continue;

        await supabase.from('tasks').upsert(taskData);
        await db.update(
          'tasks',
          {'last_sync_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [task.id],
        );
      }
    } catch (e) {
      print('Ошибка выгрузки задач в Supabase: $e');
    }
  }

  Future<void> syncGroupMembersFromSupabase() async {
    try {
      final lastSync = await _getLastSyncTime('group_members');
      final response = await supabase
          .from('group_members')
          .select()
          .gt('updated_at', lastSync.toIso8601String());

      final db = await database;

      for (var item in response) {
        final member = GroupMember.fromMap(item);
        await db.insert(
          'group_members',
          member.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace, // Обновляет или вставляет
        );
      }

      await _setLastSyncTime('group_members', DateTime.now());
    } catch (e) {
      print('Ошибка синхронизации участников групп: $e');
    }
  }

  Future<void> syncGroupMembersToSupabase() async {
    try {
      final db = await database;
      final result = await db.query(
        'group_members',
        where: 'updated_at > last_sync_at OR last_sync_at IS NULL',
      );

      final membersToSync = result.map((e) => GroupMember.fromMap(e)).toList();

      for (var member in membersToSync) {
        final data = {
          'group_id': member.groupId,
          'user_id': member.userId,
          'joined_at': member.joinedAt.toIso8601String(),
          'updated_at': member.updatedAt.toIso8601String(),
          'last_sync_at': DateTime.now().toIso8601String(),
        };

        await supabase.from('group_members').upsert(data);

        await db.update(
          'group_members',
          {'last_sync_at': DateTime.now().toIso8601String()},
          where: 'group_id = ? AND user_id = ?',
          whereArgs: [member.groupId, member.userId],
        );
      }
    } catch (e) {
      print('Ошибка выгрузки участников в Supabase: $e');
    }
  }

  Future<void> syncGroupsFromSupabase() async {
    try {
      final lastSync = await _getLastSyncTime('groups');
      final response = await supabase
          .from('groups')
          .select()
          .gt('updated_at', lastSync.toIso8601String());

      final db = await database;

      for (var item in response) {
        final group = Group.fromMap(item);
        await db.insert(
          'groups',
          group.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await _setLastSyncTime('groups', DateTime.now());
    } catch (e) {
      print('Ошибка синхронизации групп: $e');
    }
  }

  Future<List<Task>> readUserTasks(String userId) async {
    final db = await database;

    // Получаем ID групп, в которых состоит пользователь
    final userGroups = await readUserGroups(userId);
    final groupIds = userGroups.map((g) => g.id).toList();

    // Формируем запрос
    final List<String> whereParts = [];
    final List<Object> whereArgs = [];

    // Условия:
    // 1. Создатель — я
    whereParts.add('creator_id = ?');
    whereArgs.add(userId);

    // 2. Назначен мне
    whereParts.add('assigned_to LIKE ?');
    whereArgs.add('%$userId%');

    // 3. Принадлежит моей группе
    if (groupIds.isNotEmpty) {
      final groupPlaceholders = List.filled(groupIds.length, '?').join(',');
      whereParts.add('group_id IN ($groupPlaceholders)');
      whereArgs.addAll(groupIds);
    }

    final whereClause = whereParts.join(' OR ');

    final result = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return result.map((map) => Task.fromMap(map)).toList();
  }

  // Вспомогательные методы для last_sync_at
  Future<DateTime> _getLastSyncTime(String type) async {
    final db = await database;
    final result = await db.query(
      'sync_state',
      where: 'type = ?',
      whereArgs: [type],
    );

    if (result.isNotEmpty) {
      final time = result.first['last_sync_at'] as String?;
      if (time != null) return DateTime.parse(time);
    }
    return DateTime(2020); // Первичная синхронизация
  }

  Future<void> _setLastSyncTime(String type, DateTime time) async {
    final db = await database;
    await db.insert(
      'sync_state',
      {
        'type': type,
        'last_sync_at': time.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

    await db.execute('''
      CREATE TABLE sync_state (
        type TEXT PRIMARY KEY,
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

  // Возвращает группы, в которых состоит пользователь
  Future<List<Group>> readUserGroups(String userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT g.* 
      FROM groups g
      INNER JOIN group_members gm ON g.id = gm.group_id
      WHERE gm.user_id = ?
      ORDER BY g.name
    ''', [userId]);
    return result.map((map) => Group.fromMap(map)).toList();
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
    // 1. Удаляем из Supabase
    try {
      await supabase.from('tasks').delete().eq('id', id);
    } catch (e) {
      print('Ошибка удаления задачи в Supabase: $e');
      // Не блокируем локальное удаление, если Supabase недоступен
    }

    // 2. Удаляем из локальной БД
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Удалить все задачи группы
  Future<void> deleteTasksByGroupId(String? groupId) async {
    if (groupId == null) return;
    final db = await database;
    await db.delete('tasks', where: 'group_id = ?', whereArgs: [groupId]);
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

  // Удалить группу по ID
  Future<void> deleteGroupById(String? id) async {
    if (id == null) return;
    final db = await database;
    await db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD для участников групп
  Future<GroupMember> createGroupMember(GroupMember member) async {
    final db = await database;
    await db.insert('group_members', member.toMap());
    return member;
  }

  Future<List<GroupMember>> readGroupMembers(String groupId) async {
    final db = await database;
    final result = await db.query('group_members', where: 'group_id = ?', whereArgs: [groupId]);
    return result.map((map) => GroupMember.fromMap(map)).toList();
  }

  // Удалить всех участников группы
  Future<void> deleteAllMembersByGroupId(String? groupId) async {
    if (groupId == null) return;
    final db = await database;
    await db.delete('group_members', where: 'group_id = ?', whereArgs: [groupId]);
  }

  // CRUD для сообщений
  Future<Message> createMessage(Message message) async {
    final db = await database;
    await db.insert('messages', message.toMap());
    return message;
  }

  Future<List<Message>> readMessagesForGroup(String groupId) async {
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

  // Удалить все сообщения группы
  Future<void> deleteMessagesByGroupId(String? groupId) async {
    if (groupId == null) return;
    final db = await database;
    await db.delete('messages', where: 'group_id = ?', whereArgs: [groupId]);
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