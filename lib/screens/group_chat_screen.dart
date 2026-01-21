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

class _GroupChatScreenState extends State<GroupChatScreen> with TickerProviderStateMixin{
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _db = DatabaseService.instance;
  final AuthService _auth = AuthService.instance;

  final Map<String, Message> _messageMap = {};
  List<Message> get _messages => _messageMap.values.toList()
    ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  
  String? _currentUserId;
  String? _currentUserName;
  bool _isLoading = true;
  StreamSubscription? _subscription;
  final Map<String, String> _userNames = {};
  Message? _selectedMessage; // выбранное сообщение
  bool _isEditing = false; // режим редактирования
  AnimationController? _menuAnimationController;
  final Map<String, GlobalKey> _messageContentKeys = {}; // ← НОВОЕ: для Column
  OverlayEntry? _messageMenuEntry;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _loadUserData(); // Ждём получения _currentUserId
    await _loadMessages();
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
        final name = m['sender_name'] as String? ?? 'Пользователь';
        _userNames[m['sender_id']] = name;

        final message = Message(
          id: id,
          groupId: m['group_id'],
          senderId: m['sender_id'],
          content: m['content'],
          sentAt: DateTime.parse(m['sent_at']),
          senderName: name,
          isEdited: m['is_edited'] == 1,
        );

        // Сохраняем в локальную БД
        await _db.createMessage(message);

        // Добавляем в UI, если ещё нет
        if (mounted) {
          setState(() {
            if (_messageMap.containsKey(message.id)) {
              print('🟡 Обновляем сообщение: ${message.id}');
            }
            _messageMap[message.id] = message;
          });
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
          print('📡 Получено через Realtime: $change');

          // DELETE
          if (change['eventType'] == 'DELETE' && change.containsKey('old')) {
            final String? id = change['old']['id'] as String?;
            if (id == null) continue;

            await _db.deleteMessage(id);
            if (mounted) {
              setState(() {
                _messageMap.remove(id);
              });
            }
            continue;
          }

          // UPDATE
          if (change['eventType'] == 'UPDATE' && change.containsKey('new')) {
            final data = change['new'] as Map<String, dynamic>;
            final String? id = data['id'] as String?;
            if (id == null) continue;

            final existing = _messageMap[id];
            if (existing != null) {
              final updatedMessage = existing.copyWith(
                content: data['content'],
                isEdited: true,
                senderName: data['sender_name'] ?? existing.senderName,
              );

              await _db.updateMessage(updatedMessage);

              if (mounted) {
                setState(() {
                  _messageMap[id] = updatedMessage;
                });
              }
            }
            continue;
          }

          Map<String, dynamic>? data;
          // INSERT (или initial)
          // Проверяем: если есть 'new' → это нормальный INSERT/UPDATE
          if (change.containsKey('new')) {
            data = change['new'] as Map<String, dynamic>;
          } 
          // Иначе: возможно, это "initial data" — сам объект
          else if (change.containsKey('id') && change.containsKey('content')) {
            data = change; // ← используем напрямую
          } else {
            print('🔴 Непонятный формат: $change');
            continue;
          }

          final id = data['id'] as String?;
          if (id == null) continue;

          final String senderId = data['sender_id'] as String? ?? 'unknown';
          final String content = data['content'] as String;
          final String sentAtStr = data['sent_at'] as String;

          late DateTime sentAt;
          try {
            sentAt = DateTime.parse(sentAtStr);
          } catch (e) {
            print('🔴 Не удалось разобрать время: $sentAtStr');
            continue;
          }

          // Получаем имя
          String? senderName = data['sender_name'] as String?;

          if (senderName == null || senderName.isEmpty) {
            senderName = _userNames[senderId];
          }

          if (senderName == null || senderName.isEmpty) {
            final user = await _db.readUserById(senderId);
            senderName = user?.name;
          }

          senderName = senderName ?? 'Пользователь';
          _userNames[senderId] = senderName;

          final message = Message(
            id: id,
            groupId: widget.groupId,
            senderId: senderId,
            content: content,
            sentAt: sentAt,
            senderName: senderName,
            isEdited: data['is_edited'] == true,
          );

          await _db.createMessage(message).then((_) {
            if (mounted) {
              setState(() {
                if (_messageMap.containsKey(message.id)) {
                  print('🟡 Обновляем сообщение: ${message.id}');
                }
                _messageMap[message.id] = message;
              });
            }
            _scrollToBottom();
          }).catchError((e) {
            print('Ошибка сохранения в локальную БД: $e');
          });
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
    // Загрузим имена всех участников группы
      await _preloadUserNames();
    } catch (e) {
      print('Ошибка загрузки пользователя: $e');
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
      final localMessages = await _db.readMessagesForGroup(widget.groupId);
      final Set<String> localIds = localMessages.map((m) => m.id).toSet();

      final remoteResponse = await Supabase.instance.client
          .from('messages')
          .select('id, group_id, sender_id, content, sent_at, sender_name, is_edited')
          .eq('group_id', widget.groupId)
          .order('sent_at', ascending: true);

      final allMessagesMap = <String, Message>{};

      // Добавляем локальные
      for (final m in localMessages) {
        allMessagesMap[m.id] = m;
      }

      // Перезаписываем из Supabase
      for (final m in remoteResponse) {
        final id = m['id'] as String;
        String? name = m['sender_name'] as String? ?? 'Пользователь';
        _userNames[m['sender_id']] = name;

        final message = Message(
          id: id,
          groupId: m['group_id'],
          senderId: m['sender_id'],
          content: m['content'],
          sentAt: DateTime.parse(m['sent_at']),
          senderName: name,
          isEdited: m['is_edited'] == 1,
        );

        allMessagesMap[id] = message;

        if (!localIds.contains(id)) {
          await _db.createMessage(message);
        }
      }

      setState(() {
        _messageMap.clear();
        _messageMap.addAll(allMessagesMap);
        _isLoading = false;
      });

      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    } catch (e, s) {
      print('Ошибка загрузки сообщений: $e\n$s');

      setState(() async {
        _messageMap.clear();
        for (final m in await _db.readMessagesForGroup(widget.groupId)) {
          _messageMap[m.id] = m;
        }
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки чата')),
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

    if (_isEditing && _selectedMessage != null) {
      // Режим редактирования
      if (content == _selectedMessage!.content) {
        // Нет изменений
        setState(() {
          _isEditing = false;
          _selectedMessage = null;
        });
        _textController.clear();
        return;
      }

      final updatedMessage = _selectedMessage!.copyWith(
        content: content,
        isEdited: true,
        lastSyncAt: DateTime.now(),
      );

      try {
        final response = await Supabase.instance.client
            .from('messages')
            .update({
              'content': content,
              'is_edited': true,
            })
            .eq('id', updatedMessage.id)
            .select();

        if (response.isEmpty) {
          throw Exception('Supabase не обновил сообщение — возможно, RLS или id не найден');
        }
        
        print('✅ Ответ от Supabase при обновлении: $response');

        await _db.updateMessage(updatedMessage);

        setState(() {
          _messageMap[updatedMessage.id] = updatedMessage;
          _isEditing = false;
          _selectedMessage = null;
        });

        _textController.clear();
        _scrollToBottom();
      } catch (e) {
        print('Ошибка обновления сообщения: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось изменить'))
        );
      }
    } else {
      // Обычная отправка
      final newMessage = Message(
        id: Uuid().v4(),
        groupId: widget.groupId,
        senderId: _currentUserId!,
        content: content,
        sentAt: DateTime.now(),
        senderName: _currentUserName,
        isEdited: false,
      );

      try {
        // Сохраняем в Supabase
        await Supabase.instance.client.from('messages').insert({
          'id': newMessage.id,
          'group_id': newMessage.groupId,
          'sender_id': newMessage.senderId,
          'content': newMessage.content,
          'sent_at': newMessage.sentAt.toIso8601String(),
          'sender_name': _currentUserName,
          'is_edited': false,
        });

        // Сохраняем в локальную БД
        await _db.createMessage(newMessage);

        // Добавляем в UI
        setState(() {
          _messageMap[newMessage.id] = newMessage;
        });

        _textController.clear();
        _scrollToBottom();
      } catch (e) {
        await _db.createMessage(newMessage);
        setState(() {
          if (_messageMap.containsKey(newMessage.id)) {
            print('🟡 Новое изменённое сообщение: ${newMessage.id}');
          }
          _messageMap[newMessage.id] = newMessage;
        });
        _textController.clear();
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить: $e')),
        );
      }
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
                          // Проверяем, нужно ли показывать дату
                          bool showDate = true;
                          if (index > 0) {
                            final prevMessage = _messages[index - 1];
                            showDate = !DateTime(
                              message.sentAt.year,
                              message.sentAt.month,
                              message.sentAt.day,
                            ).isAtSameDayAs(
                              DateTime(
                                prevMessage.sentAt.year,
                                prevMessage.sentAt.month,
                                prevMessage.sentAt.day,
                              ),
                            );
                          }
                          return Column(
                            children: [
                              if (showDate)
                                _buildDateLabel(message.sentAt),
                              _buildMessageBubble(message, isMe),
                            ],
                          );
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
                  backgroundColor: _isEditing ? Colors.green : Theme.of(context).primaryColor,
                  mini: true,
                  child: Icon(
                    _isEditing ? Icons.check : Icons.send,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateLabel(DateTime date) {
    String label;
    final now = DateTime.now();
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay.isAtSameDayAs(DateTime(now.year, now.month, now.day))) {
      label = 'Сегодня';
    } else if (messageDay.isAtSameDayAs(
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1)))) {
      label = 'Вчера';
    } else {
      label = DateFormat('d MMMM').format(date).capitalize();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final contentKey = _messageContentKeys[message.id] ??= GlobalKey();
    final String senderName = isMe ? 'Вы' : message.senderName ?? 'Пользователь';
    final String timeText = _formatTime(message.sentAt);

    return GestureDetector(
      onLongPress: () {
        print('✅ Долгое нажатие на сообщение: ${message.id}');
  
        final overlay = Overlay.of(context);
        print('Overlay.of(context): $overlay');
        
        if (overlay == null) {
          print('❌ Overlay не найден! Контекст не подключён к Overlay.');
        } else {
          print('✅ Overlay найден! Можно вставлять меню.');
          _showMessageMenu(context, message, contentKey); // Только если Overlay есть
        }
      },
      child: Padding(
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
                  key: contentKey,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (message.isEdited)
                            const Text(
                              'изменено • ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            )
                          else
                            const SizedBox(),
                          Text(
                            _formatTime(message.sentAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isMe ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageMenu(BuildContext context, Message message, GlobalKey contentKey) {
    if (_messageMenuEntry != null) return;

    if (contentKey.currentContext == null) {
      print('🔴 Не удалось получить контекст Column');
      return;
    }

    final RenderBox contentBox = contentKey.currentContext!.findRenderObject() as RenderBox;
    final Offset contentPosition = contentBox.localToGlobal(Offset.zero);
    final Size contentSize = contentBox.size;

    print('📏 Позиция пузыря: dx=${contentPosition.dx}, dy=${contentPosition.dy}');
    print('📏 Размер пузыря: width=${contentSize.width}, height=${contentSize.height}');
    
    final OverlayState? overlayState = Overlay.of(context);
    if (overlayState == null) {
      print('🔴 Overlay.of(context) вернул null — контекст не подключён к Overlay');
      return;
    }

    final bool isSender = message.senderId == _currentUserId;
    final bool canBeEdited = isSender && DateTime.now().difference(message.sentAt).inHours < 24;
    final bool canBeDeleted = isSender; // можно удалять свои

    final Size screenSize = MediaQuery.of(context).size;
    final EdgeInsets safePadding = MediaQuery.of(context).padding;  // Учёт notch/bottom bar

    print('🖥️ Размер экрана: width=${screenSize.width}, height=${screenSize.height}');
    print('🛡️ Safe padding: top=${safePadding.top}, bottom=${safePadding.bottom}, left=${safePadding.left}, right=${safePadding.right}');

    final double maxMenuWidth = screenSize.width * 0.4;
    double menuHeight = (canBeEdited ? 60 : 0) + (canBeDeleted ? 60 : 0);
  
    // Offsets для тонкой настройки
    const double horizontalOffset = 40;  // Измените: >0 правее, <0 левее
    const double verticalOffset = -30;     // Измените: >0 ниже, <0 выше
    print('🔧 Применённые offsets: horizontal=$horizontalOffset, vertical=$verticalOffset');
    
    // Позиционирование меню// Перекрытие: если места мало, позволяем overlap на N px
    const double overlapAmount = 10;  // Измените: больше — больше перекрытия

    // Проверка пространства слева/справа
    double preferredLeft = isSender 
        ? contentPosition.dx - maxMenuWidth - 10 + horizontalOffset
        : contentPosition.dx + contentSize.width + 10 + horizontalOffset;

    if (preferredLeft < safePadding.left) {
      preferredLeft = contentPosition.dx + contentSize.width - overlapAmount + horizontalOffset;  // Fallback справа
      print('↔️ Перекрытие: Меню частично на пузыре справа (мало места слева)');
    } else if (preferredLeft + maxMenuWidth > screenSize.width - safePadding.right) {
      preferredLeft = contentPosition.dx - maxMenuWidth + overlapAmount + horizontalOffset;  // Fallback слева
      print('↔️ Перекрытие: Меню частично на пузыре слева (мало места справа)');
    }

    // Для top: предпочтительно ниже, но если места мало — сверху
    double preferredTop = contentPosition.dy + contentSize.height + 10 + verticalOffset;
    if (preferredTop + menuHeight > screenSize.height - safePadding.bottom) {
      preferredTop = contentPosition.dy - menuHeight - overlapAmount + verticalOffset;  // Сверху
      print('↕️ Fallback: Меню сверху (мало места снизу)');
      if (preferredTop < safePadding.top) {
        preferredTop = safePadding.top + overlapAmount;  // Clamp сверху
        print('↕️ Clamp: Меню прижато к верхнему краю');      
      }
    }

    print('🧭 Финальная позиция меню: left=$preferredLeft, top=$preferredTop');

    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    final scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _menuAnimationController!, curve: Curves.easeOutBack),
    );
    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _menuAnimationController!, curve: Curves.easeOut),
    );

    _messageMenuEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideMessageMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          AnimatedBuilder(
            animation: _menuAnimationController!,
            builder: (context, child) => Positioned(
              left: preferredLeft,
              top: preferredTop,
              child: ScaleTransition(
                scale: scale,
                child: FadeTransition(
                  opacity: opacity,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF8F9FA),
                    child: IntrinsicWidth(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxMenuWidth),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canBeEdited)
                              ListTile(
                                leading: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                title: const Text("Изменить", style: TextStyle(fontSize: 14)),
                                onTap: () {
                                  _hideMessageMenu();
                                  _startEditing(message);
                                },
                              ),
                            if (canBeDeleted)
                              ListTile(
                                leading: const Icon(Icons.delete, size: 18, color: Colors.red),
                                title: const Text("Удалить", style: TextStyle(fontSize: 14)),
                                onTap: () {
                                  _hideMessageMenu();
                                  _confirmDelete(message);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_messageMenuEntry!);
    _menuAnimationController!.forward();
  }

  void _hideMessageMenu() {
    _menuAnimationController?.reverse().then((_) {
      print('🔒 Меню закрыто');
      _messageMenuEntry?.remove();
      _messageMenuEntry = null;
      _menuAnimationController?.dispose();
      _menuAnimationController = null;
    });
  }

  Future<void> _confirmDelete(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Удалить сообщение?"),
        content: const Text("Это сообщение будет удалено безвозвратно."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Удалить", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMessage(message);
    }
  }

  Future<void> _deleteMessage(Message message) async {
    try {
      // Удаляем в Supabase
      final response = await Supabase.instance.client
          .from('messages')
          .delete()
          .eq('id', message.id);

      if (response == 0) {
        throw Exception('Сообщение не найдено в Supabase');
      }

      print('✅ Сообщение удалено из Supabase: ${message.id}');

      // Удаляем из локальной БД
      await _db.deleteMessage(message.id);
      print('🗑️ Сообщение удалено из локальной БД: ${message.id}');

      // Удаляем из UI
      if (mounted) {
        setState(() {
          _messageMap.remove(message.id);
        });
      }
    } catch (e) {
      print('Ошибка удаления сообщения: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось удалить сообщение')),
      );
    }
  }

  void _startEditing(Message message) {
    setState(() {
      _isEditing = true;
      _selectedMessage = message;
      _textController.text = message.content;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
  }

  String _formatTime(DateTime sentAt) {
    return DateFormat.Hm().format(sentAt);
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

extension DateTimeComparison on DateTime {
  bool isAtSameDayAs(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}