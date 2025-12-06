import 'package:flutter/foundation.dart';
import '../dao/tag_dao_base.dart';
import '../dao/tag_dao.dart';
import '../dao/tag_dao_web.dart';
import '../models/tag.dart';

class TagRepository {
  final TagDAOBase _dao = kIsWeb ? TagDAOWeb() : TagDAO();
  List<Tag>? _cache;

  Future<List<Tag>> listAll({bool forceRefresh = false, String? userId}) async {
    if (_cache != null && !forceRefresh) return _cache!;
    _cache = await _dao.listAll(userId: userId);
    return _cache!;
  }

  Future<Tag?> findById(String id) => _dao.findById(id);

  Future<void> create(Tag t) async {
    await _dao.insertTag(t);
    _cache = null;
  }

  Future<void> update(Tag t) async {
    await _dao.updateTag(t);
    _cache = null;
  }

  Future<void> upsert(Tag t) async {
    final existing = await _dao.findById(t.id);
    if (existing == null) {
      await _dao.insertTag(t);
    } else {
      await _dao.updateTag(t);
    }
    _cache = null;
  }

  Future<void> delete(String id) async {
    await _dao.deleteTag(id);
    _cache = null;
  }

  Future<void> setTagsForWord(String wordId, List<String> tagIds) async {
    await _dao.setTagsForWord(wordId, tagIds);
  }

  Future<List<Tag>> listByWord(String wordId) async {
    return _dao.listByWord(wordId);
  }
}