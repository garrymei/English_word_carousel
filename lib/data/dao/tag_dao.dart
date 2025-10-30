import 'package:sqflite/sqflite.dart';
import '../db.dart';
import '../models/tag.dart';

class TagDAO {
  Future<void> insertTag(Tag t) async {
    final db = await AppDatabase.instance.database;
    await db.insert('tags', t.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTag(Tag t) async {
    final db = await AppDatabase.instance.database;
    await db.update('tags', t.toDbMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTag(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Tag>> listAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('tags', orderBy: 'created_at DESC');
    return rows.map((e) => Tag.fromDbMap(e)).toList();
  }

  Future<void> setTagsForWord(String wordId, List<String> tagIds) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.delete('word_card_tags', where: 'word_id = ?', whereArgs: [wordId]);
      for (final tid in tagIds) {
        await txn.insert('word_card_tags', {
          'word_id': wordId,
          'tag_id': tid,
        });
      }
    });
  }

  Future<List<Tag>> listByWord(String wordId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
SELECT t.* FROM tags t
JOIN word_card_tags wct ON t.id = wct.tag_id
WHERE wct.word_id = ?
ORDER BY t.created_at DESC
''', [wordId]);
    return rows.map((e) => Tag.fromDbMap(e)).toList();
  }
}