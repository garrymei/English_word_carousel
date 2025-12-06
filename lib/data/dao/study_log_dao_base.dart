abstract class StudyLogDAOBase {
  Future<int> countDistinctWordsToday(String? userId);
  Future<int> countDistinctWordsOn(DateTime day, String? userId);
}