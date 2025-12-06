import '../db.dart';
import '../models/study_log.dart';
import 'study_log_dao_base.dart';

class StudyLogDAO implements StudyLogDAOBase {
  Future<void> insert(StudyLog log) async {
    final db = await AppDatabase.instance.database;
    await db.insert('study_logs', log.toDbMap());
  }

  Future<void> insertMany(List<StudyLog> logs) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      for (final l in logs) {
        await txn.insert('study_logs', l.toDbMap());
      }
    });
  }

  @override
  Future<int> countDistinctWordsToday(String? userId) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = start + const Duration(days: 1).inMilliseconds;
    final where = StringBuffer('viewed_at >= ? AND viewed_at < ?');
    final List<Object?> args = [start, end];
    if (userId != null) {
      where.write(' AND user_id = ?');
      args.add(userId);
    }
    final rows = await db.rawQuery(
      'SELECT COUNT(DISTINCT word_id) as cnt FROM study_logs WHERE ${where.toString()}',
      args,
    );
    final v = rows.isEmpty ? 0 : rows.first['cnt'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  @override
  Future<int> countDistinctWordsOn(DateTime day, String? userId) async {
    final db = await AppDatabase.instance.database;
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = start + const Duration(days: 1).inMilliseconds;
    final where = StringBuffer('viewed_at >= ? AND viewed_at < ?');
    final List<Object?> args = [start, end];
    if (userId != null) {
      where.write(' AND user_id = ?');
      args.add(userId);
    }
    final rows = await db.rawQuery(
      'SELECT COUNT(DISTINCT word_id) as cnt FROM study_logs WHERE ${where.toString()}',
      args,
    );
    final v = rows.isEmpty ? 0 : rows.first['cnt'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  Future<int?> lastViewedAtForWord(String wordId, String? userId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      'SELECT MAX(viewed_at) AS ts FROM study_logs WHERE word_id = ? AND (user_id IS NULL OR user_id = ?)',
      [wordId, userId],
    );
    final ts = rows.first['ts'] as int?;
    return ts;
  }
}
