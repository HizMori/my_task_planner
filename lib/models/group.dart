class Group {
  final String id;
  final String name;
  final String creatorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;

  Group({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      creatorId: map['creator_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastSyncAt: map['last_sync_at'] != null ? DateTime.parse(map['last_sync_at']) : null,
    );
  }

  Group copyWith({
    String? id, 
    String? name, 
    String? creatorId, 
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
    }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}