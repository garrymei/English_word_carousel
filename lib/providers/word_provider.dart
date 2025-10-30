import 'package:flutter/foundation.dart';
import '../data/models/word_card.dart';
import '../data/repositories/word_repository.dart';

class WordProvider extends ChangeNotifier {
  final _repo = WordRepository();
  List<WordCard> words = [];
  bool loading = false;

  Future<void> loadWords({List<String>? tagIds, bool? onlyEnabled}) async {
    loading = true;
    notifyListeners();
    words = await _repo.list(tagIds: tagIds, onlyEnabled: onlyEnabled);
    loading = false;
    notifyListeners();
  }

  Future<void> createWord(WordCard w) async {
    await _repo.create(w);
    await loadWords();
  }

  Future<void> updateWord(WordCard w) async {
    await _repo.update(w);
    await loadWords();
  }

  Future<void> deleteWord(String id) async {
    await _repo.delete(id);
    await loadWords();
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
    await loadWords();
    return count;
  }
}