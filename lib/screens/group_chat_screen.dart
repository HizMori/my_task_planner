import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMessages();
    _subscribeToMessages();
  }

  void _subscribeToMessages() {
    _subscription = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', widget.groupId)
        .listen((List<Map<String, dynamic>> payload) {
      // Приходит список, но нас интересует только новое сообщение
      for (final change in payload) {
        if (change['group_id'] == widget.groupId) {
          final newMessage = Message.fromMap({
            'id': change['id'],
            'group_id': change['group_id'],
            'sender_id': change['sender_id'],
            'content': change['content'],
            'sent_at': change['sent_at'],
          });

          setState(() {
            _messages.add(newMessage);
          });

          _scrollToBottom();
        }
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final response = await Supabase.instance.client.auth.getUser();
      _currentUserId = response.user?.id;

      // Получаем имя из локальной БД (если есть)
      final user = await _db.readUserById(_currentUserId ?? '');
      _currentUserName = user?.name ?? 'Аноним';
    } catch (e) {
      _currentUserName = 'Пользователь';
    }
  }

  Future<void> _loadMessages() async {
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('*, users(name)')
          .eq('group_id', widget.groupId)
          .order('sent_at', ascending: true);

      final messages = (response as List)
          .map((m) => Message.fromMap({
                'id': m['id'],
                'group_id': m['group_id'],
                'sender_id': m['sender_id'],
                'content': m['content'],
                'sent_at': m['sent_at'],
              }))
          .toList();

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Прокрутка вниз
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки сообщений: $e')),
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

    try {
      await Supabase.instance.client.from('messages').insert({
        'group_id': widget.groupId,
        'sender_id': _currentUserId,
        'content': content,
        'sent_at': DateTime.now().toIso8601String(),
      });

      _textController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить: $e')),
      );
    }
  }

  @override
  void dispose() {
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
    // Пока имя подтягиваем из локальной БД (можно улучшить через JOIN с users)
    // Сейчас у нас в `messages` нет `users.name`, но в Supabase-запросе выше мы делали `users(name)`
    // Однако ты в `Message.fromMap` не передаёшь имя. Давай временно покажем ID или "Вы"

    final userName = isMe ? 'Вы' : 'Пользователь';

    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isMe ? 60 : 12,
        right: isMe ? 12 : 60,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Text(
              '${userName}, ${_formatTime(message.sentAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime sentAt) {
    final now = DateTime.now();
    final difference = now.difference(sentAt);
    if (difference.inMinutes < 1) return 'только что';
    if (difference.inHours < 1) return '${difference.inMinutes} мин';
    if (difference.inDays < 1) return '${difference.inHours} ч';
    return '${sentAt.day}.${sentAt.month} ${sentAt.hour}:${sentAt.minute.toString().padLeft(2, '0')}';
  }
}