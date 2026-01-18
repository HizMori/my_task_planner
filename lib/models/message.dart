class Message {
  final String id;
  final String groupId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final String? senderName;
  final DateTime? lastSyncAt;

  Message({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.senderName,
    this.lastSyncAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'content': content,
      'sent_at': sentAt.toIso8601String(),
      'sender_name': senderName ?? 'Пользователь',
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      groupId: map['group_id'],
      senderId: map['sender_id'],
      content: map['content'],
      sentAt: DateTime.parse(map['sent_at']),
      senderName: map['sender_name']?.toString() ?? 'Пользователь',
      lastSyncAt: map['last_sync_at'] != null ? DateTime.parse(map['last_sync_at']) : null,
    );
  }

  Message copyWith({
    String? id, 
    String? groupId, 
    String? senderId, 
    String? content, 
    DateTime? sentAt,
    String? senderName,
    DateTime? lastSyncAt,
    }) {
    return Message(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      senderName: senderName ?? this.senderName,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}