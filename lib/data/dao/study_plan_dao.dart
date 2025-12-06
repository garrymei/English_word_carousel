import 'package:sqflite/sqflite.dart';
import '../db.dart';
import '../models/study_plan.dart';
import 'study_plan_dao_base.dart';

class StudyPlanDAO implements StudyPlanDAOBase {
  @override
  Future<StudyPlan?> getByUserId(String userId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('study_plans', where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (rows.isEmpty) return null;
    return StudyPlan.fromDbMap(rows.first);
  }

  @override
  Future<void> upsert(StudyPlan plan) async {
    final db = await AppDatabase.instance.database;
    await db.insert('study_plans', plan.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> markCompletedToday(String userId, {required bool completed}) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update('study_plans', {
      'completed_today': completed ? 1 : 0,
      'updated_at': now,
    }, where: 'user_id = ?', whereArgs: [userId]);
  }
}
