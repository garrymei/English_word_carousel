import 'package:flutter/foundation.dart';
import '../data/models/word_card.dart';
import '../data/repositories/word_repository.dart';
import '../services/word_cards_supabase_service.dart';
import '../services/supabase_service.dart';

class WordProvider extends ChangeNotifier {
  final _repo = WordRepository();
  List<WordCard> words = [];
  bool loading = false;
  List<String>? _lastTagFilter;
  bool? _lastOnlyEnabled;
  String? _lastUserId;
  bool? _lastPersonalOnly;

  Future<void> loadWords({List<String>? tagIds, bool? onlyEnabled, String? userId, bool personalOnly = true, bool skipDb = false}) async {
    loading = true;
    notifyListeners();

    if (skipDb && words.isNotEmpty) {
      loading = false;
      notifyListeners();
      return;
    }

    // Cache the latest filters so subsequent refreshes remain scoped to the same user/context.
    _lastTagFilter = tagIds == null ? null : List<String>.from(tagIds);
    _lastOnlyEnabled = onlyEnabled;
    _lastUserId = userId;
    _lastPersonalOnly = personalOnly;
    try {
      const readRemote = bool.fromEnvironment('SUPABASE_READ_REMOTE', defaultValue: true);
      List<WordCard> remote = const [];
      List<WordCard> local = const [];
      if (readRemote && SupabaseService.isInitialized) {
        remote = await WordCardsSupabaseService.fetchAll(
          limit: 200,
          onlyEnabled: onlyEnabled,
          userId: userId,
          personalOnly: personalOnly,
        );
        debugPrint('WordProvider: remote fetched ${remote.length} rows (onlyEnabled=$onlyEnabled, userId=$userId)');
      }
      // Always read local to include offline/SQLite data and merge with remote
      local = await _repo.list(tagIds: tagIds, onlyEnabled: onlyEnabled, userId: userId, personalOnly: personalOnly);
      debugPrint('WordProvider: local fetched ${local.length} rows (onlyEnabled=$onlyEnabled, userId=$userId)');

      if (remote.isEmpty) {
        words = local;
      } else if (local.isEmpty) {
        words = remote;
      } else {
        final byId = <String, WordCard>{};
        for (final w in local) {
          byId[w.id] = w;
        }
        for (final w in remote) {
          byId[w.id] = w; // remote overrides
        }
        words = byId.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
      // 当仅查看个人数据时，按单词去重，避免同词不同ID重复显示
      if (personalOnly) {
        final byWord = <String, WordCard>{};
        for (final w in words) {
          final key = w.word.trim().toLowerCase();
          final prev = byWord[key];
          if (prev == null || w.updatedAt.isAfter(prev.updatedAt)) {
            byWord[key] = w;
          }
        }
        words = byWord.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
      debugPrint('WordProvider: merged result ${words.length} rows');
    } catch (e) {
      debugPrint('WordProvider: loadWords error: $e');
      // 在 Web 环境下本地 SQLite 不可用时，避免一直加载转圈
      words = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadWithLastFilters({bool skipDb = false}) async {
    await loadWords(
      tagIds: _lastTagFilter,
      onlyEnabled: _lastOnlyEnabled,
      userId: _lastUserId,
      personalOnly: _lastPersonalOnly ?? false,
      skipDb: skipDb,
    );
  }

  Future<void> createWord(WordCard w) async {
    // 优先尝试远程写入（需在构建时通过 --dart-define SUPABASE_WRITE_REMOTE=true 开启）
    const writeRemote = bool.fromEnvironment('SUPABASE_WRITE_REMOTE', defaultValue: true);
    if (writeRemote && SupabaseService.isInitialized) {
      try {
        final inserted = await WordCardsSupabaseService.createRemote(w);
        if (inserted != null) {
          await _reloadWithLastFilters(skipDb: false); // Refresh from DB/source of truth
          return;
        }
      } catch (_) {
        // 远程失败则回退到本地
      }
    }

    // 本地持久化路径（SQLite/文件），并在 Web 环境做内存兜底
    try {
      await _repo.create(w);
      await _reloadWithLastFilters(skipDb: false); // Force DB reload
    } catch (_) {
      // Web 环境可能不支持本地 DB，进行内存兜底，避免“保存无效”体验
      words.insert(0, w);
      await _reloadWithLastFilters(skipDb: true); // Use memory
    }
  }

  Future<void> updateWord(WordCard w) async {
    try {
      await _repo.update(w);
      await _reloadWithLastFilters(skipDb: false); // Force DB reload
    } catch (_) {
      // Web 环境兜底：直接更新内存中的列表
      final idx = words.indexWhere((e) => e.id == w.id);
      if (idx >= 0) {
        words[idx] = w;
      } else {
        words.insert(0, w);
      }
      await _reloadWithLastFilters(skipDb: true); // Use memory
    }
  }

  Future<void> deleteWord(String id) async {
    try {
      await _repo.delete(id);
    } catch (_) {
      // Web 环境可能不支持本地 DB，忽略错误
    }
    await _reloadWithLastFilters();
  }

  Future<void> deleteMany(List<String> ids) async {
    if (ids.isEmpty) return;
    loading = true;
    notifyListeners();
    try {
      await _repo.deleteMany(ids);
    } catch (_) {
      // Web 环境兜底
    }
    await _reloadWithLastFilters();
  }

  Future<List<WordCard>> findWordsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    const readRemote = bool.fromEnvironment('SUPABASE_READ_REMOTE', defaultValue: true);
    if (readRemote && SupabaseService.isInitialized) {
      try {
        final rows = await WordCardsSupabaseService.fetchByIds(ids);
        return rows;
      } catch (_) {}
    }
    return _repo.findByIds(ids);
  }

  Future<void> toggleEnabled(String wordId, bool enabled) async {
    await _repo.toggleEnabled(wordId, enabled);
    final idx = words.indexWhere((e) => e.id == wordId);
    if (idx >= 0) {
      words[idx].enabled = enabled;
      notifyListeners();
    }
  }

  Future<int> importFromJsonString(String jsonStr) async {
    final count = await _repo.importFromJsonString(jsonStr);
    await _reloadWithLastFilters();
    return count;
  }

  void clear() {
    words = [];
    loading = false;
    notifyListeners();
  }
}
