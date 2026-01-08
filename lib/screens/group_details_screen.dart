import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group.dart';
import 'group_members_screen.dart';
import 'group_chat_screen.dart';
import 'group_tasks_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Участники',
            ),
            Tab(
              icon: Icon(Icons.chat_bubble),
              text: 'Чат',
            ),
            Tab(
              icon: Icon(Icons.checklist),
              text: 'Задачи',
            ),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.normal),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Вкладка: Участники
          const GroupMembersScreen(),
          // Вкладка: Чат
          const GroupChatScreen(),
          // Вкладка: Задачи
          GroupTasksScreen(group: widget.group),
        ],
      ),
    );
  }
}