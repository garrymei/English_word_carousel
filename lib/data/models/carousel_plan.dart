class CarouselPlan {
  final String id; // uuid
  String name;
  String? userId;
  List<String> wordIds;
  DateTime createdAt;
  DateTime updatedAt;

  CarouselPlan({
    required this.id,
    required this.name,
    this.userId,
    this.wordIds = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'user_id': userId,
        'word_ids': wordIds,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory CarouselPlan.fromJson(Map<String, dynamic> j) => CarouselPlan(
        id: j['id'],
        name: j['name'] ?? '',
        userId: j['user_id'] as String?,
        wordIds: (j['word_ids'] as List? ?? []).map((e) => e.toString()).toList(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['created_at'] ?? DateTime.now().millisecondsSinceEpoch),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(j['updated_at'] ?? DateTime.now().millisecondsSinceEpoch),
      );

  Map<String, Object?> toDbMap() => {
        'id': id,
        'name': name,
        'user_id': userId,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };
}