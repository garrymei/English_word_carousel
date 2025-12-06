import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase using compile-time environment defines.
  /// If `SUPABASE_URL` or `SUPABASE_ANON_KEY` are missing, initialization is skipped.
  static Future<void> init() async {
    if (_initialized) return;
    // 1) 优先使用编译期 dart-define
    const urlDefine = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    const anonKeyDefine = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

    String url = urlDefine;
    String anonKey = anonKeyDefine;
    String source = '';

    // 2) 若未提供 define，则尝试从本地 assets/config/supabase.json 读取
    if (url.isEmpty || anonKey.isEmpty) {
      final fromAsset = await _loadFromAsset();
      if (fromAsset != null) {
        url = fromAsset.$1;
        anonKey = fromAsset.$2;
        source = 'asset';
      }
    }

    // 标记来源
    if (source.isEmpty && urlDefine.isNotEmpty && anonKeyDefine.isNotEmpty) {
      source = 'dart-define';
    }

    if (url.isEmpty || anonKey.isEmpty) {
      // 未配置 Supabase，跳过初始化，应用可继续使用本地存储。
      if (kDebugMode) {
        debugPrint('Supabase 未初始化：未检测到 SUPABASE_URL/ANON_KEY 或配置文件');
      }
      return;
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
    _initialized = true;
    if (kDebugMode) {
      debugPrint('Supabase 已初始化，source=$source, url=$url');
    }
  }

  /// 从 assets 配置文件读取 Supabase url 与 anon key。
  /// 配置文件路径可通过 `SUPABASE_CONFIG_PATH` dart-define 覆盖，默认 `assets/config/supabase.json`。
  static Future<(String, String)?> _loadFromAsset() async {
    const configPath = String.fromEnvironment(
      'SUPABASE_CONFIG_PATH',
      defaultValue: 'assets/config/supabase.json',
    );
    try {
      final raw = await rootBundle.loadString(configPath);
      final jsonMap = json.decode(raw);
      if (jsonMap is Map) {
        final url = (jsonMap['url'] ?? jsonMap['SUPABASE_URL'] ?? '').toString();
        final anon = (jsonMap['anonKey'] ?? jsonMap['SUPABASE_ANON_KEY'] ?? '').toString();
        if (url.isNotEmpty && anon.isNotEmpty) {
          return (url, anon);
        }
      }
      if (kDebugMode) {
        debugPrint('Supabase 配置文件存在但内容缺失：$configPath');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('读取 Supabase 配置文件失败 ($configPath)：$e');
      }
    }
    return null;
  }
}