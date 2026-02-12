import 'dart:convert'; // Для JSON

class GroupMember {
  final String groupId;
  final String userId;
  final String role; 
  final String? permissions; 
  final String? customTitle;
  final DateTime joinedAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;

  GroupMember({
    required this.groupId,
    required this.userId,
    this.role = 'member',
    this.permissions,
    this.customTitle,
    required this.joinedAt,
    required this.updatedAt,
    this.lastSyncAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'permissions': permissions,
      'custom_title': customTitle ?? '',
      'joined_at': joinedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    final rawCustomTitle = map['custom_title'];
    final customTitle = (rawCustomTitle is String && rawCustomTitle.trim().isNotEmpty)
        ? rawCustomTitle.trim()
        : null;

    return GroupMember(
      groupId: map['group_id'],
      userId: map['user_id'],
      role: map['role'] ?? 'member',
      permissions: map['permissions'],
      customTitle: customTitle,
      joinedAt: DateTime.parse(map['joined_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastSyncAt: map['last_sync_at'] != null ? DateTime.parse(map['last_sync_at']) : null,
    );
  }

  // Хелперы для permissions (опционально, для удобства)
  Map<String, bool> getPermissionsMap() {
    if (permissions == null || permissions == '{}' || permissions!.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(permissions!);
      if (decoded is Map<String, dynamic>) {
        return decoded.map((key, value) => MapEntry(key, value as bool));
      }
      return {};
    } catch (e) {
      print('Error parsing permissions: $e, raw value: $permissions');
      return {};
    }
  }

  GroupMember copyWith({
    String? groupId,
    String? userId,
    String? role,
    String? permissions,
    String? customTitle,
    DateTime? joinedAt,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
  }) {
    return GroupMember(
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      customTitle: customTitle ?? this.customTitle,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  bool canManageAdmins() {
    if (role == 'creator') return true;
    final perms = getPermissionsMap();
    return perms['can_manage_admins'] == true;
  }

  bool canDeleteGroup() {
    if (role == 'creator') return true;
    final perms = getPermissionsMap();
    return perms['can_delete_group'] == true;
  }

  bool canDeleteMessages() {
    if (role == 'creator') return true;
    final perms = getPermissionsMap();
    return perms['can_manage_chat'] == true;
  }

  bool get isCreator => role == 'creator';
  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';
}