class CarouselConfig {
  bool shuffle;
  int intervalSeconds; // default 5
  bool showRelated;
  List<String> selectedTagIds;
  String voice;           // "en-US" or "en-GB"
  bool autoPlaySound;     // 是否自动发音
  String durationMode;    // "5min"|"10min"|"20min"|"1h"|"forever"
  bool loopForever;       // 永久循环标志

  CarouselConfig({
    this.shuffle = false,
    this.intervalSeconds = 5,
    this.showRelated = true,
    this.selectedTagIds = const [],
    this.voice = 'en-US',
    this.autoPlaySound = false,
    this.durationMode = 'forever',
    this.loopForever = false,
  });

  Map<String, dynamic> toJson() => {
        'shuffle': shuffle,
        'intervalSeconds': intervalSeconds,
        'showRelated': showRelated,
        'selectedTagIds': selectedTagIds,
        'voice': voice,
        'autoPlaySound': autoPlaySound,
        'durationMode': durationMode,
        'loopForever': loopForever,
      };

  factory CarouselConfig.fromJson(Map<String, dynamic> j) => CarouselConfig(
        shuffle: (j['shuffle'] ?? false) == true,
        intervalSeconds: j['intervalSeconds'] ?? 5,
        showRelated: (j['showRelated'] ?? true) == true,
        selectedTagIds: (j['selectedTagIds'] as List? ?? []).map((e) => e.toString()).toList(),
        voice: (j['voice'] as String?) ?? 'en-US',
        autoPlaySound: (j['autoPlaySound'] ?? false) == true,
        durationMode: (j['durationMode'] as String?) ?? 'forever',
        loopForever: (j['loopForever'] ?? false) == true,
      );
}