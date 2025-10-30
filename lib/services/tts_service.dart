import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/models/word_card.dart';
import 'audio_cache_service.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  final AudioCacheService _cache = AudioCacheService();

  Future<void> init({String voice = 'en-US'}) async {
    await _tts.setLanguage(voice);
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
  }

  Future<void> playWord(WordCard w, String voiceCode) async {
    await init(voice: voiceCode);
    final exists = await _cache.exists(w.word, voiceCode);
    if (exists) {
      final f = await _cache.fileFor(w.word, voiceCode);
      await _player.stop();
      await _player.play(DeviceFileSource(f.path));
      await _cache.touchAccess(f);
    } else {
      // Fallback to live TTS; TODO: persist audio to file when supported
      await _tts.stop();
      await _tts.speak(w.word);
    }
    // Optionally run cache cleaning in background
    _cache.cleanCacheIfNeeded();
  }
}