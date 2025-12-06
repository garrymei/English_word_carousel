import '../data/dao/study_plan_dao.dart';
import '../data/dao/study_log_dao.dart';
import '../data/models/study_plan.dart';
import 'package:flutter/foundation.dart';
import '../data/dao/study_plan_dao_web.dart';
import '../data/dao/study_log_dao_web.dart';
import '../data/dao/study_plan_dao_base.dart';
import '../data/dao/study_log_dao_base.dart';

class StudyPlanService {
  final StudyPlanDAOBase _dao = kIsWeb ? StudyPlanDAOWeb() : StudyPlanDAO();
  final StudyLogDAOBase _logs = kIsWeb ? StudyLogDAOWeb() : StudyLogDAO();

  Future<StudyPlan> loadOrInit(String userId) async {
    final p = await _dao.getByUserId(userId);
    if (p != null) return p;
    final plan = StudyPlan(userId: userId);
    await _dao.upsert(plan);
    return plan;
  }

  Future<StudyPlan> save(StudyPlan plan) async {
    plan.updatedAt = DateTime.now();
    await _dao.upsert(plan);
    return plan;
  }

  Future<int> todayProgress(String? userId) async {
    return await _logs.countDistinctWordsToday(userId);
  }

  Future<void> markCompletedToday(String userId, bool completed) async {
    await _dao.markCompletedToday(userId, completed: completed);
  }

  Future<int> calculateStreakDays(String userId, int targetWords, {int lookbackDays = 30}) async {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < lookbackDays; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final cnt = await _logs.countDistinctWordsOn(day, userId);
      if (cnt >= targetWords) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<List<Map<String, dynamic>>> recentHistory(String userId, int days, int targetWords) async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> out = [];
    for (int i = 0; i < days; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final cnt = await _logs.countDistinctWordsOn(day, userId);
      out.add({
        'date': '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}',
        'count': cnt,
        'completed': cnt >= targetWords,
      });
    }
    return out;
  }
}