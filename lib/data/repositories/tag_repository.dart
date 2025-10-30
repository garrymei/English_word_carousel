import '../dao/tag_dao.dart';
import '../models/tag.dart';

class TagRepository {
  final _dao = TagDAO();
  List<Tag>? _cache;

  Future<List<Tag>> listAll({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) return _cache!;
    _cache = await _dao.listAll();
    return _cache!;
  }

  Future<void> create(Tag t) async {
    await _dao.insertTag(t);
    _cache = null;
  }

  Future<void> update(Tag t) async {
    await _dao.updateTag(t);
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