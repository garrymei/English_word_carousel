import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_card.dart';
import 'word_card_dao.dart';

// Simple Web persistence using SharedPreferences (localStorage)
// Stores entire word list as JSON under a single key.
class WordCardDAOWeb implements WordCardDAO {
  static const _key = 'ewc_words_v1';

  Future<List<WordCard>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => WordCard.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _saveAll(List<WordCard> words) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(words.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  @override
  Future<void> insertWord(WordCard w) async {
    final list = await _loadAll();
    list.removeWhere((e) => e.id == w.id);
    list.insert(0, w);
    await _saveAll(list);
  }

  @override
  Future<void> updateWord(WordCard w) async {
    final list = await _loadAll();
    final idx = list.indexWhere((e) => e.id == w.id);
    if (idx >= 0) {
      list[idx] = w;
    } else {
      list.insert(0, w);
    }
    await _saveAll(list);
  }

  @override
  Future<void> deleteWord(String id) async {
    final list = await _loadAll();
    list.removeWhere((e) => e.id == id);
    await _saveAll(list);
  }

  @override
  Future<void> deleteWordsByIds(List<String> ids) async {
    if (ids.isEmpty) return;
    final list = await _loadAll();
    list.removeWhere((e) => ids.contains(e.id));
    await _saveAll(list);
  }

  @override
  Future<WordCard?> findById(String id) async {
    final list = await _loadAll();
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WordCard>> list({List<String>? tagIds, bool? onlyEnabled, String? userId, bool personalOnly = false}) async {
    var list = await _loadAll();
    if (onlyEnabled == true) {
      list = list.where((e) => e.enabled).toList();
    }
    // Include shared (userId == null) and personal (userId == current) cards
    if (userId == null) {
      list = list.where((e) => e.userId == null).toList();
    } else {
      list = personalOnly
          ? list.where((e) => e.userId == userId).toList()
          : list.where((e) => e.userId == null || e.userId == userId).toList();
    }
    if (tagIds != null && tagIds.isNotEmpty) {
      final set = tagIds.toSet();
      list = list.where((e) => e.tagIds.toSet().containsAll(set)).toList();
    }
    // Sort by updatedAt desc
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }
}
