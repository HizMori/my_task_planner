class User {
  final int? id;
  final String name;
  final String? email;
  final String? telephone;
  final String? password;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;

  User({
    this.id,
    required this.name,
    this.email,
    this.telephone,
    this.password,
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
      'password': password,
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
      password: map['password'],
      avatarUrl: map['avatar_url'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastSyncAt: map['last_sync_at'] != null ? DateTime.parse(map['last_sync_at']) : null,
    );
  }

  User copyWith({
    int? id, 
    String? name, 
    String? email,
    String? telephone,
    String? password,
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
      password: password ?? this.password,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}