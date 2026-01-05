class User {
  final String id;  // Изменено на String для UUID
  final String name;
  final String? email;
  final String? telephone;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;

  User({
    required this.id,
    required this.name,
    this.email,
    this.telephone,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'telephone': telephone,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      telephone: map['telephone'],
      avatarUrl: map['avatar_url'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastSyncAt: map['last_sync_at'] != null ? DateTime.parse(map['last_sync_at']) : null,
    );
  }

  User copyWith({
    String? id,
    String? name, 
    String? email,
    String? telephone,
    String? avatarUrl, 
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
    }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}