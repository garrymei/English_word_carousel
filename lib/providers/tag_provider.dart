import 'package:flutter/foundation.dart';
import '../data/models/tag.dart';
import '../data/repositories/tag_repository.dart';

class TagProvider extends ChangeNotifier {
  final _repo = TagRepository();
  List<Tag> tags = [];

  Future<void> loadTags({bool forceRefresh = false}) async {
    tags = await _repo.listAll(forceRefresh: forceRefresh);
    notifyListeners();
  }

  Future<void> create(Tag t) async {
    await _repo.create(t);
    await loadTags(forceRefresh: true);
  }

  Future<void> update(Tag t) async {
    await _repo.update(t);
    await loadTags(forceRefresh: true);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await loadTags(forceRefresh: true);
  }

  Future<void> setTagsForWord(String wordId, List<String> tagIds) async {
    await _repo.setTagsForWord(wordId, tagIds);
  }
}