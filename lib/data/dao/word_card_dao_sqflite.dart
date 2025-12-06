import 'package:sqflite/sqflite.dart';
import '../db.dart';
import '../models/word_card.dart';
import 'word_card_dao.dart';

class WordCardDAOSqflite implements WordCardDAO {
  @override
  Future<void> insertWord(WordCard w) async {
    final db = await AppDatabase.instance.database;
    await db.insert('word_cards', w.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateWord(WordCard w) async {
    final db = await AppDatabase.instance.database;
    w.updatedAt = DateTime.now();
    await db.update('word_cards', w.toDbMap(), where: 'id = ?', whereArgs: [w.id]);
  }

  @override
  Future<void> deleteWord(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('word_cards', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteWordsByIds(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      final placeholders = List.filled(ids.length, '?').join(',');
      await txn.delete('word_card_tags', where: 'word_id IN ($placeholders)', whereArgs: ids);
      await txn.delete('word_cards', where: 'id IN ($placeholders)', whereArgs: ids);
    });
  }

  @override
  Future<WordCard?> findById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('word_cards', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return WordCard.fromDbMap(rows.first);
  }

  @override
  Future<List<WordCard>> list({List<String>? tagIds, bool? onlyEnabled, String? userId, bool personalOnly = false}) async {
    final db = await AppDatabase.instance.database;
    final enableClause = (onlyEnabled == true) ? ' AND wc.enabled = 1' : '';

    if (tagIds == null || tagIds.isEmpty) {
      final whereUser = userId == null
          ? 'wc.user_id IS NULL'
          : (personalOnly ? 'wc.user_id = ?' : '(wc.user_id IS NULL OR wc.user_id = ?)');
      final rows = await db.rawQuery(
          'SELECT * FROM word_cards wc WHERE $whereUser$enableClause ORDER BY wc.updated_at DESC',
          userId == null ? [] : [userId]);
      return rows.map((e) => WordCard.fromDbMap(e)).toList();
    }

    final placeholders = List.filled(tagIds.length, '?').join(',');
    final whereUser = userId == null
        ? 'wc.user_id IS NULL'
        : (personalOnly ? 'wc.user_id = ?' : '(wc.user_id IS NULL OR wc.user_id = ?)');
    final sql = '''
SELECT wc.* FROM word_cards wc
JOIN word_card_tags wct ON wc.id = wct.word_id
WHERE $whereUser AND wct.tag_id IN ($placeholders)$enableClause
GROUP BY wc.id
HAVING COUNT(DISTINCT wct.tag_id) = ?
ORDER BY wc.updated_at DESC
''';
    final args = userId == null ? [...tagIds, tagIds.length] : [userId, ...tagIds, tagIds.length];
    final rows = await db.rawQuery(sql, args);
    return rows.map((e) => WordCard.fromDbMap(e)).toList();
  }
}