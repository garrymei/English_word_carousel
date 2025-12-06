class Tag {
  final String id; // uuid
  String name;
  String color; // #RRGGBB
  String description;
  DateTime createdAt;
  String? userId;

  Tag({
    required this.id,
    required this.name,
    this.color = '#3B82F6',
    this.description = '',
    DateTime? createdAt,
    this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'description': description,
        'created_at': createdAt.millisecondsSinceEpoch,
        'user_id': userId,
      };

  factory Tag.fromJson(Map<String, dynamic> j) => Tag(
        id: j['id'],
        name: j['name'] ?? '',
        color: j['color'] ?? '#3B82F6',
        description: j['description'] ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['created_at'] ?? DateTime.now().millisecondsSinceEpoch),
        userId: j['user_id'] as String?,
      );

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'name': name,
        'color': color,
        'description': description,
        'created_at': createdAt.millisecondsSinceEpoch,
        'user_id': userId,
      };

  factory Tag.fromDbMap(Map<String, Object?> m) => Tag(
        id: (m['id'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        color: (m['color'] as String?) ?? '#3B82F6',
        description: (m['description'] as String?) ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch((m['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
        userId: m['user_id'] as String?,
      );
}