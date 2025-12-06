import 'package:flutter/foundation.dart';
import '../services/study_plan_service.dart';
import '../data/models/study_plan.dart';

class StudyPlanProvider extends ChangeNotifier {
  final StudyPlanService _svc = StudyPlanService();
  StudyPlan? plan;
  int todayCount = 0;
  List<Map<String, dynamic>> history = [];

  Future<void> load(String userId) async {
    plan = await _svc.loadOrInit(userId);
    todayCount = await _svc.todayProgress(userId);
    plan!.streakDays = await _svc.calculateStreakDays(userId, plan!.targetWords);
    history = await _svc.recentHistory(userId, 7, plan!.targetWords);
    notifyListeners();
  }

  Future<void> save(StudyPlan p) async {
    plan = await _svc.save(p);
    notifyListeners();
  }

  Future<void> refreshToday(String? userId) async {
    todayCount = await _svc.todayProgress(userId);
    if (plan != null && userId != null) {
      plan!.streakDays = await _svc.calculateStreakDays(userId, plan!.targetWords);
      history = await _svc.recentHistory(userId, 7, plan!.targetWords);
    }
    notifyListeners();
  }

  Future<void> markCompleted(bool completed) async {
    if (plan == null) return;
    await _svc.markCompletedToday(plan!.userId, completed);
    plan!.completedToday = completed;
    notifyListeners();
  }
}