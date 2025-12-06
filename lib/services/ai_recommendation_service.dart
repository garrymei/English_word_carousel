import '../data/dao/study_log_dao.dart';
import '../data/repositories/word_repository.dart';
import '../data/models/word_card.dart';

class AIRecommendationService {
  final StudyLogDAO _logs = StudyLogDAO();
  final WordRepository _words = WordRepository();

  Future<List<WordCard>> recommendLocally({String? userId, int limit = 10}) async {
    // 简单启发式：最近未复习的优先 + 已错/停留久的（此处以未复习时间近似）
    final list = await _words.list(onlyEnabled: true, userId: userId);
    final scored = <WordCard, double>{};
    for (final w in list) {
      final lastViewed = await _logs.lastViewedAtForWord(w.id, userId);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLast = lastViewed == null ? 999999999.0 : ((nowMs - lastViewed) / 1000.0);
      final reviewIntervalWeight = 1.0;
      final mistakeWeight = 0.0; // 暂无错误次数数据，先为0
      final similarityWeight = 0.0; // 暂无语义相似度，先为0
      final score = reviewIntervalWeight * timeSinceLast + mistakeWeight * 0 + similarityWeight * 0;
      scored[w] = score;
    }
    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }
}