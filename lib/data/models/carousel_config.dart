class CarouselConfig {
  bool shuffle;
  int intervalSeconds; // default 5
  bool showRelated;
  List<String> selectedTagIds;

  CarouselConfig({
    this.shuffle = false,
    this.intervalSeconds = 5,
    this.showRelated = true,
    this.selectedTagIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'shuffle': shuffle,
        'intervalSeconds': intervalSeconds,
        'showRelated': showRelated,
        'selectedTagIds': selectedTagIds,
      };

  factory CarouselConfig.fromJson(Map<String, dynamic> j) => CarouselConfig(
        shuffle: (j['shuffle'] ?? false) == true,
        intervalSeconds: j['intervalSeconds'] ?? 5,
        showRelated: (j['showRelated'] ?? true) == true,
        selectedTagIds: (j['selectedTagIds'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}