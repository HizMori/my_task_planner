import 'package:flutter/material.dart';

class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: theme.primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Чат группы',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.primaryColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Чат будет доступен в следующем обновлении',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Функция в разработке'),
            ),
          );
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(
          Icons.message,
          color: Colors.white,
        ),
      ),
    );
  }
}
