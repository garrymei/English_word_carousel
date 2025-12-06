import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../core/validators.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _svc;
  AuthUser? currentUser;
  String? token; // stored in secure storage, cached here for convenience
  bool initializing = true;

  AuthProvider({AuthService? service}) : _svc = service ?? AuthService() {
    _bootstrap();
  }

  bool get isLoggedIn => token != null;

  Future<void> loadToken() async {
    await _bootstrap();
  }

  Future<void> _bootstrap() async {
    print('AuthProvider: Starting _bootstrap');
    try {
      token = await _svc.getStoredToken();
      print('AuthProvider: Loaded token: ${token != null ? 'exists' : 'null'}');

      if (token == null || token!.isEmpty) {
        currentUser = null;
        token = null;
      } else {
        final ok = await _svc.verifyToken();
        print('AuthProvider: Token verification: $ok');
        if (!ok) {
          await _svc.clearToken();
          currentUser = null;
          token = null;
        } else {
          currentUser = await _svc.me();
          print('AuthProvider: Loaded currentUser: ${currentUser?.id}');
        }
      }
    } catch (e) {
      print('AuthProvider: Error in _bootstrap: $e');
      currentUser = null;
      token = null;
    } finally {
      initializing = false;
      print('AuthProvider: Bootstrap completed, userId: ${currentUser?.id}, isLoggedIn: $isLoggedIn');
      notifyListeners();
    }
  }

  Future<void> register(String email, String username, String password) async {
    // 统一用户名大小写（后端按不区分大小写唯一）
    final normalizedUsername = username.trim().toLowerCase();
    final user = await _svc.register(email: email.trim(), username: normalizedUsername, password: password.trim());
    currentUser = user;
    token = await _svc.getStoredToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', user.username ?? '');
    notifyListeners();
  }

  Future<void> login(String identifier, String password) async {
    // 邮箱保持原样；用户名统一为小写以支持不区分大小写登录
    final id = Validators.isEmail(identifier.trim()) ? identifier.trim() : identifier.trim().toLowerCase();
    try {
      final user = await _svc.login(usernameOrEmail: id, password: password.trim());
      currentUser = user;
      token = await _svc.getStoredToken();
    } catch (e) {
      rethrow;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', currentUser!.username ?? '');
    notifyListeners();
  }

  Future<void> logout() async {
    await _svc.logout(); // Updated to call logout in AuthService
    currentUser = null;
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    notifyListeners();
  }

  // 为避免“用户名与内部ID不一致”导致 Supabase 绑定错位，
  // 统一使用后端内部 ID 作为用户标识（与 word_cards.user_id 对齐）。
  String? get userId => currentUser?.id;
}