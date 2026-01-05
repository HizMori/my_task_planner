import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;
    // Проверь валидность токена (опционально, Supabase проверит при запросах)
    // Можно добавить проверку валидности сессии
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    return session != null;
  }
}