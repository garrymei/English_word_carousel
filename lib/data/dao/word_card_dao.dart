import '../models/word_card.dart';

abstract class WordCardDAO {
  Future<void> insertWord(WordCard w);
  Future<void> updateWord(WordCard w);
  Future<void> deleteWord(String id);
  Future<void> deleteWordsByIds(List<String> ids);
  Future<WordCard?> findById(String id);
  Future<List<WordCard>> list({List<String>? tagIds, bool? onlyEnabled, String? userId, bool personalOnly = false});
}
