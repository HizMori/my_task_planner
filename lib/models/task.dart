// Класс, описывающий структуру задачи
class Task {
  final String? id; // Уникальный идентификатор задачи (может быть null при создании)
  final String title; // Название задачи
  final String? description; // Описание задачи (может быть пустым)
  final String? dueDate;
  final DateTime? deadline; // Дедлайн задачи (может быть пустым)
  final String? priority; // Приоритет задачи (например, "low", "medium", "high")
  final String? category; // Категория задачи (например, "работа", "личное")
  final bool is_completed; // Статус выполнения задачи (true — выполнена, false — нет)
  final String? assigned_to; // Кому назначена задача (например, UID контакта, опционально)
  final String? groupId;  // ID группы, если групповая
  final String creatorId;  // ID создателя
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? last_sync_at;

  Task({
    this.id, // ID задачи
    required this.title, // Обязательное поле — название
    this.description, // Описание (необязательно)
    this.dueDate,
    this.deadline, // Дедлайн (необязательно)
    required this.priority, // Обязательное поле — приоритет
    required this.category, // Обязательное поле — категория
    this.is_completed = false, // По умолчанию задача не выполнена
    this.assigned_to, // Назначение (необязательно)
    this.groupId,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    this.last_sync_at,
  });

  // Метод для преобразования задачи в Map (нужен для сохранения в базу данных)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title, // Название
      'description': description, // Описание
      'deadline': deadline?.toIso8601String(), // Преобразуем дату в строку формата ISO8601
      'priority': priority, // Приоритет
      'category': category, // Категория
      'is_completed': is_completed ? 1 : 0, // Преобразуем bool в int (1 — выполнена, 0 — нет)
      'assigned_to': assigned_to, // Кому назначена задача
      'group_id': groupId,
      'creator_id': creatorId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_sync_at': last_sync_at?.toIso8601String(),
    };
  }

  // Фабричный метод для создания задачи из Map (нужен при загрузке из базы данных)
  factory Task.fromMap(Map<String, dynamic> map) {
  return Task(
    id: map['id']?.toString(), // Извлекаем ID
    title: map['title'], // Извлекаем название
    description: map['description'], // Извлекаем описание
    deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
    priority: map['priority'] ?? 'medium', // Извлекаем приоритет
    category: map['category'] ?? 'other', // Извлекаем категорию
    is_completed: map['is_completed'] == true, // Исправлено на is_completed
    assigned_to: map['assigned_to'],
    groupId: map['group_id'],
    creatorId: map['creator_id'].toString(),
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    last_sync_at: map['last_sync_at'] != null ? DateTime.parse(map['last_sync_at']) : null,
  );
}

  // Для Supabase (если нужно адаптировать, например, без INTEGER)
  Map<String, dynamic> toMapSupabase() {
    return {
    'id': id,
    'title': title,
    'description': description,
    'deadline': deadline?.toIso8601String(),
    'priority': priority, // 'low', 'medium', 'high'
    'category': category, // 'work', 'personal', 'study', 'other'
    'is_completed': is_completed,
    'assigned_to': assigned_to,
    'group_id': groupId,
    'creator_id': creatorId,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'last_sync_at': DateTime.now().toIso8601String(),
    };  // Можно расширить, если нужно
  }

  factory Task.fromSupabaseMap(Map<String, dynamic> map) {
  return Task(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    dueDate: map['due_date'],
    deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
    priority: map['priority'] ?? 'medium',
    category: map['category'] ?? 'other',
    is_completed: map['is_completed'] == true,
    assigned_to: map['assigned_to'],
    groupId: map['group_id'],
    creatorId: map['creator_id'],
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    last_sync_at: DateTime.now(), // Обновляем при синхронизации
  );
}

  // Метод для создания копии задачи с измененными полями
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    String? priority,
    String? category,
    bool? is_completed,
    String? assigned_to,
    String? groupId, 
    String? creatorId, 
    DateTime? createdAt, 
    DateTime? updatedAt,
    DateTime? last_sync_at,
  }) {
    return Task(
      id: id ?? this.id, // Используем новое значение или старое, если новое null
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      is_completed: is_completed ?? this.is_completed,
      assigned_to: assigned_to ?? this.assigned_to,
      groupId: groupId ?? this.groupId,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      last_sync_at: last_sync_at ?? this.last_sync_at,
    );
  }
}
