import 'package:flutter/foundation.dart';
import '../data/models/tag.dart';
import '../data/repositories/tag_repository.dart';

class TagProvider extends ChangeNotifier {
  final _repo = TagRepository();
  List<Tag> tags = [];

  Future<void> loadTags({bool forceRefresh = false, String? userId}) async {
    tags = await _repo.listAll(forceRefresh: forceRefresh, userId: userId);
    notifyListeners();
  }

  Future<void> create(Tag t, {String? userId}) async {
    if (userId != null) {
      t.userId = userId;
    }
    await _repo.create(t);
    await loadTags(forceRefresh: true, userId: userId);
  }

  Future<void> update(Tag t, {String? userId}) async {
    if (userId != null) {
      t.userId = userId;
    }
    await _repo.update(t);
    await loadTags(forceRefresh: true, userId: userId);
  }

  Future<void> delete(String id, {String? userId}) async {
    await _repo.delete(id);
    await loadTags(forceRefresh: true, userId: userId);
  }

  Future<void> setTagsForWord(String wordId, List<String> tagIds) async {
    await _repo.setTagsForWord(wordId, tagIds);
  }

  void clear() {
    tags = [];
    notifyListeners();
  }
}