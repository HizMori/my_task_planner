import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../services/database_service.dart';

class UserAvatar extends StatelessWidget {
  final User user;
  final double radius;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 20,
  });

  Future<String?> _fetchAvatarUrl(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();
      
      if (response == null) {
        return null;
      }

      final avatarUrl = response['avatar_url'] as String?;
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        // Обновим локально при возможности
        final updatedUser = user.copyWith(avatarUrl: avatarUrl);
        await DatabaseService.instance.updateUser(updatedUser);
      }
      return avatarUrl;
    } catch (e) {
      print('Error fetching avatarUrl: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user.avatarUrl != null) {
      return CachedNetworkImage(
        imageUrl: user.avatarUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF7e61f3).withOpacity(0.15),
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF7e61f3).withOpacity(0.15),
          child: SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7e61f3)),
            ),
          ),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF7e61f3).withOpacity(0.15),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: const Color(0xFF7e61f3),
              fontWeight: FontWeight.bold,
              fontSize: radius,
            ),
          ),
        ),
      );
    }

    // Если avatarUrl == null → пробуем подгрузить динамически
    return FutureBuilder<String?>(
      future: _fetchAvatarUrl(user.id),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: CachedNetworkImageProvider(snapshot.data!),
          );
        }

        // Fallback на первую букву
        return CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF7e61f3).withOpacity(0.15),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: const Color(0xFF7e61f3),
              fontWeight: FontWeight.bold,
              fontSize: radius,
            ),
          ),
        );
      },
    );
  }
}
