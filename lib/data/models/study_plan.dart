class StudyPlan {
  final String userId;
  int targetWords;
  int reviewCycleDays;
  String reminderTime; // HH:mm
  int streakDays;
  bool completedToday;
  DateTime updatedAt;

  StudyPlan({
    required this.userId,
    this.targetWords = 10,
    this.reviewCycleDays = 7,
    this.reminderTime = '20:00',
    this.streakDays = 0,
    this.completedToday = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toDbMap() => {
    'user_id': userId,
    'target_words': targetWords,
    'review_cycle': reviewCycleDays,
    'reminder_time': reminderTime,
    'streak_days': streakDays,
    'completed_today': completedToday ? 1 : 0,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory StudyPlan.fromDbMap(Map<String, Object?> m) => StudyPlan(
    userId: (m['user_id'] as String?) ?? '',
    targetWords: (m['target_words'] as int?) ?? 10,
    reviewCycleDays: (m['review_cycle'] as int?) ?? 7,
    reminderTime: (m['reminder_time'] as String?) ?? '20:00',
    streakDays: (m['streak_days'] as int?) ?? 0,
    completedToday: ((m['completed_today'] as int?) ?? 0) == 1,
    updatedAt: DateTime.fromMillisecondsSinceEpoch((m['updated_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
  );
}