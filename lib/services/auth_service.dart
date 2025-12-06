import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../core/validators.dart';

class AuthUser {
  final String id;
  final String email;
  final String? username; // Make username optional if not always present
  AuthUser({required this.id, required this.email, this.username});
  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id: j['id'].toString(),
    email: (j['email'] ?? '').toString(),
    username: (j['username'] ?? '').toString(),
  );
  factory AuthUser.fromSupabase(supa.User user) => AuthUser(
    id: user.id,
    email: user.email ?? '',
    username: user.userMetadata?['username'], // Prefer metadata when available
  );
}

class AuthException implements Exception {
  final int status;
  final String message;
  AuthException(this.status, this.message);
  @override
  String toString() => message;
}

class AuthService {
  static const _tokenKey = 'auth_token';
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  AuthService();

  // Normalize username: treat empty or literal 'null' as invalid
  String? _normalizeUsername(String? raw, {String? email}) {
    final s = raw?.toString().trim();
    final isInvalid = s == null || s.isEmpty || s.toLowerCase() == 'null';
    if (!isInvalid) return s;
    final e = (email ?? '').trim();
    if (e.isNotEmpty) return e.split('@').first;
    return null;
  }

  Future<String?> getStoredToken() async {
    return await _secure.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _secure.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _secure.delete(key: _tokenKey);
  }

  Future<AuthUser> register({required String email, required String username, required String password}) async {
    try {
      final response = await supa.Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username}, // Store username in user metadata
      );
      await saveToken(response.session?.accessToken ?? '');
      return AuthUser.fromSupabase(response.user!);
    } catch (e) {
      throw AuthException(500, '注册失败: $e');
    }
  }

  Future<AuthUser> login({required String usernameOrEmail, required String password}) async {
    try {
      final email = await _resolveEmail(usernameOrEmail.trim());
      final response = await supa.Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('Login successful: User ID ${response.user?.id}');
      await saveToken(response.session?.accessToken ?? '');
      // Build user with username fallback from profiles/users if metadata missing
      final u = response.user!;
      String? username;
      // First try metadata, but normalize invalid values like 'null'
      username = _normalizeUsername(u.userMetadata?['username'], email: u.email);
      // If still invalid, try tables and normalize
      if (username == null) {
        final emailForLookup = u.email ?? '';
        if (emailForLookup.isNotEmpty) {
          final tableUsername = await _resolveUsernameByEmail(emailForLookup);
          username = _normalizeUsername(tableUsername, email: u.email);
        }
      }

      // Sync back to auth metadata if missing
      try {
        final currentMeta = u.userMetadata ?? {};
        final hasUsernameMeta = (currentMeta['username'] is String) &&
            (currentMeta['username'] as String).trim().isNotEmpty &&
            (currentMeta['username'] as String).toLowerCase() != 'null';
        if (!hasUsernameMeta && (username != null && username!.isNotEmpty)) {
          await supa.Supabase.instance.client.auth.updateUser(
            supa.UserAttributes(data: {'username': username}),
          );
        }
      } catch (_) {
        // ignore metadata update failures
      }
      return AuthUser(id: u.id, email: u.email ?? '', username: username);
    } catch (e) {
      print('Login error: $e');
      throw AuthException(500, '登录失败: $e');
    }
  }

  Future<String> _resolveEmail(String identifier) async {
    if (Validators.isEmail(identifier)) return identifier;
    final normalized = identifier.toLowerCase();
    final client = supa.Supabase.instance.client;

    // Primary lookup: Supabase Auth profiles table (if present).
    final profileEmail = await _fetchEmailFromTable(client, 'profiles', normalized);
    if (profileEmail != null && profileEmail.isNotEmpty) {
      return profileEmail;
    }

    // Fallback lookup: custom public.users table used by legacy auth.
    final userEmail = await _fetchEmailFromTable(client, 'users', normalized);
    if (userEmail != null && userEmail.isNotEmpty) {
      return userEmail;
    }

    throw AuthException(400, '用户名不存在');
  }

  // Resolve username when we only have email
  Future<String?> _resolveUsernameByEmail(String email) async {
    final client = supa.Supabase.instance.client;
    final profileUsername = await _fetchUsernameFromTable(client, 'profiles', email);
    if (profileUsername != null && profileUsername.isNotEmpty) {
      return profileUsername;
    }
    final userUsername = await _fetchUsernameFromTable(client, 'users', email);
    return userUsername;
  }

  Future<String?> _fetchEmailFromTable(
    supa.SupabaseClient client,
    String table,
    String username,
  ) async {
    try {
      final rows = await client
          .from(table)
          .select('email')
          .eq('username', username)
          .limit(1);
      if (rows is List && rows.isNotEmpty) {
        final email = rows.first['email'];
        if (email is String && email.isNotEmpty) {
          return email;
        }
      }
    } catch (err) {
      // Ignore table not found / permission errors and continue to next fallback.
    }
    return null;
  }

  Future<AuthUser?> me() async {
    final token = await getStoredToken();
    if (token == null || token.isEmpty) return null;
    final user = supa.Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    final client = supa.Supabase.instance.client;
    String? username;
    // Normalize metadata username first
    username = _normalizeUsername(user.userMetadata?['username'], email: user.email);
    // If still invalid, resolve from tables and normalize
    if (username == null) {
      final email = user.email ?? '';
      if (email.isNotEmpty) {
        final tableUsername = await _resolveUsernameByEmail(email);
        username = _normalizeUsername(tableUsername, email: user.email);
      }
    }

    // Sync back to metadata if still missing
    try {
      final currentMeta = user.userMetadata ?? {};
      final hasUsernameMeta = (currentMeta['username'] is String) &&
          (currentMeta['username'] as String).trim().isNotEmpty &&
          (currentMeta['username'] as String).toLowerCase() != 'null';
      if (!hasUsernameMeta && (username != null && username!.isNotEmpty)) {
        await client.auth.updateUser(
          supa.UserAttributes(data: {'username': username}),
        );
      }
    } catch (_) {
      // ignore
    }
    return AuthUser(id: user.id, email: user.email ?? '', username: username);
  }

  Future<bool> verifyToken() async {
    final token = await getStoredToken();
    return token != null && supa.Supabase.instance.client.auth.currentSession != null;
  }

  Future<void> logout() async {
    await supa.Supabase.instance.client.auth.signOut();
    await clearToken();
  }

  // Helpers for table lookups
  Future<String?> _fetchUsernameFromTable(supa.SupabaseClient client, String table, String email) async {
    try {
      final res = await client.from(table).select('username').eq('email', email).limit(1);
      if (res is List && res.isNotEmpty) {
        final v = res.first['username'];
        if (v is String) {
          final s = v.trim();
          if (s.isNotEmpty && s.toLowerCase() != 'null') {
            return s;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}