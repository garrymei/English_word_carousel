import 'study_log_dao_base.dart';

class StudyLogDAOWeb implements StudyLogDAOBase {
  @override
  Future<int> countDistinctWordsToday(String? userId) async {
    // Web stub: no DB, return 0
    return 0;
  }

  @override
  Future<int> countDistinctWordsOn(DateTime day, String? userId) async {
    // Web stub: no DB, return 0
    return 0;
  }
}
