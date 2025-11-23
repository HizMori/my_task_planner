class AppSettings {
  final String userId;
  final String theme;  // 'light', 'dark', 'system'
  final bool notificationsEnabled;
  final int reminderTime;  // Минуты
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;

  AppSettings({
    required this.userId,
    this.theme = 'system',
    this.notificationsEnabled = true,
    this.reminderTime = 15,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'theme': theme,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'reminder_time': reminderTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      userId: map['user_id'],
      theme: map['theme'],
      notificationsEnabled: map['notifications_enabled'] == 1,
      reminderTime: map['reminder_time'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastSyncAt: map['last_sync_at'] != null ? DateTime.parse(map['last_sync_at']) : null,
    );
  }

  AppSettings copyWith({
    String? userId, 
    String? theme, 
    bool? notificationsEnabled, 
    int? reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
    }) {
    return AppSettings(
      userId: userId ?? this.userId,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}