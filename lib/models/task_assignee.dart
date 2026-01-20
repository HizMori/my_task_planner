class TaskAssignee {
  final String taskId;
  final String userId;
  final DateTime assignedAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;

  TaskAssignee({
    required this.taskId,
    required this.userId,
    required this.assignedAt,
    required this.updatedAt,
    this.lastSyncAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'task_id': taskId,
      'user_id': userId,
      'assigned_at': assignedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  factory TaskAssignee.fromMap(Map<String, dynamic> map) {
    return TaskAssignee(
      taskId: map['task_id'],
      userId: map['user_id'],
      assignedAt: DateTime.parse(map['assigned_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastSyncAt: map['last_sync_at'] != null ? DateTime.parse(map['last_sync_at']) : null,
    );
  }

  TaskAssignee copyWith({
    String? taskId,
    String? userId,
    DateTime? assignedAt,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
  }) {
    return TaskAssignee(
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      assignedAt: assignedAt ?? this.assignedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}
