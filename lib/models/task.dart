// Класс, описывающий структуру задачи
class Task {
  final int?
  id; // Уникальный идентификатор задачи (может быть null при создании)
  final String title; // Название задачи
  final String? description; // Описание задачи (может быть пустым)
  final String? dueDate;
  final DateTime? deadline; // Дедлайн задачи (может быть пустым)
  final String priority; // Приоритет задачи (например, "low", "medium", "high")
  final String category; // Категория задачи (например, "работа", "личное")
  final bool
  isCompleted; // Статус выполнения задачи (true — выполнена, false — нет)
  final String?
  assignedTo; // Кому назначена задача (например, UID контакта, опционально)

  Task({
    this.id, // ID задачи
    required this.title, // Обязательное поле — название
    this.description, // Описание (необязательно)
    this.dueDate,
    this.deadline, // Дедлайн (необязательно)
    required this.priority, // Обязательное поле — приоритет
    required this.category, // Обязательное поле — категория
    this.isCompleted = false, // По умолчанию задача не выполнена
    this.assignedTo, // Назначение (необязательно)
  });

  // Метод для преобразования задачи в Map (нужен для сохранения в базу данных)
  Map<String, dynamic> toMap() {
    return {
      'id': id, // ID задачи
      'title': title, // Название
      'description': description, // Описание
      'deadline':
          deadline
              ?.toIso8601String(), // Преобразуем дату в строку формата ISO8601
      'priority': priority, // Приоритет
      'category': category, // Категория
      'isCompleted':
          isCompleted
              ? 1
              : 0, // Преобразуем bool в int (1 — выполнена, 0 — нет)
      'assignedTo': assignedTo, // Кому назначена задача
    };
  }

  // Фабричный метод для создания задачи из Map (нужен при загрузке из базы данных)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'], // Извлекаем ID
      title: map['title'], // Извлекаем название
      description: map['description'], // Извлекаем описание
      deadline:
          map['deadline'] != null
              ? DateTime.parse(map['deadline'])
              : null, // Парсим дедлайн из строки
      priority: map['priority'], // Извлекаем приоритет
      category: map['category'], // Извлекаем категорию
      isCompleted: map['isCompleted'] == 1, // Преобразуем int в bool
      assignedTo: map['assignedTo'], // Извлекаем назначение
    );
  }

  // Метод для создания копии задачи с измененными полями
  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? deadline,
    String? priority,
    String? category,
    bool? isCompleted,
    String? assignedTo,
  }) {
    return Task(
      id:
          id ??
          this.id, // Используем новое значение или старое, если новое null
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}
