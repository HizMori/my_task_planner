class Group {
  final String id;
  final String name;
  final String creatorId;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      creatorId: map['creator_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Group copyWith({String? id, String? name, String? creatorId, DateTime? createdAt}) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}