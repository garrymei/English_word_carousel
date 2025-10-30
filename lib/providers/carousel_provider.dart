import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/carousel_config.dart';
import '../data/models/word_card.dart';
import '../data/repositories/word_repository.dart';
import '../services/audio_cache_service.dart';

class CarouselProvider extends ChangeNotifier {
  final _repo = WordRepository();
  final AudioCacheService _audio = AudioCacheService();
  List<WordCard> playingDeck = [];
  int currentIndex = 0;
  Timer? _timer;
  CarouselConfig cfg = CarouselConfig();
  bool isPlaying = false;
  DateTime? _sessionEnd; // 根据 durationMode 计算

  Future<void> buildDeck({List<String>? tagIds, bool? onlyEnabled, bool? shuffle}) async {
    playingDeck = await _repo.list(tagIds: tagIds, onlyEnabled: onlyEnabled ?? true);
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

  void applyConfig(CarouselConfig c) {
    cfg = c;
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
    super.dispose();
  }
}