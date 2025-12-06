import '../models/tag.dart';

abstract class TagDAOBase {
  Future<void> insertTag(Tag t);
  Future<void> updateTag(Tag t);
  Future<void> deleteTag(String id);
  Future<List<Tag>> listAll({String? userId});
  Future<Tag?> findById(String id);
  Future<void> setTagsForWord(String wordId, List<String> tagIds);
  Future<List<Tag>> listByWord(String wordId);
}