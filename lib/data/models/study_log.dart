class StudyLog {
  final String id;
  final String? userId;
  final String? wordId;
  final String sessionId;
  final int durationSeconds;
  final DateTime viewedAt;

  StudyLog({
    required this.id,
    this.userId,
    this.wordId,
    required this.sessionId,
    required this.durationSeconds,
    DateTime? viewedAt,
  }) : viewedAt = viewedAt ?? DateTime.now();

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'user_id': userId,
        'word_id': wordId,
        'session_id': sessionId,
        'duration': durationSeconds,
        'viewed_at': viewedAt.millisecondsSinceEpoch,
      };

  factory StudyLog.fromDbMap(Map<String, Object?> m) => StudyLog(
        id: (m['id'] as String?) ?? '',
        userId: m['user_id'] as String?,
        wordId: m['word_id'] as String?,
        sessionId: (m['session_id'] as String?) ?? '',
        durationSeconds: (m['duration'] as int?) ?? 0,
        viewedAt: DateTime.fromMillisecondsSinceEpoch((m['viewed_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      );
}