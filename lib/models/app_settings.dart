class AppSettings {
  final String userId;
  final String theme;  // 'light', 'dark', 'system'
  final bool notificationsEnabled;
  final int reminderTime;  // Минуты

  AppSettings({
    required this.userId,
    this.theme = 'system',
    this.notificationsEnabled = true,
    this.reminderTime = 15,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'theme': theme,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'reminder_time': reminderTime,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      userId: map['user_id'],
      theme: map['theme'],
      notificationsEnabled: map['notifications_enabled'] == 1,
      reminderTime: map['reminder_time'],
    );
  }

  AppSettings copyWith({String? userId, String? theme, bool? notificationsEnabled, int? reminderTime}) {
    return AppSettings(
      userId: userId ?? this.userId,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}