import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class GroupChatScreen extends StatefulWidget {
  // Передаём ID группы — важно!
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _db = DatabaseService.instance;
  final AuthService _auth = AuthService.instance;

  List<Message> _messages = [];
  String? _currentUserId;
  String? _currentUserName;
  bool _isLoading = true;
  StreamSubscription? _subscription;
  final Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMessages();
    _subscribeToMessages();
    _startPeriodicSync();
  }

  Timer? _syncTimer;

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _syncMessagesFromSupabase();
    });
  }

  Future<void> _syncMessagesFromSupabase() async {
    try {
      final lastMessageTime = _messages.isEmpty
          ? DateTime(2020)
          : _messages.last.sentAt;

      final response = await Supabase.instance.client
          .from('messages')
          .select('*, users(name)')
          .eq('group_id', widget.groupId)
          .gt('sent_at', lastMessageTime.toIso8601String())
          .order('sent_at', ascending: true);

      for (final m in response) {
        final id = m['id'] as String;
        final name = m['users']?['name'] as String? ?? 'Пользователь';
        _userNames[m['sender_id']] = name;

        final message = Message(
          id: id,
          groupId: m['group_id'],
          senderId: m['sender_id'],
          content: m['content'],
          sentAt: DateTime.parse(m['sent_at']),
          senderName: name,
        );

        // ✅ Сохраняем в локальную БД
        await _db.createMessage(message);

        // ✅ Добавляем в UI, если ещё нет
        if (!_messages.any((msg) => msg.id == id)) {
          if (mounted) {
            setState(() {
              _messages.add(message);
            });
          }
        }
      }
    } catch (e) {
      print('Ошибка фоновой синхронизации: $e');
    }
  }

  void _subscribeToMessages() {
    _subscription = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', widget.groupId)
        .listen((List<Map<String, dynamic>> payload) async {
      for (final change in payload) {
        final String event = change['event'] as String;
        final Map<String, dynamic>? newData = change['new'] as Map<String, dynamic>?;

        if (event == 'INSERT' && newData != null) {
          final String senderId = newData['sender_id'] as String? ?? 'unknown';
          String? rawName = (newData['users'] as Map?)?['name'] as String?;

          if (rawName == null || rawName.isEmpty) {
            if (_userNames.containsKey(senderId)) {
              rawName = _userNames[senderId];
            } else {
              final user = await _db.readUserById(senderId);
              rawName = user?.name;
            }
          }

          final String senderName = rawName ?? _userNames[senderId] ?? 'Пользователь';
          _userNames[senderId] = senderName;

          final newMessage = Message(
            id: newData['id'],
            groupId: newData['group_id'],
            senderId: senderId,
            content: newData['content'],
            sentAt: DateTime.parse(newData['sent_at'] as String),
            senderName: senderName,
          );

          // ✅ Сохраняем в локальную БД!
          _db.createMessage(newMessage).then((_) {
            // Только после сохранения — обновляем UI
            if (mounted) {
              setState(() {
                _messages.add(newMessage);
              });
            }
            _scrollToBottom();
          }).catchError((e) {
            print('Ошибка сохранения сообщения в локальную БД: $e');
          });
        }
      }
    }, onError: (error) {
      print('Stream error: $error');
    });
  }

  Future<void> _loadUserData() async {
    try {
      final response = await Supabase.instance.client.auth.getUser();
      _currentUserId = response.user?.id;

      // Получаем имя из локальной БД (если есть)
      final user = await _db.readUserById(_currentUserId ?? '');
       _currentUserName = user?.name ?? 'Вы';
    // ✅ Загрузим имена всех участников группы
      await _preloadUserNames();
    } catch (e) {
      _currentUserName = 'Вы';
    }
  }

  Future<void> _preloadUserNames() async {
    try {
      final members = await Supabase.instance.client
          .from('group_members')
          .select('user_id')
          .eq('group_id', widget.groupId);

      final userIds = members.map((m) => m['user_id']).whereType<String>().toList();
      if (userIds.isEmpty) return;

      final users = await Supabase.instance.client
          .from('users')
          .select('id, name')
          .filter('id', 'in', userIds);

      for (var u in users) {
        _userNames[u['id']] = u['name'];
      }
    } catch (e) {
      print('Ошибка загрузки имён пользователей: $e');
    }
  }

  Future<void> _loadMessages() async {
    print('🔄 Начинаем загрузку сообщений для группы: ${widget.groupId}');
    try {
      print('✅ Проверяем локальные сообщения...');
      // Сначала загружаем из локальной БД (оффлайн-доступ)
      final localMessages = await _db.readMessagesForGroup(widget.groupId);
      final localMap = {for (var m in localMessages) m.id: m};
      final Set<String> localIds = localMap.keys.toSet();
      print('📦 Локальных сообщений: ${localMessages.length}');
      print('☁️ Запрашиваем из Supabase...');
      // Загружаем из Supabase
      final remoteResponse = await Supabase.instance.client
          .from('messages')
          .select('id, group_id, sender_id, content, sent_at')
          .eq('group_id', widget.groupId)
          .order('sent_at', ascending: true);

      print('✅ Supabase вернул ${remoteResponse.length} сообщений');
      final remoteMessages = <Message>[];
      final seenIds = <String>{};

      for (final m in remoteResponse) {
        final id = m['id'] as String;
        seenIds.add(id);

        // Обновляем кэш имён
        String? name = m['users']?['name'] as String?;
        if (name == null || name.isEmpty) {
          // Попробуем получить из локальной БД
          final cachedUser = await _db.readUserById(m['sender_id']);
          name = cachedUser?.name;
        }
        name = name ?? 'Пользователь';
        _userNames[m['sender_id']] = name;

        final message = Message(
          id: id,
          groupId: m['group_id'],
          senderId: m['sender_id'],
          content: m['content'],
          sentAt: DateTime.parse(m['sent_at']),
          senderName: name,
        );

        remoteMessages.add(message);

        // Сохраняем в локальную БД, если ещё нет
        if (!localIds.contains(id)) {
          await _db.createMessage(message);
        }
      }

      // 4Объединяем: приоритет — свежие из Supabase, но если нет — локальные
      final allMessagesMap = <String, Message>{};

      // Добавляем локальные (на случай, если Supabase их не вернул)
      for (final m in localMessages) {
        allMessagesMap[m.id] = m;
      }

      // Перезаписываем более свежими из Supabase
      for (final m in remoteMessages) {
        allMessagesMap[m.id] = m;
      }

      final allMessages = allMessagesMap.values.toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

      setState(() {
        _messages = allMessages;
        _isLoading = false;
      });

      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    } catch (e, s) {
      print('Ошибка загрузки сообщений: $e\n$s');

      // Включаем оффлайн-режим
      final fallback = await _db.readMessagesForGroup(widget.groupId);
      setState(() {
        _messages = fallback;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка чата: $e')), // ← Покажи ошибку
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _textController.text.trim();
    if (content.isEmpty || _currentUserId == null) return;

    final now = DateTime.now();
    final newMessage = Message(
      id: Uuid().v4(), // Генерируем ID
      groupId: widget.groupId,
      senderId: _currentUserId!,
      content: content,
      sentAt: now,
      senderName: _currentUserName,
    );

    try {
      // Сохраняем в Supabase
      await Supabase.instance.client.from('messages').insert({
        'id': newMessage.id,
        'group_id': newMessage.groupId,
        'sender_id': newMessage.senderId,
        'content': newMessage.content,
        'sent_at': newMessage.sentAt.toIso8601String(),
      });

      // Сохраняем в локальную БД
      await _db.createMessage(newMessage);

      // Добавляем в UI
      setState(() {
        _messages.add(newMessage);
      });

      _textController.clear();
      _scrollToBottom();
    } catch (e) {
      await _db.createMessage(newMessage);
      setState(() {
        _messages.add(newMessage);
      });
      _textController.clear();
      _scrollToBottom();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить: $e')),
      );
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('Ещё нет сообщений'),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == _currentUserId;

                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),

          // Поле ввода
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Написать сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color(0xFFf2f2f7),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Theme.of(context).primaryColor,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final String senderName = isMe ? 'Вы' : message.senderName ?? 'Пользователь';
    final String timeText = _formatTime(message.sentAt);

    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isMe ? 60 : 12,
        right: isMe ? 12 : 60,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: IntrinsicWidth(
            // ← Ключевое: делает ширину = max(текст, время)
            stepWidth: 10.0,
            child: Container(
              decoration: BoxDecoration(
                color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Имя отправителя (только у чужих)
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8, right: 12),
                      child: Text(
                        senderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  // Текст сообщения
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  // Время — теперь не Padding, а отдельный элемент с отступом
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime sentAt) {
  if (sentAt.isToday()) {
      return DateFormat.Hm().format(sentAt);
    } else if (sentAt.isYesterday()) {
      return 'Вчера';
    } else {
      return DateFormat('dd MMM').format(sentAt);
    }
  }
}

extension DateTimeExtension on DateTime {
  bool isToday() {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.day == day && yesterday.month == month && yesterday.year == year;
  }
}