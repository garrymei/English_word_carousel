import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tag.dart';
import '../models/word_card.dart';
import 'word_card_dao_web.dart';
import 'tag_dao_base.dart';

// Web 端标签持久化，使用 SharedPreferences（localStorage）
// - 标签以 JSON 数组保存在一个键下
// - 关联关系在 Web 端不使用链接表，直接存于 WordCard.tagIds
class TagDAOWeb implements TagDAOBase {
  static const _key = 'ewc_tags_v1';

  Future<List<Tag>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Tag.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _saveAll(List<Tag> tags) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(tags.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  Future<void> insertTag(Tag t) async {
    final list = await _loadAll();
    list.removeWhere((e) => e.id == t.id);
    list.insert(0, t);
    await _saveAll(list);
  }

  Future<void> updateTag(Tag t) async {
    final list = await _loadAll();
    final idx = list.indexWhere((e) => e.id == t.id);
    if (idx >= 0) {
      list[idx] = t;
    } else {
      list.insert(0, t);
    }
    await _saveAll(list);
  }

  Future<void> deleteTag(String id) async {
    final list = await _loadAll();
    list.removeWhere((e) => e.id == id);
    await _saveAll(list);
  }

  Future<List<Tag>> listAll({String? userId}) async {
    var list = await _loadAll();
    // 与原生实现保持一致：
    // - userId == null -> 仅返回公共标签（userId 为 null）
    // - userId != null -> 仅返回该用户的个人标签
    if (userId == null) {
      list = list.where((e) => e.userId == null).toList();
    } else {
      list = list.where((e) => e.userId == userId).toList();
    }
    // 按创建时间倒序（与 DB 行为尽量一致）
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<Tag?> findById(String id) async {
    final list = await _loadAll();
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // Web: 将标签与单词的关联直接写入 WordCard.tagIds
  Future<void> setTagsForWord(String wordId, List<String> tagIds) async {
    final wdao = WordCardDAOWeb();
    final w = await wdao.findById(wordId);
    if (w == null) return;
    final updated = WordCard(
      id: w.id,
      word: w.word,
      chinese: w.chinese,
      phonetic: w.phonetic,
      phrase: w.phrase,
      phraseCn: w.phraseCn,
      sentenceEn: w.sentenceEn,
      sentenceCn: w.sentenceCn,
      enabled: w.enabled,
      tagIds: tagIds,
      userId: w.userId,
      createdAt: w.createdAt,
      updatedAt: DateTime.now(),
      relatedEnabled: w.relatedEnabled,
      related: w.related,
    );
    await wdao.updateWord(updated);
  }

  // Web: 通过 WordCard.tagIds 找到对应的标签对象
  Future<List<Tag>> listByWord(String wordId) async {
    final wdao = WordCardDAOWeb();
    final w = await wdao.findById(wordId);
    if (w == null) return [];
    final tags = await _loadAll();
    final set = w.tagIds.toSet();
    return tags.where((t) => set.contains(t.id)).toList();
  }
}