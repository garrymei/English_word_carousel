import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/db.dart';
import '../data/repositories/word_repository.dart';

class SyncService {
  final String baseUrl;
  final WordRepository wordRepo;
  SyncService({
    String? baseUrlParam,
    WordRepository? wordRepo,
  })
      : baseUrl = baseUrlParam ??
            const String.fromEnvironment(
              'SYNC_BASE_URL',
              defaultValue: 'https://example.com',
            ),
        wordRepo = wordRepo ?? WordRepository(),
        assert(baseUrl.isNotEmpty) {
    _ensureSecure();
  }

  static const _kSyncEnabled = 'sync_enabled';
  static const _kLastSyncAt = 'last_sync_at';

  void _ensureSecure() {
    final uri = Uri.parse(baseUrl);
    final isLocalhost = uri.host == 'localhost' || uri.host == '127.0.0.1';
    if (!isLocalhost && uri.scheme != 'https') {
      throw Exception('非本地环境必须使用 HTTPS 接口: $baseUrl');
    }
  }

  Future<bool> syncEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kSyncEnabled) ?? true;
  }

  Future<void> setSyncEnabled(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSyncEnabled, enabled);
  }

  Future<DateTime?> lastSyncAt() async {
    final p = await SharedPreferences.getInstance();
    final ts = p.getInt(_kLastSyncAt);
    return ts == null ? null : DateTime.fromMillisecondsSinceEpoch(ts);
  }

  Future<void> setLastSyncAt(DateTime dt) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLastSyncAt, dt.millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>> downloadRemote(String token) async {
    final uri = Uri.parse('$baseUrl/sync/download');
    final resp = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (resp.statusCode != 200) throw Exception('下载同步数据失败: ${resp.statusCode}');
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<void> uploadLocal(String token, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/sync/upload');
    final resp = await http.post(uri,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(payload));
    if (resp.statusCode != 200) throw Exception('上传同步数据失败: ${resp.statusCode}');
  }

  Future<Map<String, dynamic>> collectAllLocal() async {
    final db = await AppDatabase.instance.database;
    final words = await db.query('word_cards');
    final tags = await db.query('tags');
    return {
      'words': words,
      'tags': tags,
    };
  }

  Future<List<Map<String, dynamic>>> collectLocalChangesSince(DateTime since) async {
    final db = await AppDatabase.instance.database;
    final rowsWords = await db.query('word_cards', where: 'updated_at > ?', whereArgs: [since.millisecondsSinceEpoch]);
    final rowsTags = await db.query('tags', where: 'created_at > ?', whereArgs: [since.millisecondsSinceEpoch]);
    final changes = <Map<String, dynamic>>[];
    for (final r in rowsWords) {
      changes.add({
        'entity': 'word_card',
        'action': 'update',
        'data': r,
      });
    }
    for (final r in rowsTags) {
      changes.add({
        'entity': 'tag',
        'action': 'update',
        'data': r,
      });
    }
    return changes;
  }
}