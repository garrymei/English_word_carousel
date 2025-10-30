import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/carousel_config.dart';
import '../data/models/word_card.dart';
import '../data/repositories/word_repository.dart';

class CarouselProvider extends ChangeNotifier {
  final _repo = WordRepository();
  List<WordCard> playingDeck = [];
  int currentIndex = 0;
  Timer? _timer;
  CarouselConfig cfg = CarouselConfig();
  bool isPlaying = false;

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
    _scheduleNextTick();
    notifyListeners();
  }

  void _scheduleNextTick() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: cfg.intervalSeconds), () {
      if (!isPlaying || playingDeck.isEmpty) return;
      currentIndex = (currentIndex + 1) % playingDeck.length;
      _scheduleNextTick();
      notifyListeners();
    });
  }

  void pause() {
    isPlaying = false;
    _timer?.cancel();
    notifyListeners();
  }

  void resume() {
    if (!isPlaying) {
      isPlaying = true;
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
    notifyListeners();
  }

  void prev() {
    if (playingDeck.isEmpty) return;
    currentIndex = (currentIndex - 1 + playingDeck.length) % playingDeck.length;
    notifyListeners();
  }

  void applyConfig(CarouselConfig c) {
    cfg = c;
    notifyListeners();
  }
}