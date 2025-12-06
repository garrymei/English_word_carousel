import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_plan.dart';
import 'study_plan_dao_base.dart';

class StudyPlanDAOWeb implements StudyPlanDAOBase {
  String _keyFor(String userId) => 'ewc_study_plan_$userId';

  @override
  Future<StudyPlan?> getByUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(userId));
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return StudyPlan(
      userId: userId,
      targetWords: m['target_words'] ?? 10,
      reviewCycleDays: m['review_cycle'] ?? 7,
      reminderTime: m['reminder_time'] ?? '20:00',
      streakDays: m['streak_days'] ?? 0,
      completedToday: (m['completed_today'] ?? false) == true,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  @override
  Future<void> upsert(StudyPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final m = {
      'user_id': plan.userId,
      'target_words': plan.targetWords,
      'review_cycle': plan.reviewCycleDays,
      'reminder_time': plan.reminderTime,
      'streak_days': plan.streakDays,
      'completed_today': plan.completedToday,
      'updated_at': plan.updatedAt.millisecondsSinceEpoch,
    };
    await prefs.setString(_keyFor(plan.userId), jsonEncode(m));
  }

  @override
  Future<void> markCompletedToday(String userId, {required bool completed}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(userId);
    final raw = prefs.getString(key);
    Map<String, dynamic> m = {};
    if (raw != null) m = jsonDecode(raw);
    m['completed_today'] = completed;
    m['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString(key, jsonEncode(m));
  }
}
