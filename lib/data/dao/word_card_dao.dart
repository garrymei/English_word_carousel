import 'package:sqflite/sqflite.dart';
import '../db.dart';
import '../models/word_card.dart';

class WordCardDAO {
  Future<void> insertWord(WordCard w) async {
    final db = await AppDatabase.instance.database;
    await db.insert('word_cards', w.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateWord(WordCard w) async {
    final db = await AppDatabase.instance.database;
    w.updatedAt = DateTime.now();
    await db.update('word_cards', w.toDbMap(), where: 'id = ?', whereArgs: [w.id]);
  }

  Future<void> deleteWord(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('word_cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<WordCard?> findById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('word_cards', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return WordCard.fromDbMap(rows.first);
  }

  Future<List<WordCard>> list({List<String>? tagIds, bool? onlyEnabled}) async {
    final db = await AppDatabase.instance.database;
    final enableClause = (onlyEnabled == true) ? ' AND enabled = 1' : '';

    if (tagIds == null || tagIds.isEmpty) {
      final rows = await db.rawQuery(
          'SELECT * FROM word_cards WHERE 1=1$enableClause ORDER BY updated_at DESC');
      return rows.map((e) => WordCard.fromDbMap(e)).toList();
    }

    final placeholders = List.filled(tagIds.length, '?').join(',');
    final sql = '''
SELECT wc.* FROM word_cards wc
JOIN word_card_tags wct ON wc.id = wct.word_id
WHERE wct.tag_id IN ($placeholders)$enableClause
GROUP BY wc.id
HAVING COUNT(DISTINCT wct.tag_id) = ?
ORDER BY wc.updated_at DESC
''';
    final rows = await db.rawQuery(sql, [...tagIds, tagIds.length]);
    return rows.map((e) => WordCard.fromDbMap(e)).toList();
  }
}