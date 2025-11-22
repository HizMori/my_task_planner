/*
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';

class CreateNoteScreen extends StatefulWidget {
  final Note? note;

  const CreateNoteScreen({super.key, this.note});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService.instance;
  DateTime _createdAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _createdAt = widget.note!.createdAt;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() async {
    final note = Note(
      id: widget.note?.id,
      title: _titleController.text,
      content: _contentController.text,
      createdAt: _createdAt,
    );

    if (widget.note == null) {
      await _databaseService.createNote(note);
    } else {
      await _databaseService.updateNote(note);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заметки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _saveNote,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Поле ввода заголовка
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Заголовок',
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          // Дата и количество символов
          Text(
            '${_createdAt.day} ${_getMonthName(_createdAt.month)} ${_createdAt.hour}:${_createdAt.minute.toString().padLeft(2, '0')} • ${_contentController.text.length} символов',
          ),
          const SizedBox(height: 16),
          // Поле ввода текста
          Expanded(
            child: TextField(
              controller: _contentController,
              maxLines: null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Начать ввод',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (value) {
                setState(() {}); // Обновляем количество символов
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return months[month - 1];
  }
}
*/