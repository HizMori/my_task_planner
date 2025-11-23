class GroupMember {
  final String groupId;
  final String userId;
  final DateTime joinedAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;

  GroupMember({
    required this.groupId,
    required this.userId,
    required this.joinedAt,
    required this.updatedAt,
    this.lastSyncAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      groupId: map['group_id'],
      userId: map['user_id'],
      joinedAt: DateTime.parse(map['joined_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastSyncAt: map['last_sync_at'] != null ? DateTime.parse(map['last_sync_at']) : null,
    );
  }
}