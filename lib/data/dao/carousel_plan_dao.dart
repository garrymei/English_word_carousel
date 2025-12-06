import 'package:sqflite/sqflite.dart';
import '../db.dart';
import '../models/carousel_plan.dart';

class CarouselPlanDAO {
  Future<List<CarouselPlan>> listAll({String? userId}) async {
    final db = await AppDatabase.instance.database;
    final where = userId == null ? null : 'user_id = ?';
    final args = userId == null ? null : [userId];
    final rows = await db.query('carousel_plans', where: where, whereArgs: args, orderBy: 'updated_at DESC');
    return rows.map((m) => CarouselPlan(
      id: (m['id'] as String?) ?? '',
      name: (m['name'] as String?) ?? '',
      userId: m['user_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch((m['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((m['updated_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
    )).toList();
  }

  Future<void> upsert(CarouselPlan plan) async {
    final db = await AppDatabase.instance.database;
    await db.insert('carousel_plans', plan.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    // Skip local association writes; remote plan_words is the source of truth
  }

  Future<void> delete(String planId) async {
    final db = await AppDatabase.instance.database;
    // Ensure associations are removed even if foreign_keys PRAGMA is off
    await db.transaction((txn) async {
      await txn.delete('carousel_plan_words', where: 'plan_id = ?', whereArgs: [planId]);
      await txn.delete('carousel_plans', where: 'id = ?', whereArgs: [planId]);
    });
  }

  Future<List<String>> getWords(String planId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('carousel_plan_words', columns: ['word_id'], where: 'plan_id = ?', whereArgs: [planId]);
    return rows.map((m) => (m['word_id'] as String?) ?? '').where((id) => id.isNotEmpty).toList();
  }

  Future<void> setWords(String planId, List<String> wordIds) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.delete('carousel_plan_words', where: 'plan_id = ?', whereArgs: [planId]);
      for (final id in wordIds.toSet()) {
        try {
          final exists = Sqflite.firstIntValue(await txn.rawQuery(
            'SELECT COUNT(1) FROM word_cards WHERE id = ?',
            [id],
          )) ?? 0;
          if (exists == 0) {
            // Skip missing local word to avoid FK violation; remote plan_words will be authoritative
            continue;
          }
          await txn.insert('carousel_plan_words', {
            'plan_id': planId,
            'word_id': id,
          });
        } catch (_) {
          // Ignore per-row errors to avoid failing the whole transaction
        }
      }
    });
  }
}