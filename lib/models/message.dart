import 'dart:convert';

class Message {
  final String id;
  final String groupId;
  final String senderId;
  final String content;
  final List<Map<String, String>>? attachments;
  final String? replyToId;
  final DateTime sentAt;
  final String? senderName;
  final bool isEdited;
  final DateTime? lastSyncAt;

  Message({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.content,
    this.attachments,
    this.replyToId,
    required this.sentAt,
    this.senderName,
    this.isEdited = false,
    this.lastSyncAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'content': content,
      'attachments': jsonEncode(attachments ?? []),
      'reply_to_id': replyToId,
      'sent_at': sentAt.toIso8601String(),
      'sender_name': senderName ?? 'Пользователь',
      'is_edited': isEdited ? 1 : 0,
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    dynamic raw = map['attachments'];
    List<Map<String, String>>? attachments;

    if (raw != null) {
      if (raw is String) {
        // из sqflite или старого insert
        attachments = List<Map<String, String>>.from(
          jsonDecode(raw).map((e) => Map<String, String>.from(e as Map)),
        );
      } else if (raw is List) {
        // из Supabase Realtime / select
        attachments = List<Map<String, String>>.from(
          raw.map((e) => Map<String, String>.from(e as Map)),
        );
      }
    }

    return Message(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String? ?? '',
      attachments: attachments,
      replyToId: map['reply_to_id'],
      sentAt: DateTime.parse(map['sent_at'] as String),
      senderName: map['sender_name']?.toString() ?? 'Пользователь',
      isEdited: map['is_edited'] == 1 || map['is_edited'] == true,
      lastSyncAt: map['last_sync_at'] != null 
          ? DateTime.parse(map['last_sync_at'] as String) 
          : null,
    );
  }

  Message copyWith({
    String? id, 
    String? groupId, 
    String? senderId, 
    String? content, 
    List<Map<String, String>>? attachments,
    String? replyToId,
    DateTime? sentAt,
    String? senderName,
    bool? isEdited,
    DateTime? lastSyncAt,
    }) {
    return Message(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      replyToId: replyToId ?? this.replyToId,
      sentAt: sentAt ?? this.sentAt,
      senderName: senderName ?? this.senderName,
      isEdited: isEdited ?? this.isEdited,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}