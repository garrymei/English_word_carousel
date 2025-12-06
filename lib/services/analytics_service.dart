import 'package:uuid/uuid.dart';
import '../data/dao/study_log_dao.dart';
import '../data/models/study_log.dart';

class AnalyticsService {
  final _uuid = const Uuid();
  final StudyLogDAO _dao = StudyLogDAO();
  String? _currentSessionId;
  String? _currentUserId;

  String startSession({String? userId}) {
    _currentSessionId = _uuid.v4();
    _currentUserId = userId;
    return _currentSessionId!;
  }

  Future<void> logPlay(String wordId, int durationSeconds) async {
    if (_currentSessionId == null) return;
    final log = StudyLog(
      id: _uuid.v4(),
      userId: _currentUserId,
      wordId: wordId,
      sessionId: _currentSessionId!,
      durationSeconds: durationSeconds,
    );
    await _dao.insert(log);
  }

  void endSession() {
    _currentSessionId = null;
    _currentUserId = null;
  }
}