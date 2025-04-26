import 'package:sqflite/sqflite.dart'; // Пакет для работы с SQLite
import 'package:path/path.dart'; // Пакет для работы с путями
import '../models/task.dart'; // Импортируем модель задачи
import '../models/note.dart'; // Импортируем модель заметки

class DatabaseService {
  static final DatabaseService instance =
      DatabaseService._init(); // Создаем singleton экземпляр сервиса
  static Database? _database; // Приватная переменная для хранения базы данных

  DatabaseService._init(); // Приватный конструктор для singleton

  // Геттер для получения базы данных
  Future<Database> get database async {
    if (_database != null)
      return _database!; // Если база уже инициализирована, возвращаем её
    _database = await _initDB(
      'tasks.db',
    ); // Инициализируем базу, если она ещё не создана
    return _database!;
  }

  // Метод для инициализации базы данных
  Future<Database> _initDB(String filePath) async {
    final dbPath =
        await getDatabasesPath(); // Получаем путь к директории базы данных
    final path = join(
      dbPath,
      filePath,
    ); // Формируем полный путь к файлу базы данных
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    ); // Открываем или создаем базу
  }

  // Метод для создания таблицы задач при первом запуске
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        title TEXT NOT NULL, 
        description TEXT, 
        dueDate TEXT,
        deadline TEXT, 
        priority TEXT NOT NULL, 
        category TEXT NOT NULL, 
        isCompleted INTEGER NOT NULL, 
        assignedTo TEXT 
      )
    ''');
    await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
  }

  // Метод для создания новой задачи
  Future<Task> create(Task task) async {
    final db = await instance.database; // Получаем доступ к базе данных
    final id = await db.insert(
      'tasks',
      task.toMap(),
    ); // Вставляем задачу и получаем её ID
    return task.copyWith(id: id); // Возвращаем задачу с присвоенным ID
  }

  // Метод для чтения всех задач
  Future<List<Task>> readAllTasks() async {
    final db = await instance.database; // Получаем доступ к базе данных
    final result = await db.query(
      'tasks',
    ); // Запрашиваем все записи из таблицы tasks
    return result
        .map((json) => Task.fromMap(json))
        .toList(); // Преобразуем результат в список задач
  }

  // Метод для обновления задачи
  Future<int> update(Task task) async {
    final db = await instance.database; // Получаем доступ к базе данных
    return db.update(
      'tasks', // Таблица для обновления
      task.toMap(), // Данные для обновления
      where: 'id = ?', // Условие — обновляем задачу с конкретным ID
      whereArgs: [task.id], // Аргумент для условия
    );
  }

  // Метод для удаления задачи
  Future<int> delete(int id) async {
    final db = await instance.database; // Получаем доступ к базе данных
    return await db.delete(
      'tasks', // Таблица для удаления
      where: 'id = ?', // Условие — удаляем задачу с конкретным ID
      whereArgs: [id], // Аргумент для условия
    );
  }

  // Новые методы для заметок
  Future<int> createNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> readAllNotes() async {
    final db = await database;
    final result = await db.query('notes');
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // Метод для закрытия базы данных
  Future<void> close() async {
    final db = await instance.database; // Получаем доступ к базе данных
    db.close(); // Закрываем соединение с базой
  }
}
