import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabase_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('supabase_token');
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('supabase_token');
  }

  Future<void> saveCurrentUserId(String userId) async {  // Новый: хранит ID из users таблицы
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_id');
  }

  Future<void> deleteCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }

  Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await getToken();
    if (token == null) return false;

    // Дополнительно можно проверить сессию
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    return session != null;
  }

  Future<bool> syncCurrentUser() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.auth.getUser();
      final supabaseUser = response.user;
      if (supabaseUser == null) return true; // нет пользователя

      final userResponse = await supabase
          .from('users')
          .select()
          .eq('id', supabaseUser.id)
          .single();

      if (userResponse['deleted_at'] != null) {
        // ✅ Помечаем, что аккаунт удалён, и выходим
        await supabase.auth.signOut();
        await deleteToken();
        await deleteCurrentUserId();
        await setLoggedIn(false);

        return false; // ❌ Аккаунт удалён
      }

      // Синхронизируем данные
      await DatabaseService.instance.syncUserFromSupabase(userResponse);
      await DatabaseService.instance.syncGroupsFromSupabase();
      await DatabaseService.instance.syncGroupMembersFromSupabase();
      await DatabaseService.instance.syncTasksFromSupabase();

      return true; // ✅ Успешно
    } catch (e) {
      print('Ошибка синхронизации пользователя: $e');
      return false;
    }
  }
}