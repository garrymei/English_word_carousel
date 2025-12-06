import '../models/study_plan.dart';

abstract class StudyPlanDAOBase {
  Future<StudyPlan?> getByUserId(String userId);
  Future<void> upsert(StudyPlan plan);
  Future<void> markCompletedToday(String userId, {required bool completed});
}