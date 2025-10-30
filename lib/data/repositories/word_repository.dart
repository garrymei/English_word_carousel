import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../dao/word_card_dao.dart';
import '../dao/tag_dao.dart';
import '../models/word_card.dart';

class WordRepository {
  final _dao = WordCardDAO();
  final _tagDao = TagDAO();
  final _uuid = const Uuid();

  Future<List<WordCard>> list({List<String>? tagIds, bool? onlyEnabled}) async {
    final words = await _dao.list(tagIds: tagIds, onlyEnabled: onlyEnabled);
    // hydrate tagIds
    for (final w in words) {
      final tags = await _tagDao.listByWord(w.id);
      w.tagIds = tags.map((e) => e.id).toList();
    }
    return words;
  }

  Future<void> create(WordCard w) async {
    await _dao.insertWord(w);
    await _tagDao.setTagsForWord(w.id, w.tagIds);
  }

  Future<void> update(WordCard w) async {
    await _dao.updateWord(w);
    await _tagDao.setTagsForWord(w.id, w.tagIds);
  }

  Future<void> delete(String id) async {
    await _dao.deleteWord(id);
  }

  Future<void> toggleEnabled(String id, bool enabled) async {
    final w = await _dao.findById(id);
    if (w == null) return;
    w.enabled = enabled;
    await _dao.updateWord(w);
  }

  // Import/Export via JSON strings (web-friendly)
  Future<int> importFromJsonString(String jsonStr) async {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    int count = 0;
    for (final item in list) {
      final j = Map<String, dynamic>.from(item);
      final id = j['id'] ?? _uuid.v4();
      final w = WordCard.fromJson({...j, 'id': id});
      await create(w);
      count++;
    }
    return count;
  }

  Future<String> exportToJsonString(List<WordCard> words) async {
    return jsonEncode(words.map((e) => e.toJson()).toList());
  }
}