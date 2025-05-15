import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import 'create_note_screen.dart'; // Экран создания заметки

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заметки')),
      body: FutureBuilder<List<Note>>(
        future: _databaseService.readAllNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Нет заметок'));
          } else {
            final notes = snapshot.data!;
            return ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Dismissible(
                  key: Key(note.id.toString()),
                  onDismissed: (direction) {
                    _databaseService.deleteNote(note.id!);
                    setState(() {});
                  },
                  background: Container(color: Colors.red),
                  child: Card(
                    color: const Color(0xFFF5F5DC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: Color(0xFF6B705C),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        note.title,
                        style: const TextStyle(color: Color(0xFF2A9D8F)),
                      ),
                      subtitle: Text(
                        '${note.createdAt.day} ${_getMonthName(note.createdAt.month)} ${note.createdAt.hour}:${note.createdAt.minute.toString().padLeft(2, '0')} • ${note.content.length} символов',
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateNoteScreen(note: note),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
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
