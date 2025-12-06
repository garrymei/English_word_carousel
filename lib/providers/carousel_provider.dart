import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/carousel_config.dart';
import '../data/models/word_card.dart';
import '../data/repositories/word_repository.dart';
import '../services/audio_cache_service.dart';
import '../services/settings_service.dart';
import '../services/analytics_service.dart';

class CarouselProvider extends ChangeNotifier {
  final _repo = WordRepository();
  final AudioCacheService _audio = AudioCacheService();
  final SettingsService _settings = SettingsService();
  final AnalyticsService _analytics = AnalyticsService();
  List<WordCard> playingDeck = [];
  int currentIndex = 0;
  Timer? _timer;
  CarouselConfig cfg = CarouselConfig();
  bool isPlaying = false;
  DateTime? _sessionEnd; // 根据 durationMode 计算
  String? _userId; // for analytics

  Future<void> buildDeck({List<String>? tagIds, bool? onlyEnabled, bool? shuffle, String? userId}) async {
    playingDeck = await _repo.list(tagIds: tagIds, onlyEnabled: onlyEnabled ?? true, userId: userId, personalOnly: true);
    _userId = userId; // keep for analytics session
    if ((shuffle ?? cfg.shuffle) && playingDeck.isNotEmpty) {
      playingDeck.shuffle();
    }
    currentIndex = 0;
    notifyListeners();
  }

  void start() {
    if (playingDeck.isEmpty) return;
    isPlaying = true;
    currentIndex = 0;
    _computeSessionEnd();
    _analytics.startSession(userId: _userId);
    // 预加载音频（异步），不阻塞播放
    _audio.preloadDeck(playingDeck, cfg.voice);
    _playCurrentIfNeeded();
    _scheduleNextTick();
    notifyListeners();
  }

  void _computeSessionEnd() {
    if (cfg.loopForever) {
      _sessionEnd = null;
      return;
    }
    final dur = _durationFromMode(cfg.durationMode);
    _sessionEnd = dur == null ? null : DateTime.now().add(dur);
  }

  Duration? _durationFromMode(String mode) {
    switch (mode) {
      case '5min': return const Duration(minutes: 5);
      case '10min': return const Duration(minutes: 10);
      case '20min': return const Duration(minutes: 20);
      case '1h': return const Duration(hours: 1);
      case 'forever': return null;
      default: return null;
    }
  }

  void _scheduleNextTick() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: cfg.intervalSeconds), () {
      if (!isPlaying || playingDeck.isEmpty) return;
      if (_sessionEnd != null && DateTime.now().isAfter(_sessionEnd!)) {
        stop();
        return;
      }
      currentIndex = (currentIndex + 1) % playingDeck.length;
      _playCurrentIfNeeded();
      _scheduleNextTick();
      notifyListeners();
    });
  }

  void _playCurrentIfNeeded() {
    if (!cfg.autoPlaySound || playingDeck.isEmpty) return;
    final current = playingDeck[currentIndex];
    _audio.playWord(current, cfg.voice);
    _analytics.logPlay(current.id, cfg.intervalSeconds);
  }

  void pause() {
    isPlaying = false;
    _timer?.cancel();
    notifyListeners();
  }

  void resume() {
    if (!isPlaying) {
      isPlaying = true;
      _computeSessionEnd();
      _playCurrentIfNeeded();
      _scheduleNextTick();
      notifyListeners();
    }
  }

  void stop() {
    isPlaying = false;
    _timer?.cancel();
    currentIndex = 0;
    _analytics.endSession();
    notifyListeners();
  }

  void next() {
    if (playingDeck.isEmpty) return;
    currentIndex = (currentIndex + 1) % playingDeck.length;
    _playCurrentIfNeeded();
    notifyListeners();
  }

  void prev() {
    if (playingDeck.isEmpty) return;
    currentIndex = (currentIndex - 1 + playingDeck.length) % playingDeck.length;
    _playCurrentIfNeeded();
    notifyListeners();
  }

  Future<void> loadConfigFromPrefs() async {
    final loaded = await _settings.loadConfig();
    applyConfig(loaded);
  }

  void applyConfig(CarouselConfig c) {
    cfg = c;
    _settings.saveConfig(cfg); // persist
    if (isPlaying) {
      _computeSessionEnd();
      _scheduleNextTick();
      _playCurrentIfNeeded();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _analytics.endSession();
    super.dispose();
  }

  Duration? remaining() {
    if (_sessionEnd == null) return null;
    final diff = _sessionEnd!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  void reset() {
    stop();
    playingDeck = [];
    currentIndex = 0;
    notifyListeners();
  }

  void setDeck(List<WordCard> deck, {bool startPlaying = false}) {
    playingDeck = List<WordCard>.from(deck);
    currentIndex = 0;
    notifyListeners();
    if (startPlaying) {
      start();
    }
  }
}